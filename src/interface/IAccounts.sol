// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAccounts {
    event Deposited(address indexed account, address indexed token, uint256 amount);
    event Withdrawn(
        address indexed account, address indexed token, uint256 gross, uint256 net, uint256 fee, bool paidPlan
    );
    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint256 gross) external returns (uint256 net);
    function available(address account, address token) external view returns (uint256);
    function totalAvailable(address token) external view returns (uint256);
}
