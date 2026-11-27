// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VeyraFixture} from "../support/VeyraFixture.sol";
import {Veyra} from "../../src/core/Veyra.sol";
import {IMarketConfig} from "../../src/interface/IMarketConfig.sol";

contract DeploymentTest is VeyraFixture {
    function test_RejectsAmbiguousRolesAndIncorrectAssets() public {
        vm.expectRevert(IMarketConfig.InvalidConfiguration.selector);
        new Veyra(address(usd), address(eth), admin, admin);
        vm.expectRevert(IMarketConfig.InvalidConfiguration.selector);
        new Veyra(address(usd), address(eth), address(0), treasury);
        vm.expectRevert(IMarketConfig.InvalidConfiguration.selector);
        new Veyra(address(eth), address(usd), admin, treasury);
        vm.expectRevert(IMarketConfig.InvalidConfiguration.selector);
        new Veyra(address(usd), address(usd), admin, treasury);
    }

    function test_ZeroPricePublicationPreservesThePreviousQuoteAndTime() public {
        publish(2000e6);
        uint256 originalTime = v.priceUpdatedAt();
        vm.warp(originalTime + 4);
        vm.prank(admin);
        vm.expectRevert(IMarketConfig.InvalidPrice.selector);
        v.publishPrice(0);
        assertEq(v.price(), 2000e6);
        assertEq(v.priceUpdatedAt(), originalTime);
    }

    function test_InitialStateAndRoundTripInBothAssets() public {
        assertEq(v.usd(), address(usd));
        assertEq(v.eth(), address(eth));
        assertEq(usd.decimals(), 6);
        assertEq(eth.decimals(), 18);
        assertEq(v.admin(), admin);
        assertEq(v.treasury(), treasury);
        assertTrue(v.enabled(address(usd)) && v.enabled(address(eth)));
        assertEq(v.equity(), 0);
        assertEq(v.activeLoanCount(), 0);
        (uint256 cost, uint256 period, uint256 age, uint256 maxLtv, uint256 threshold, uint256 bonus) = v.parameters();
        assertEq(cost, 10e6);
        assertEq(period, 30 days);
        assertEq(age, 1 hours);
        assertEq(maxLtv, 6000);
        assertEq(threshold, 7500);
        assertEq(bonus, 500);
        assertEq(v.price(), 0);
        publish(2000e6);
        assertEq(v.priceUpdatedAt(), vm.getBlockTimestamp());
        // EC-01 / INV-03 / CL-05, EC-01 / INV-04 / CL-47
        fund(lp, usd, 1);
        fund(lp, eth, 1);
        vm.startPrank(lp);
        assertEq(v.withdraw(address(usd), 1), 1);
        assertEq(v.withdraw(address(eth), 1), 1);
        vm.stopPrank();
        assertEq(usd.balanceOf(lp), 1);
        assertEq(eth.balanceOf(lp), 1);
        assertEq(v.totalAvailable(address(usd)) + v.totalAvailable(address(eth)), 0);
    }
}
