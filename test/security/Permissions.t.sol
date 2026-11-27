// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VeyraFixture} from "../support/VeyraFixture.sol";
import {Accounts} from "../../src/modules/Accounts.sol";
import {Access} from "../../src/security/Access.sol";
import {ExactTransfer} from "../../src/security/ExactTransfer.sol";
import {IMarketConfig} from "../../src/interface/IMarketConfig.sol";
import {IERC20} from "../../src/interface/IERC20.sol";
import {MockUSD} from "../../src/tokens/MockUSD.sol";
import {Loans} from "../../src/modules/Loans.sol";
import {Pool} from "../../src/modules/Pool.sol";

contract PermissionsTest is VeyraFixture {
    // EC-01 / INV-03 / CL-03, CL-26. Permission to spend ERC-20 belongs to custody.
    function testAllowanceToCustodyDoesNotLetAnotherAccountDepositForOwner() public {
        usd.mint(borrower, 50e6);
        vm.prank(borrower);
        usd.approve(address(v), 50e6);
        vm.prank(liquidator);
        vm.expectRevert();
        v.deposit(address(usd), 50e6);
        assertEq(usd.allowance(borrower, address(v)), 50e6);
        assertEq(usd.balanceOf(borrower), 50e6);
        assertEq(usd.balanceOf(address(v)), 0);
        assertEq(v.totalAvailable(address(usd)), 0);
    }

    // EC-08 / INV-09, INV-10 / CL-36, CL-37, CL-38.
    function testOnlyTreasuryCanWithdrawRetainedFundsToItsOwnAddress() public {
        fund(borrower, usd, 110e6);
        vm.prank(borrower);
        v.subscribe();
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Access.Unauthorized.selector, admin));
        v.withdrawRevenue(address(usd), 10e6);
        vm.startPrank(treasury);
        vm.expectRevert(abi.encodeWithSelector(Accounts.InsufficientRevenue.selector, address(usd)));
        v.withdrawRevenue(address(usd), 10e6 + 1);
        v.withdrawRevenue(address(usd), 10e6);
        vm.stopPrank();
        assertEq(usd.balanceOf(treasury), 10e6);
        assertEq(v.retained(address(usd)), 0);
        assertEq(usd.balanceOf(address(v)), 100e6);
        assertEq(v.available(borrower, address(usd)), 100e6);
    }

    // EC-01 / INV-01, INV-07 / CL-25, CL-28, CL-32.
    function testSurplusNeitherCreatesRevenueNorPreventsDisablingVacantAsset() public {
        usd.mint(borrower, 1e6);
        vm.prank(borrower);
        usd.transfer(address(v), 1e6);
        vm.prank(treasury);
        vm.expectRevert(abi.encodeWithSelector(Accounts.InsufficientRevenue.selector, address(usd)));
        v.withdrawRevenue(address(usd), 1);
        vm.prank(admin);
        v.setEnabled(address(usd), false);
        vm.prank(borrower);
        vm.expectRevert(abi.encodeWithSelector(IMarketConfig.AssetDisabled.selector, address(usd)));
        v.deposit(address(usd), 1);
        vm.prank(admin);
        v.setEnabled(address(usd), true);
        fund(lp, usd, 2e6);
        assertEq(usd.balanceOf(address(v)), 3e6);
        assertEq(v.totalAvailable(address(usd)), 2e6);
        assertEq(v.retained(address(usd)), 0);
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IMarketConfig.OutstandingObligations.selector, address(usd)));
        v.setEnabled(address(usd), false);
        assertTrue(v.enabled(address(usd)));
    }

    function testOnlyAdminCanPublishAndChangeRegisteredAssets() public {
        uint256 original = v.price();
        vm.startPrank(treasury);
        vm.expectRevert(abi.encodeWithSelector(Access.Unauthorized.selector, treasury));
        v.publishPrice(500e6);
        vm.expectRevert(abi.encodeWithSelector(Access.Unauthorized.selector, treasury));
        v.setEnabled(address(eth), false);
        vm.stopPrank();
        assertTrue(v.enabled(address(eth)));
        assertEq(v.price(), original);
        MockUSD lookalike = new MockUSD(admin);
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IMarketConfig.UnsupportedAsset.selector, address(lookalike)));
        v.setEnabled(address(lookalike), true);
    }

    function testOnlyConfiguredMinterIssuesMockTokens() public {
        vm.prank(borrower);
        vm.expectRevert(abi.encodeWithSelector(Access.Unauthorized.selector, borrower));
        usd.mint(borrower, 1);
        assertEq(usd.balanceOf(borrower), 0);
        assertEq(usd.totalSupply(), 0);
    }

    // EC-01 / INV-03 / CL-03, CL-04 and EC-08 / INV-10 / CL-50.
    function testFalseTransferFromDoesNotCreditDeposit() public {
        usd.mint(borrower, 10e6);
        vm.prank(borrower);
        usd.approve(address(v), 10e6);
        vm.mockCall(address(usd), abi.encodeCall(IERC20.transferFrom, (borrower, address(v), 10e6)), abi.encode(false));
        vm.prank(borrower);
        vm.expectRevert(abi.encodeWithSelector(ExactTransfer.TransferFailed.selector, address(usd)));
        v.deposit(address(usd), 10e6);
        assertEq(v.totalAvailable(address(usd)), 0);
        assertEq(usd.balanceOf(address(v)), 0);
        assertEq(usd.balanceOf(borrower), 10e6);
    }

    // EC-01 / INV-04 / CL-16, CL-22. A successful return value alone cannot authorize a payout.
    function testInexactTransferRollsBackGrossDebitAndCollectedFee() public {
        fund(borrower, usd, 100e6);
        uint256 net = 99_900_000;
        vm.mockCall(address(usd), abi.encodeCall(IERC20.transfer, (borrower, net)), abi.encode(true));
        vm.prank(borrower);
        vm.expectRevert(abi.encodeWithSelector(ExactTransfer.InexactTransfer.selector, address(usd)));
        v.withdraw(address(usd), 100e6);
        assertEq(v.available(borrower, address(usd)), 100e6);
        assertEq(v.totalAvailable(address(usd)), 100e6);
        assertEq(usd.balanceOf(address(v)), 100e6);
        assertEq(v.retained(address(usd)), 0);
    }

    // EC-04 / INV-06 and EC-06 / INV-11 / CL-28. Prepare positions with funds on both sides.
    function testProviderAndBorrowerPermissionsRemainBoundToTheirOwners() public {
        fund(lp, usd, 1_000e6);
        vm.prank(lp);
        v.supply(1_000e6);
        vm.prank(admin);
        vm.expectRevert(Pool.InsufficientShares.selector);
        v.redeem(1);
        assertEq(v.sharesOf(lp), 1_000e6);
        assertEq(v.totalShares(), 1_000e6);
        assertEq(v.cash(), 1_000e6);

        fund(borrower, eth, 1e18);
        fund(liquidator, usd, 1_000e6);
        publish(2_000e6);
        vm.prank(borrower);
        uint256 id = v.openLoan(1_000e6, 1e18);
        vm.prank(liquidator);
        vm.expectRevert(Loans.NotBorrower.selector);
        v.repayAll(id);
        assertEq(v.available(liquidator, address(usd)), 1_000e6);
        assertEq(v.loan(id).debt, 1_000e6);
        assertEq(v.totalCollateral(), 1e18);

        publish(630e6);
        vm.prank(borrower);
        vm.expectRevert(Loans.SelfLiquidation.selector);
        v.liquidate(id);
        assertEq(v.activeLoan(borrower), id);
        assertEq(v.cash(), 0);
        vm.prank(liquidator);
        v.liquidate(id);
        assertEq(v.activeLoan(borrower), 0);
        assertEq(v.cash(), 600e6);
        assertEq(v.available(liquidator, address(usd)), 400e6);
    }

    // EC-08 / INV-07, INV-10 / CL-50. Both custody and destination must observe the same amount.
    function testTreasuryReceiptOneUnitShortRevertsAllAccounting() public {
        fund(borrower, usd, 10e6);
        vm.prank(borrower);
        v.subscribe();
        bytes[] memory answers = new bytes[](2);
        answers[0] = abi.encode(uint256(0));
        answers[1] = abi.encode(uint256(10e6 - 1));
        vm.mockCalls(address(usd), abi.encodeCall(IERC20.balanceOf, (treasury)), answers);
        vm.prank(treasury);
        vm.expectRevert(abi.encodeWithSelector(ExactTransfer.InexactTransfer.selector, address(usd)));
        v.withdrawRevenue(address(usd), 10e6);
        vm.clearMockedCalls();
        assertEq(v.retained(address(usd)), 10e6);
        assertEq(usd.balanceOf(treasury), 0);
        assertEq(usd.balanceOf(address(v)), 10e6);
    }

    // EC-01 / INV-01, INV-06 / CL-23, CL-24, CL-30. Prepared one-unit deficit.
    function testPayoutMustLeaveOtherUsersBacked() public {
        fund(borrower, usd, 1e6);
        fund(lp, usd, 2e6);
        deal(address(usd), address(v), 3e6 - 1);
        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(ExactTransfer.InsufficientBacking.selector, address(usd), 2_000_999, 2_001_000)
        );
        v.withdraw(address(usd), 1e6);
        assertEq(usd.balanceOf(address(v)), 3e6 - 1);
        assertEq(usd.balanceOf(borrower), 0);
        assertEq(v.available(borrower, address(usd)), 1e6);
        assertEq(v.available(lp, address(usd)), 2e6);
        assertEq(v.retained(address(usd)), 0);
    }
}
