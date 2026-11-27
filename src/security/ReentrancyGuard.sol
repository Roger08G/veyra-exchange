// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @dev Share one lock across all state-changing entry points of the custodian.
abstract contract ReentrancyGuard {
    error ReentrantCall();

    uint256 private _lock = 1;

    modifier nonReentrant() {
        if (_lock != 1) revert ReentrantCall();
        _lock = 2;
        _;
        _lock = 1;
    }
}
