// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FullMath} from "../libraries/FullMath.sol";

/// @dev EC-04. Shares and cash are in minimal MockUSD units; valuation uses pre-operation equity.
library Pool {
    error InvalidPoolState();
    error ZeroAmount();
    error ZeroShares();
    error InsufficientShares();
    error InsufficientCash();
    error EquityOverflow();

    struct State {
        uint256 cash;
        uint256 totalShares;
        mapping(address => uint256) shares;
    }

    function supply(State storage self, address account, uint256 amount, uint256 equity)
        internal
        returns (uint256 minted)
    {
        if (amount == 0) revert ZeroAmount();
        if ((self.totalShares == 0) != (equity == 0)) revert InvalidPoolState();
        if (amount > type(uint256).max - equity) revert EquityOverflow();
        minted = equity == 0 ? amount : FullMath.mulDiv(amount, self.totalShares, equity);
        if (minted == 0) revert ZeroShares();
        self.shares[account] += minted;
        self.totalShares += minted;
        self.cash += amount;
    }

    function redeem(State storage self, address account, uint256 shares, uint256 equity)
        internal
        returns (uint256 amount)
    {
        if (shares == 0) revert ZeroShares();
        if (shares > self.shares[account]) revert InsufficientShares();
        amount = FullMath.mulDiv(shares, equity, self.totalShares);
        if (amount == 0) revert ZeroAmount();
        lend(self, amount);
        self.shares[account] -= shares;
        self.totalShares -= shares;
    }

    function lend(State storage self, uint256 amount) internal {
        if (amount > self.cash) revert InsufficientCash();
        self.cash -= amount;
    }

    function collect(State storage self, uint256 amount) internal {
        self.cash += amount;
    }
}
