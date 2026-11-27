// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockToken} from "./MockToken.sol";

contract MockETH is MockToken {
    constructor(address minter_) MockToken("MockETH", "MockETH", 18, minter_) {}
}
