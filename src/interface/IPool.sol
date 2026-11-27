// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPool {
    event Supplied(address indexed provider, uint256 amount, uint256 shares);
    event Redeemed(address indexed provider, uint256 shares, uint256 amount);
    function supply(uint256 amount) external returns (uint256 shares);
    function redeem(uint256 shares) external returns (uint256 amount);
    function cash() external view returns (uint256);
    /// @notice Free MockUSD plus each active loan's principal and whole accrued interest at this block.
    function equity() external view returns (uint256);
    function totalShares() external view returns (uint256);
    function sharesOf(address provider) external view returns (uint256);
}
