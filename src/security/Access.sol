// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Access {
    error Unauthorized(address caller);
    error ZeroAddress();

    function requireCaller(address expected) internal view {
        if (msg.sender != expected) revert Unauthorized(msg.sender);
    }

    function requireNonZero(address account) internal pure {
        if (account == address(0)) revert ZeroAddress();
    }
}
