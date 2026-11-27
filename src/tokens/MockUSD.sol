// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockToken} from "./MockToken.sol";

contract MockUSD is MockToken {
    constructor(address minter_) MockToken("MockUSD", "MockUSD", 6, minter_) {}
}
