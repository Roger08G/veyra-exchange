// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITreasury {
    event RevenueWithdrawn(address indexed treasury, address indexed token, uint256 amount);
    function retained(address token) external view returns (uint256);
    function withdrawRevenue(address token, uint256 amount) external;
}
