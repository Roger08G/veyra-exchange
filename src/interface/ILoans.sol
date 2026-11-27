// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILoans {
    struct LoanView {
        address borrower;
        uint8 status;
        uint256 principal;
        uint256 interest;
        uint256 debt;
        uint256 remainder;
        uint256 lastAccrued;
        uint256 annualRateBps;
        uint256 openingFeeBps;
        uint256 collateral;
    }
    event LoanOpened(
        uint256 indexed id,
        address indexed borrower,
        address indexed feeToken,
        uint256 principal,
        uint256 net,
        uint256 fee,
        uint256 collateral,
        uint256 annualRateBps,
        uint256 openingFeeBps
    );
    event Repaid(
        uint256 indexed id,
        address indexed borrower,
        uint256 interestPaid,
        uint256 principalPaid,
        uint256 releasedCollateral
    );
    /// @notice Borrow gross MockUSD against the caller's available MockETH. Fees reduce the net credit.
    function openLoan(uint256 principal, uint256 collateral) external returns (uint256 id);
    function repay(uint256 id, uint256 amount) external;
    /// @notice Close using the full debt at execution, even if the last published price has expired.
    function repayAll(uint256 id) external returns (uint256 amount);
    function loanOpenedAt(uint256 id) external view returns (uint256);
    function activeLoan(address borrower) external view returns (uint256);
    function activeLoanCount() external view returns (uint256);
    function totalCollateral() external view returns (uint256);
    /// @notice Interest, debt and remainder are projected at this block. lastAccrued is the last stored settlement time.
    function loan(uint256 id) external view returns (LoanView memory);
}
