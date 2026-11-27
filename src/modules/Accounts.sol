// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ExactTransfer} from "../security/ExactTransfer.sol";
import {FullMath} from "../libraries/FullMath.sol";

library Accounts {
    uint256 internal constant PLAN_PRICE = 10e6;
    uint256 internal constant PLAN_DURATION = 30 days;

    struct State {
        mapping(address user => mapping(address token => uint256)) balance;
        mapping(address token => uint256) total;
        mapping(address token => uint256) revenue;
        mapping(address user => uint256) expiresAt;
    }

    error ZeroAmount();
    error InvalidPayee();
    error InsufficientAvailable(address user, address token);
    error InsufficientRevenue(address token);
    error PlanAlreadyActive();
    error NoSubscriptionHistory();

    function credit(State storage self, address user, address token, uint256 amount) internal {
        self.balance[user][token] += amount;
        self.total[token] += amount;
    }

    function debit(State storage self, address user, address token, uint256 amount) internal {
        uint256 available = self.balance[user][token];
        if (amount > available) revert InsufficientAvailable(user, token);
        self.balance[user][token] = available - amount;
        self.total[token] -= amount;
    }

    function collect(State storage self, address token, uint256 amount) internal {
        if (amount != 0) self.revenue[token] += amount;
    }

    function terms(bool paid)
        internal
        pure
        returns (uint256 withdrawalBps, uint256 paymentBps, uint256 openingBps, uint256 annualBps)
    {
        if (paid) return (5, 5, 50, 500);
        return (10, 20, 100, 800);
    }

    function fee(uint256 gross, uint256 bps) internal pure returns (uint256) {
        return FullMath.mulDiv(gross, bps, 10_000);
    }

    function isPaid(State storage self, address user) internal view returns (bool) {
        return block.timestamp < self.expiresAt[user];
    }

    function deposit(State storage self, address user, address token, uint256 amount) internal {
        if (amount == 0) revert ZeroAmount();
        ExactTransfer.pull(token, user, amount);
        credit(self, user, token, amount);
    }

    function withdraw(State storage self, address user, address token, uint256 gross, uint256 otherReserves)
        internal
        returns (uint256 charge)
    {
        if (gross == 0) revert ZeroAmount();
        (uint256 bps,,,) = terms(isPaid(self, user));
        charge = fee(gross, bps);
        debit(self, user, token, gross);
        collect(self, token, charge);
        ExactTransfer.push(token, user, gross - charge, self.total[token] + self.revenue[token] + otherReserves);
    }

    function pay(State storage self, address sender, address recipient, address usd, uint256 gross)
        internal
        returns (uint256 charge)
    {
        if (recipient == address(0) || recipient == sender) {
            revert InvalidPayee();
        }
        if (gross == 0) revert ZeroAmount();
        (, uint256 bps,,) = terms(isPaid(self, sender));
        charge = fee(gross, bps);
        debit(self, sender, usd, gross);
        credit(self, recipient, usd, gross - charge);
        collect(self, usd, charge);
    }

    function subscribe(State storage self, address user, address usd, bool renewal)
        internal
        returns (uint256 start, uint256 end)
    {
        uint256 previousEnd = self.expiresAt[user];
        if (renewal && previousEnd == 0) revert NoSubscriptionHistory();
        if (!renewal && block.timestamp < previousEnd) {
            revert PlanAlreadyActive();
        }
        start = block.timestamp < previousEnd ? previousEnd : block.timestamp;
        end = start + PLAN_DURATION;
        debit(self, user, usd, PLAN_PRICE);
        collect(self, usd, PLAN_PRICE);
        self.expiresAt[user] = end;
    }

    function withdrawRevenue(State storage self, address treasury, address token, uint256 amount, uint256 otherReserves)
        internal
    {
        if (amount == 0) revert ZeroAmount();
        uint256 retained = self.revenue[token];
        if (amount > retained) revert InsufficientRevenue(token);
        self.revenue[token] = retained - amount;
        ExactTransfer.push(token, treasury, amount, self.total[token] + self.revenue[token] + otherReserves);
    }
}
