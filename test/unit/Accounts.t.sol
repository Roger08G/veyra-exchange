// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VeyraFixture} from "../support/VeyraFixture.sol";
import {Accounts} from "../../src/modules/Accounts.sol";
import {IPlans} from "../../src/interface/IPlans.sol";
import {IPayments} from "../../src/interface/IPayments.sol";

contract AccountsTest is VeyraFixture {
    // EC-02 / INV-01, INV-02 / CL-04, CL-12. First payment to a fresh wallet.
    function testPaymentMovesOnlyTheGrossAndAttributesItsFeeOnce() public {
        uint256 gross = 100e6;
        fund(borrower, usd, gross);
        vm.expectEmit(true, true, true, true, address(v));
        emit IPayments.Payment(borrower, lp, address(usd), gross, 99_800_000, 200_000, false);
        vm.prank(borrower);
        assertEq(v.pay(lp, gross), 99_800_000);
        assertEq(v.available(borrower, address(usd)), 0);
        assertEq(v.totalAvailable(address(usd)), 99_800_000);
        assertEq(v.available(lp, address(usd)), 99_800_000);
        assertEq(v.retained(address(usd)), 200_000);
        assertEq(usd.balanceOf(address(v)), gross);
    }

    // EC-02 / INV-01, INV-06 / CL-03, CL-05, CL-09, CL-10.
    function testPaymentRejectsInvalidRecipientAndZeroThenAcceptsOneUnit() public {
        fund(borrower, usd, 1);
        vm.startPrank(borrower);
        vm.expectRevert(Accounts.InvalidPayee.selector);
        v.pay(address(0), 1);
        vm.expectRevert(Accounts.InvalidPayee.selector);
        v.pay(borrower, 1);
        vm.expectRevert(Accounts.ZeroAmount.selector);
        v.pay(lp, 0);
        assertEq(v.pay(lp, 1), 1);
        vm.stopPrank();
        assertEq(v.available(lp, address(usd)), 1);
        assertEq(v.totalAvailable(address(usd)), 1);
        assertEq(v.retained(address(usd)), 0);
    }

    // EC-01 / INV-04 / CL-10, CL-14, CL-18. Multiply-before-divide can overflow at this size.
    function testFuzzWithdrawEntireBalance(uint256 gross) public {
        gross = bound(gross, 1, type(uint256).max);
        fund(borrower, eth, gross);
        vm.prank(borrower);
        uint256 net = v.withdraw(address(eth), gross);
        uint256 expectedFee = gross / 1_000;
        assertEq(net, gross - expectedFee);
        assertEq(eth.balanceOf(borrower), net);
        assertEq(v.retained(address(eth)), expectedFee);
        assertEq(eth.balanceOf(address(v)), expectedFee);
        assertEq(v.totalAvailable(address(eth)), 0);
    }

    // EC-03 / INV-02, INV-03, INV-06 / CL-33, CL-34, CL-37.
    function testEachManualRenewalPaysForItsOwnContiguousOrNewPeriod() public {
        uint256 t = 1_700_000_000;
        vm.warp(t);
        fund(borrower, usd, 40e6);
        vm.startPrank(borrower);
        vm.expectRevert(Accounts.NoSubscriptionHistory.selector);
        v.renew();
        vm.expectEmit(true, true, false, true, address(v));
        emit IPlans.PlanPurchased(borrower, address(usd), 10e6, t, t + 30 days, false);
        assertEq(v.subscribe(), t + 30 days);
        vm.expectRevert(Accounts.PlanAlreadyActive.selector);
        v.subscribe();

        vm.warp(t + 29 days);
        vm.expectEmit(true, true, false, true, address(v));
        emit IPlans.PlanPurchased(borrower, address(usd), 10e6, t + 30 days, t + 60 days, true);
        assertEq(v.renew(), t + 60 days);
        vm.warp(t + 60 days);
        (bool atExpiry, uint256 expiry) = v.plan(borrower);
        assertFalse(atExpiry);
        assertEq(expiry, t + 60 days);
        vm.warp(t + 61 days);
        assertEq(v.renew(), t + 91 days);
        vm.warp(t + 91 days);
        assertEq(v.subscribe(), t + 121 days);
        vm.stopPrank();

        assertEq(v.available(borrower, address(usd)), 0);
        assertEq(v.retained(address(usd)), 40e6);
        assertEq(usd.balanceOf(address(v)), 40e6);
    }

    // EC-03 / INV-04, INV-05 / CL-26 and EC-02 / INV-05. Read plan at execution.
    function testPaymentUsesPaidRateJustBeforeExpiryAndBasicRateAtExpiry() public {
        uint256 t = 1_700_000_000;
        vm.warp(t);
        fund(borrower, usd, 210e6);
        vm.startPrank(borrower);
        v.subscribe();
        vm.warp(t + 30 days - 1);
        assertEq(v.pay(lp, 100e6), 99_950_000);
        vm.warp(t + 30 days);
        assertEq(v.pay(lp, 100e6), 99_800_000);
        vm.stopPrank();
        assertEq(v.available(lp, address(usd)), 199_750_000);
        assertEq(v.retained(address(usd)), 10_250_000);
    }

    // EC-03 / INV-06, INV-09 / CL-35. An unpaid renewal must preserve the original expiry.
    function testUnfundedRenewalPreservesOriginalPeriodAndRevenue() public {
        fund(borrower, usd, 10e6);
        vm.startPrank(borrower);
        uint256 originalExpiry = v.subscribe();
        vm.expectRevert(abi.encodeWithSelector(Accounts.InsufficientAvailable.selector, borrower, address(usd)));
        v.renew();
        vm.stopPrank();
        (bool paid, uint256 expiry) = v.plan(borrower);
        assertTrue(paid);
        assertEq(expiry, originalExpiry);
        assertEq(v.retained(address(usd)), 10e6);
    }
}
