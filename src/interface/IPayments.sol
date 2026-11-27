// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPayments {
    event Payment(
        address indexed sender,
        address indexed recipient,
        address indexed token,
        uint256 gross,
        uint256 net,
        uint256 fee,
        bool paidPlan
    );
    function pay(address recipient, uint256 gross) external returns (uint256 net);
}
