// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILiquidations {
    event Liquidated(
        uint256 indexed id,
        address indexed liquidator,
        address indexed borrower,
        uint256 debt,
        uint256 repaid,
        uint256 interestPaid,
        uint256 principalPaid,
        uint256 badDebt,
        uint256 seized,
        uint256 returnedCollateral,
        uint256 executionPrice
    );
    function liquidate(uint256 id) external;
}
