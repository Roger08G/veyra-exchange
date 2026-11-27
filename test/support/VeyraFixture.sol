// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Veyra} from "../../src/core/Veyra.sol";
import {MockUSD} from "../../src/tokens/MockUSD.sol";
import {MockETH} from "../../src/tokens/MockETH.sol";
import {IERC20} from "../../src/interface/IERC20.sol";

interface IFaucet {
    function mint(address to, uint256 amount) external;
}

abstract contract VeyraFixture is Test {
    Veyra internal v;
    MockUSD internal usd;
    MockETH internal eth;
    address internal admin = makeAddr("admin");
    address internal treasury = makeAddr("treasury");
    address internal lp = makeAddr("lp");
    address internal borrower = makeAddr("borrower");
    address internal liquidator = makeAddr("liquidator");

    function setUp() public virtual {
        usd = new MockUSD(address(this));
        eth = new MockETH(address(this));
        v = new Veyra(address(usd), address(eth), admin, treasury);
    }

    function fund(address who, IERC20 asset, uint256 amount) internal {
        IFaucet(address(asset)).mint(who, amount);
        vm.startPrank(who);
        asset.approve(address(v), amount);
        v.deposit(address(asset), amount);
        vm.stopPrank();
    }

    function publish(uint256 value) internal {
        vm.prank(admin);
        v.publishPrice(value);
    }
}
