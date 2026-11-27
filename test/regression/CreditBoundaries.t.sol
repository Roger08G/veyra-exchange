// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VeyraFixture} from "../support/VeyraFixture.sol";
import {Loans} from "../../src/modules/Loans.sol";
import {Pool} from "../../src/modules/Pool.sol";
import {Accounts} from "../../src/modules/Accounts.sol";
import {IMarketConfig} from "../../src/interface/IMarketConfig.sol";

contract CreditBoundariesTest is VeyraFixture {
    function _market(uint256 liquidity) private {
        fund(lp, usd, liquidity);
        vm.prank(lp);
        v.supply(liquidity);
        fund(borrower, eth, 1 ether);
        publish(2000e6);
    }

    function test_FractionalInterestIsRoundedPerLoan() public {
        _market(20);
        fund(liquidator, eth, 1 ether);
        uint256 start = vm.getBlockTimestamp();
        vm.prank(borrower);
        v.openLoan(10, 1 ether);
        vm.prank(liquidator);
        v.openLoan(10, 1 ether);
        vm.warp(start + 365 days);
        assertEq(v.equity(), 20);
        vm.warp(start + 730 days);
        assertEq(v.equity(), 22);
    }

    function test_OpeningIsAtomicAndOnlyOneLoanCanRemainActivePerBorrower() public {
        _market(2000e6);
        vm.startPrank(borrower);
        vm.expectRevert(abi.encodeWithSelector(Accounts.InsufficientAvailable.selector, borrower, address(eth)));
        v.openLoan(1000e6, 2 ether);
        assertEq(v.cash(), 2000e6);
        assertEq(v.activeLoanCount(), 0);
        assertEq(v.totalCollateral(), 0);
        assertEq(v.retained(address(usd)), 0);
        assertEq(v.available(borrower, address(eth)), 1 ether);

        uint256 id = v.openLoan(500e6, 0.5 ether);
        vm.expectRevert(Loans.ActiveLoanExists.selector);
        v.openLoan(500e6, 0.5 ether);
        vm.expectRevert(Loans.InvalidRepayment.selector);
        v.repay(id, 500e6 + 1);
        vm.stopPrank();
        assertEq(v.activeLoan(borrower), id);
        assertEq(v.loan(id).debt, 500e6);
        assertEq(v.totalCollateral(), 0.5 ether);
        assertEq(v.cash(), 1500e6);
        assertEq(v.retained(address(usd)), 5e6);
    }

    /// EC-07 / INV-02 / CL-03 and CL-04.
    function test_ExactLtvAndOneUnitAcrossBothThresholds() public {
        _market(2000e6);
        fund(liquidator, usd, 1200e6);
        vm.startPrank(borrower);
        vm.expectRevert(Loans.OpeningLtvExceeded.selector);
        v.openLoan(1200e6 + 1, 1 ether);
        uint256 id = v.openLoan(1200e6, 1 ether);
        vm.stopPrank();
        publish(1600e6);
        vm.expectRevert(Loans.NotLiquidatable.selector);
        vm.prank(liquidator);
        v.liquidate(id);
        publish(1600e6 - 1);
        vm.prank(liquidator);
        v.liquidate(id);
        assertEq(v.activeLoanCount(), 0);
    }

    function test_StaleOracleDoesNotBlockRepaymentOrAllowLiquidation() public {
        _market(2000e6);
        fund(borrower, usd, 100e6);
        fund(liquidator, usd, 1000e6);
        uint256 start = vm.getBlockTimestamp();
        vm.warp(start + 3601);
        vm.expectRevert(IMarketConfig.StalePrice.selector);
        vm.prank(borrower);
        v.openLoan(1000e6, 1 ether);
        publish(2000e6);
        vm.warp(start + 7201);
        vm.prank(borrower);
        uint256 id = v.openLoan(1000e6, 1 ether);
        publish(630e6);
        vm.warp(start + 10802);
        vm.expectRevert(IMarketConfig.StalePrice.selector);
        vm.prank(liquidator);
        v.liquidate(id);
        vm.prank(borrower);
        v.repayAll(id);
        assertEq(v.available(borrower, address(eth)), 1 ether);
    }

    function test_ClosedIdCannotSettleAnotherLoanAndInsufficientCashIsAtomic() public {
        _market(1000e6);
        fund(borrower, usd, 10e6);
        vm.prank(borrower);
        uint256 first = v.openLoan(1000e6, 1 ether);
        vm.expectRevert(Pool.InsufficientCash.selector);
        vm.prank(lp);
        v.redeem(1);
        assertEq(v.sharesOf(lp), 1000e6);
        vm.startPrank(borrower);
        v.repayAll(first);
        uint256 second = v.openLoan(100e6, 1 ether);
        vm.expectRevert(Loans.InactiveLoan.selector);
        v.repayAll(first);
        vm.stopPrank();
        publish(100e6);
        vm.expectRevert(Loans.InactiveLoan.selector);
        vm.prank(liquidator);
        v.liquidate(first);
        assertGt(second, first);
        assertEq(v.loan(second).principal, 100e6);
        assertEq(v.activeLoan(borrower), second);
    }
}
