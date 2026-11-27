// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Veyra} from "../../src/core/Veyra.sol";
import {MockUSD} from "../../src/tokens/MockUSD.sol";
import {MockETH} from "../../src/tokens/MockETH.sol";

/// @notice Deploy the reference market using local Anvil accounts.
contract DeployVeyra is Script {
    error LocalChainRequired();

    function run(address admin, address treasury) external returns (Veyra market) {
        if (block.chainid != 31337) revert LocalChainRequired();
        vm.startBroadcast(admin);
        MockUSD usd = new MockUSD(admin);
        MockETH eth = new MockETH(admin);
        market = new Veyra(address(usd), address(eth), admin, treasury);
        market.publishPrice(2_000e6);
        vm.stopBroadcast();
    }
}
