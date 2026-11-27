// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IVeyra} from "../interface/IVeyra.sol";
import {IERC20} from "../interface/IERC20.sol";
import {Accounts} from "../modules/Accounts.sol";
import {Loans} from "../modules/Loans.sol";
import {Pool} from "../modules/Pool.sol";
import {MarketPrice} from "../modules/MarketPrice.sol";
import {Access} from "../security/Access.sol";
import {ReentrancyGuard} from "../security/ReentrancyGuard.sol";

/// @notice Custodia y punto de entrada del mercado local MockUSD/MockETH.
contract Veyra is IVeyra, ReentrancyGuard {
    using Accounts for Accounts.State;
    using Loans for Loans.State;
    using Pool for Pool.State;
    using MarketPrice for MarketPrice.Quote;

    address public immutable usd;
    address public immutable eth;
    address public immutable admin;
    address public immutable treasury;
    mapping(address token => bool) public enabled;

    Accounts.State private ledger;
    Loans.State private loans;
    Pool.State private pool;
    MarketPrice.Quote private quote;

    constructor(address usd_, address eth_, address admin_, address treasury_) {
        if (
            admin_ == address(0) || treasury_ == address(0) || admin_ == treasury_ || admin_ == address(this)
                || treasury_ == address(this)
        ) revert InvalidConfiguration();
        if (usd_ == eth_ || usd_.code.length == 0 || eth_.code.length == 0) revert InvalidConfiguration();
        if (IERC20(usd_).decimals() != 6 || IERC20(eth_).decimals() != 18) revert InvalidConfiguration();
        usd = usd_;
        eth = eth_;
        admin = admin_;
        treasury = treasury_;
        enabled[usd_] = true;
        enabled[eth_] = true;
    }

    function setEnabled(address token, bool value) external nonReentrant {
        Access.requireCaller(admin);
        if (token != usd && token != eth) revert UnsupportedAsset(token);
        if (
            !value
                && (ledger.total[token] != 0
                    || ledger.revenue[token] != 0
                    || _otherReserves(token) != 0
                    || loans.activeIds.length != 0)
        ) revert OutstandingObligations(token);
        enabled[token] = value;
        emit AssetEnabled(token, value);
    }

    function publishPrice(uint256 value) external nonReentrant {
        Access.requireCaller(admin);
        quote.publish(value);
        emit PricePublished(value, block.timestamp);
    }

    function price() external view returns (uint256) {
        return quote.value;
    }

    function priceUpdatedAt() external view returns (uint256) {
        return quote.publishedAt;
    }

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
        )
    {
        return (
            Accounts.PLAN_PRICE,
            Accounts.PLAN_DURATION,
            MarketPrice.MAX_AGE,
            Loans.MAX_LTV_BPS,
            Loans.LIQUIDATION_LTV_BPS,
            Loans.BONUS_BPS
        );
    }

    function planTerms(bool paid)
        external
        pure
        returns (uint256 withdrawalBps, uint256 paymentBps, uint256 openingBps, uint256 annualBps)
    {
        return Accounts.terms(paid);
    }

    function deposit(address token, uint256 amount) external nonReentrant {
        _requireEnabled(token);
        ledger.deposit(msg.sender, token, amount);
        emit Deposited(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 gross) external nonReentrant returns (uint256 net) {
        _requireEnabled(token);
        uint256 fee = ledger.withdraw(msg.sender, token, gross, _otherReserves(token));
        net = gross - fee;
        emit Withdrawn(msg.sender, token, gross, net, fee, ledger.isPaid(msg.sender));
    }

    function pay(address recipient, uint256 gross) external nonReentrant returns (uint256 net) {
        _requireEnabled(usd);
        uint256 fee = ledger.pay(msg.sender, recipient, usd, gross);
        net = gross - fee;
        emit Payment(msg.sender, recipient, usd, gross, net, fee, ledger.isPaid(msg.sender));
    }

    function available(address account, address token) external view returns (uint256) {
        return ledger.balance[account][token];
    }

    function totalAvailable(address token) external view returns (uint256) {
        return ledger.total[token];
    }

    function retained(address token) external view returns (uint256) {
        return ledger.revenue[token];
    }

    function withdrawRevenue(address token, uint256 amount) external nonReentrant {
        Access.requireCaller(treasury);
        _requireEnabled(token);
        ledger.withdrawRevenue(treasury, token, amount, _otherReserves(token));
        emit RevenueWithdrawn(treasury, token, amount);
    }

    function subscribe() external nonReentrant returns (uint256) {
        return _purchasePlan(false);
    }

    function renew() external nonReentrant returns (uint256) {
        return _purchasePlan(true);
    }

    function _purchasePlan(bool renewal) private returns (uint256) {
        _requireEnabled(usd);
        (uint256 start, uint256 expiry) = ledger.subscribe(msg.sender, usd, renewal);
        emit PlanPurchased(msg.sender, usd, Accounts.PLAN_PRICE, start, expiry, renewal);
        return expiry;
    }

    function plan(address account) external view returns (bool paid, uint256 expiry) {
        return (ledger.isPaid(account), ledger.expiresAt[account]);
    }

    function cash() external view returns (uint256) {
        return pool.cash;
    }

    function equity() public view returns (uint256) {
        return pool.cash + loans.totalDebt();
    }

    function totalShares() external view returns (uint256) {
        return pool.totalShares;
    }

    function sharesOf(address provider) external view returns (uint256) {
        return pool.shares[provider];
    }

    function supply(uint256 amount) external nonReentrant returns (uint256 shares) {
        _requireEnabled(usd);
        ledger.debit(msg.sender, usd, amount);
        shares = pool.supply(msg.sender, amount, equity());
        emit Supplied(msg.sender, amount, shares);
    }

    function redeem(uint256 shares) external nonReentrant returns (uint256 amount) {
        _requireEnabled(usd);
        amount = pool.redeem(msg.sender, shares, equity());
        ledger.credit(msg.sender, usd, amount);
        emit Redeemed(msg.sender, shares, amount);
    }

    function openLoan(uint256 principal, uint256 collateral) external nonReentrant returns (uint256 id) {
        _requireMarket();
        (,, uint256 openingBps, uint256 annualBps) = Accounts.terms(ledger.isPaid(msg.sender));
        id = loans.open(msg.sender, principal, collateral, quote.current(), annualBps, openingBps);
        uint256 fee = Accounts.fee(principal, openingBps);
        pool.lend(principal);
        ledger.debit(msg.sender, eth, collateral);
        ledger.credit(msg.sender, usd, principal - fee);
        ledger.collect(usd, fee);
        emit LoanOpened(id, msg.sender, usd, principal, principal - fee, fee, collateral, annualBps, openingBps);
    }

    function repay(uint256 id, uint256 amount) external nonReentrant {
        _repay(id, amount, false);
    }

    function repayAll(uint256 id) external nonReentrant returns (uint256) {
        return _repay(id, 0, true);
    }

    function _repay(uint256 id, uint256 requested, bool full) private returns (uint256 amount) {
        _requireMarket();
        (uint256 interestPaid, uint256 principalPaid, uint256 released) = loans.repay(msg.sender, id, requested, full);
        amount = interestPaid + principalPaid;
        ledger.debit(msg.sender, usd, amount);
        pool.collect(amount);
        if (released != 0) ledger.credit(msg.sender, eth, released);
        emit Repaid(id, msg.sender, interestPaid, principalPaid, released);
    }

    function liquidate(uint256 id) external nonReentrant {
        _requireMarket();
        uint256 executionPrice = quote.current();
        Loans.Settlement memory result = loans.liquidate(msg.sender, id, executionPrice);
        ledger.debit(msg.sender, usd, result.repaid);
        pool.collect(result.repaid);
        ledger.credit(msg.sender, eth, result.seized);
        if (result.returnedCollateral != 0) ledger.credit(result.borrower, eth, result.returnedCollateral);
        emit Liquidated(
            id,
            msg.sender,
            result.borrower,
            result.debt,
            result.repaid,
            result.interestPaid,
            result.principalPaid,
            result.badDebt,
            result.seized,
            result.returnedCollateral,
            executionPrice
        );
    }

    function activeLoan(address borrower) external view returns (uint256) {
        return loans.activeId[borrower];
    }

    function activeLoanCount() external view returns (uint256) {
        return loans.activeIds.length;
    }

    function loanOpenedAt(uint256 id) external view returns (uint256) {
        return loans.positions[id].openedAt;
    }

    function totalCollateral() external view returns (uint256) {
        return loans.totalCollateral;
    }

    function loan(uint256 id) external view returns (LoanView memory result) {
        Loans.Position storage position = loans.positions[id];
        result.borrower = position.borrower;
        result.status = uint8(position.status);
        result.principal = position.principal;
        (result.interest, result.remainder) = loans.projected(id);
        result.debt = result.principal + result.interest;
        result.lastAccrued = position.lastAccrued;
        result.annualRateBps = position.annualRateBps;
        result.openingFeeBps = position.openingFeeBps;
        result.collateral = position.collateral;
    }

    function _requireEnabled(address token) private view {
        if (!enabled[token]) revert AssetDisabled(token);
    }

    function _requireMarket() private view {
        _requireEnabled(usd);
        _requireEnabled(eth);
    }

    function _otherReserves(address token) private view returns (uint256) {
        return token == usd ? pool.cash : loans.totalCollateral;
    }
}
