// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VeyraFixture} from "../support/VeyraFixture.sol";
import {ILiquidations} from "../../src/interface/ILiquidations.sol";
import {ILoans} from "../../src/interface/ILoans.sol";

contract MarketLifecycleTest is VeyraFixture {
    address private secondLp = makeAddr("secondLp");
    address private secondBorrower = makeAddr("secondBorrower");
    address private sender = makeAddr("sender");
    address private recipient = makeAddr("recipient");
    address private subscriber = makeAddr("subscriber");

    function _provide(address provider, uint256 amount) private {
        fund(provider, usd, amount);
        vm.prank(provider);
        assertEq(v.supply(amount), amount);
    }

    function test_AcceptanceWithLossAndFinalExternalWithdrawals() public {
        _provide(lp, 5000e6);
        _provide(secondLp, 5000e6);
        fund(sender, usd, 100e6);
        fund(subscriber, usd, 10e6);
        fund(borrower, usd, 70e6);
        fund(borrower, eth, 1 ether);
        fund(secondBorrower, eth, 1 ether);
        fund(liquidator, usd, 600e6);
        vm.prank(sender);
        assertEq(v.pay(recipient, 100e6), 99.8e6);
        vm.prank(subscriber);
        v.subscribe();
        publish(2000e6);
        uint256 t0 = vm.getBlockTimestamp();
        vm.prank(borrower);
        uint256 first = v.openLoan(1000e6, 1 ether);
        vm.prank(secondBorrower);
        uint256 second = v.openLoan(1000e6, 1 ether);
        assertEq(v.cash(), 8000e6);
        assertEq(v.equity(), 10000e6);
        assertEq(v.totalCollateral(), 2 ether);

        vm.warp(t0 + 365 days / 2);
        assertEq(v.loan(first).interest, 40e6);
        vm.prank(borrower);
        v.repay(first, 540e6);
        assertEq(v.loan(first).principal, 500e6);
        vm.warp(t0 + 365 days);
        vm.prank(borrower);
        assertEq(v.repayAll(first), 520e6);
        assertEq(v.loan(first).status, 2);
        publish(630e6);
        assertEq(v.equity(), 10140e6);
        vm.expectEmit(true, true, true, true, address(v));
        emit ILiquidations.Liquidated(
            second, liquidator, secondBorrower, 1080e6, 600e6, 80e6, 520e6, 480e6, 1 ether, 0, 630e6
        );
        vm.prank(liquidator);
        v.liquidate(second);
        assertEq(v.loan(second).status, 3);
        assertEq(v.activeLoanCount(), 0);
        assertEq(v.totalCollateral(), 0);
        assertEq(v.cash(), 9660e6);
        assertEq(v.equity(), 9660e6);
        assertEq(v.totalShares(), 10000e6);
        vm.prank(lp);
        assertEq(v.redeem(5000e6), 4830e6);
        vm.prank(secondLp);
        assertEq(v.redeem(5000e6), 4830e6);
        assertEq(usd.balanceOf(address(v)), 10780e6);
        assertEq(eth.balanceOf(address(v)), 2 ether);
        assertEq(v.retained(address(usd)), 30.2e6);
        vm.prank(treasury);
        v.withdrawRevenue(address(usd), 30.2e6);

        vm.prank(lp);
        v.withdraw(address(usd), 4830e6);
        vm.prank(secondLp);
        v.withdraw(address(usd), 4830e6);
        vm.prank(secondBorrower);
        v.withdraw(address(usd), 990e6);
        vm.prank(recipient);
        v.withdraw(address(usd), 99.8e6);
        vm.prank(borrower);
        v.withdraw(address(eth), 1 ether);
        vm.prank(liquidator);
        v.withdraw(address(eth), 1 ether);
        assertEq(usd.balanceOf(lp), 4825.17e6);
        assertEq(usd.balanceOf(secondLp), 4825.17e6);
        assertEq(usd.balanceOf(secondBorrower), 989.01e6);
        assertEq(usd.balanceOf(recipient), 99.7002e6);
        assertEq(eth.balanceOf(borrower), 0.999 ether);
        assertEq(eth.balanceOf(liquidator), 0.999 ether);
        vm.startPrank(treasury);
        v.withdrawRevenue(address(usd), 10.7498e6);
        v.withdrawRevenue(address(eth), 0.002 ether);
        vm.stopPrank();
        assertEq(usd.balanceOf(address(v)), 0);
        assertEq(eth.balanceOf(address(v)), 0);
        assertEq(v.totalAvailable(address(usd)), 0);
        assertEq(v.totalAvailable(address(eth)), 0);
        assertEq(v.retained(address(usd)), 0);
        assertEq(v.retained(address(eth)), 0);
        assertEq(v.totalShares(), 0);
    }

    function test_LiquidationReturnsSurplusToBorrower() public {
        _provide(lp, 1600e6);
        fund(liquidator, usd, 1600e6);
        fund(borrower, eth, 1 ether);
        publish(3000e6);
        vm.prank(borrower);
        uint256 id = v.openLoan(1600e6, 1 ether);
        publish(2000e6);
        vm.expectEmit(true, true, true, true, address(v));
        emit ILiquidations.Liquidated(
            id, liquidator, borrower, 1600e6, 1600e6, 0, 1600e6, 0, 0.84 ether, 0.16 ether, 2000e6
        );
        vm.prank(liquidator);
        v.liquidate(id);
        assertEq(v.available(borrower, address(eth)), 0.16 ether);
        assertEq(v.available(liquidator, address(eth)), 0.84 ether);
        assertEq(v.cash(), 1600e6);
        assertEq(v.equity(), 1600e6);
        assertEq(v.retained(address(usd)), 16e6);
    }

    function test_PaidTermsSurviveExpiryAndManualRenewals() public {
        _provide(lp, 1000e6);
        fund(borrower, eth, 1 ether);
        fund(borrower, usd, 230e6);
        uint256 start = vm.getBlockTimestamp();
        vm.startPrank(borrower);
        assertEq(v.subscribe(), start + 30 days);
        assertEq(v.pay(recipient, 100e6), 99.95e6);
        vm.stopPrank();
        publish(2000e6);
        vm.prank(borrower);
        uint256 id = v.openLoan(1000e6, 1 ether);
        assertEq(v.available(borrower, address(usd)), 1115e6);
        vm.warp(start + 29 days);
        vm.prank(borrower);
        assertEq(v.renew(), start + 60 days);
        vm.warp(start + 60 days);
        (bool paid,) = v.plan(borrower);
        assertFalse(paid);
        vm.prank(borrower);
        assertEq(v.pay(recipient, 100e6), 99.8e6);
        vm.warp(start + 61 days);
        vm.prank(borrower);
        assertEq(v.renew(), start + 91 days);
        vm.warp(start + 365 days);
        ILoans.LoanView memory position = v.loan(id);
        assertEq(position.debt, 1050e6);
        assertEq(position.annualRateBps, 500);
        assertEq(position.openingFeeBps, 50);
    }
}
