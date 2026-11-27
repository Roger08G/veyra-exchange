// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "../interface/IERC20.sol";

library ExactTransfer {
    error TransferFailed(address token);
    error InexactTransfer(address token);
    error InsufficientBacking(address token, uint256 balance, uint256 required);

    function pull(address token, address owner, uint256 amount) internal {
        IERC20 asset = IERC20(token);
        uint256 ownerBefore = asset.balanceOf(owner);
        uint256 custodyBefore = asset.balanceOf(address(this));
        if (!asset.transferFrom(owner, address(this), amount)) revert TransferFailed(token);
        verifyDelta(token, ownerBefore, asset.balanceOf(owner), amount);
        verifyDelta(token, asset.balanceOf(address(this)), custodyBefore, amount);
    }

    /// @param remaining All obligations in this token after the proposed withdrawal.
    function push(address token, address recipient, uint256 amount, uint256 remaining) internal {
        IERC20 asset = IERC20(token);
        uint256 custodyBefore = asset.balanceOf(address(this));
        uint256 recipientBefore = asset.balanceOf(recipient);
        if (!asset.transfer(recipient, amount)) revert TransferFailed(token);
        uint256 custodyAfter = asset.balanceOf(address(this));
        verifyDelta(token, custodyBefore, custodyAfter, amount);
        verifyDelta(token, asset.balanceOf(recipient), recipientBefore, amount);
        if (custodyAfter < remaining) revert InsufficientBacking(token, custodyAfter, remaining);
    }

    function verifyDelta(address token, uint256 higher, uint256 lower, uint256 expected) private pure {
        if (lower > higher || higher - lower != expected) revert InexactTransfer(token);
    }
}
