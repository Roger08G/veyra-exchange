// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VeyraFixture} from "../support/VeyraFixture.sol";
import {ReentrancyGuard} from "../../src/security/ReentrancyGuard.sol";

contract SharedGuardTest is VeyraFixture {
    /// @dev Prepare an already-held custody lock and exercise each mutable public entry point.
    function test_AllMutationsUseTheSameCustodyLock() public {
        uint256[] memory slots = vm.getStorageSlots(address(v), "_lock");
        assertEq(slots.length, 1);
        bytes32 lockSlot = bytes32(slots[0]);
        assertEq(vm.load(address(v), lockSlot), bytes32(uint256(1)));
        vm.store(address(v), lockSlot, bytes32(uint256(2)));

        vm.startPrank(admin);
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.publishPrice(2000e6);
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.setEnabled(address(usd), false);
        vm.stopPrank();
        vm.prank(treasury);
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.withdrawRevenue(address(usd), 1);

        vm.startPrank(borrower);
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.deposit(address(usd), 1);
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.withdraw(address(usd), 1);
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.pay(lp, 1);
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.subscribe();
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.renew();
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.supply(1);
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.redeem(1);
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.openLoan(1, 1 ether);
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.repay(1, 1);
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.repayAll(1);
        vm.expectRevert(ReentrancyGuard.ReentrantCall.selector);
        v.liquidate(1);
        vm.stopPrank();
    }
}
