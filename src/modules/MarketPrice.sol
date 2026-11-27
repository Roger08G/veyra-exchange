// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IMarketConfig} from "../interface/IMarketConfig.sol";

library MarketPrice {
    uint256 internal constant MAX_AGE = 1 hours;

    struct Quote {
        uint256 value;
        uint256 publishedAt;
    }

    function publish(Quote storage quote, uint256 value) internal {
        if (value == 0) revert IMarketConfig.InvalidPrice();
        quote.value = value;
        quote.publishedAt = block.timestamp;
    }

    function current(Quote storage quote) internal view returns (uint256) {
        if (quote.value == 0) revert IMarketConfig.InvalidPrice();
        if (block.timestamp < quote.publishedAt || block.timestamp - quote.publishedAt > MAX_AGE) {
            revert IMarketConfig.StalePrice();
        }
        return quote.value;
    }
}
