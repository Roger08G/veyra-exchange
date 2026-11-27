// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IMarketConfig {
    event PricePublished(uint256 price, uint256 timestamp);
    event AssetEnabled(address indexed token, bool enabled);
    error InvalidConfiguration();
    error UnsupportedAsset(address token);
    error AssetDisabled(address token);
    error OutstandingObligations(address token);
    error InvalidPrice();
    error StalePrice();
    function usd() external view returns (address);
    function eth() external view returns (address);
    function admin() external view returns (address);
    function treasury() external view returns (address);
    function enabled(address token) external view returns (bool);
    function setEnabled(address token, bool value) external;
    function price() external view returns (uint256);
    function priceUpdatedAt() external view returns (uint256);
    /// @param value Minimal MockUSD units per whole MockETH.
    function publishPrice(uint256 value) external;
    function parameters()
        external
        pure
        returns (
            uint256 planPrice,
            uint256 planDuration,
            uint256 maxPriceAge,
            uint256 maxLtvBps,
            uint256 liquidationLtvBps,
            uint256 bonusBps
        );
}
