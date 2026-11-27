// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPlans {
    event PlanPurchased(
        address indexed account, address indexed token, uint256 fee, uint256 start, uint256 expiry, bool renewal
    );
    function subscribe() external returns (uint256 expiry);
    function renew() external returns (uint256 expiry);
    function plan(address account) external view returns (bool paid, uint256 expiry);
    function planTerms(bool paid)
        external
        pure
        returns (uint256 withdrawalBps, uint256 paymentBps, uint256 openingBps, uint256 annualBps);
}
