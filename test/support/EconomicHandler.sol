// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IVeyra} from "../../src/interface/IVeyra.sol";
import {IERC20} from "../../src/interface/IERC20.sol";
import {ILoans} from "../../src/interface/ILoans.sol";

/// @dev The model reads only the clock and its own journal when pricing a transition.
/// All actor endowments bound the products below uint256; production math is never imported.
contract EconomicHandler is Test {
    uint256 public constant INITIAL_USD = 10_000e6;
    uint256 public constant INITIAL_ETH = 10 ether;
    uint256 private constant YEAR_BPS = 365 days * 10_000;
    uint256 private constant ACTORS = 5;

    struct Debt {
        uint256 id;
        uint256 principal;
        uint256 interest;
        uint256 carry;
        uint256 timestamp;
        uint256 annualBps;
        uint256 openingBps;
        uint256 collateral;
    }

    struct ModelAccount {
        uint256[2] wallet;
        uint256[2] available;
        uint256 shares;
        uint256 expiry;
        Debt loan;
    }

    IVeyra private immutable market;
    IERC20[2] private token;
    address private immutable admin;
    address private immutable treasury;
    address[5] private actors;
    ModelAccount[5] private accounts;
    uint256[2] private retained;
    uint256[2] private donated;
    uint256[2] private treasuryWallet;
    uint256 private cash;
    uint256 private supply;
    uint256 private nextId;
    uint256 private lastPrice;
    uint256 private publishedAt;

    constructor(IVeyra market_, IERC20 usd, IERC20 eth, address admin_, address treasury_, address[5] memory actors_) {
        market = market_;
        token = [usd, eth];
        admin = admin_;
        treasury = treasury_;
        actors = actors_;
        for (uint256 i; i < ACTORS; ++i) {
            accounts[i].wallet = [INITIAL_USD, INITIAL_ETH];
        }
    }

    function deposit(uint256 actorSeed, bool useEth, uint256 amountSeed) external {
        uint256 i = actorSeed % ACTORS;
        uint256 t = useEth ? 1 : 0;
        uint256 amount = sized(amountSeed, accounts[i].wallet[t]);
        if (amount == 0) return;
        vm.prank(actors[i]);
        market.deposit(address(token[t]), amount);
        accounts[i].wallet[t] -= amount;
        accounts[i].available[t] += amount;
    }

    function withdraw(uint256 actorSeed, bool useEth, uint256 amountSeed) external {
        uint256 i = actorSeed % ACTORS;
        uint256 t = useEth ? 1 : 0;
        uint256 gross = sized(amountSeed, accounts[i].available[t]);
        if (gross == 0) return;
        uint256 fee = gross * (block.timestamp < accounts[i].expiry ? 5 : 10) / 10_000;
        vm.prank(actors[i]);
        assertEq(market.withdraw(address(token[t]), gross), gross - fee);
        accounts[i].available[t] -= gross;
        accounts[i].wallet[t] += gross - fee;
        retained[t] += fee;
    }

    function donate(uint256 actorSeed, bool useEth, uint256 amountSeed) external {
        uint256 i = actorSeed % ACTORS;
        uint256 t = useEth ? 1 : 0;
        uint256 amount = sized(amountSeed, accounts[i].wallet[t]);
        if (amount == 0) return;
        vm.prank(actors[i]);
        assertTrue(token[t].transfer(address(market), amount));
        accounts[i].wallet[t] -= amount;
        donated[t] += amount;
    }

    function pay(uint256 actorSeed, uint256 recipientSeed, uint256 amountSeed) external {
        uint256 i = actorSeed % ACTORS;
        uint256 recipient = otherActor(i, recipientSeed);
        uint256 gross = sized(amountSeed, accounts[i].available[0]);
        if (gross == 0) return;
        uint256 fee = gross * (block.timestamp < accounts[i].expiry ? 5 : 20) / 10_000;
        vm.prank(actors[i]);
        assertEq(market.pay(actors[recipient], gross), gross - fee);
        accounts[i].available[0] -= gross;
        accounts[recipient].available[0] += gross - fee;
        retained[0] += fee;
    }

    function buyPlan(uint256 actorSeed, bool preferRenew) external {
        uint256 i = actorSeed % ACTORS;
        ModelAccount storage a = accounts[i];
        if (a.available[0] < 10e6) return;
        uint256 oldExpiry = a.expiry;
        bool active = block.timestamp < oldExpiry;
        uint256 expiry = (active ? oldExpiry : block.timestamp) + 30 days;
        vm.prank(actors[i]);
        uint256 result = active || (oldExpiry != 0 && preferRenew) ? market.renew() : market.subscribe();
        assertEq(result, expiry);
        a.expiry = expiry;
        a.available[0] -= 10e6;
        retained[0] += 10e6;
    }

    function supplyLiquidity(uint256 actorSeed, uint256 amountSeed) external {
        uint256 i = actorSeed % ACTORS;
        uint256 amount = sized(amountSeed, accounts[i].available[0]);
        if (amount == 0) return;
        uint256 equity = modelEquity();
        if (equity == 0 && supply != 0) return;
        uint256 shares = supply == 0 ? amount : amount * supply / equity;
        if (shares == 0) return;
        vm.prank(actors[i]);
        assertEq(market.supply(amount), shares);
        accounts[i].shares += shares;
        accounts[i].available[0] -= amount;
        supply += shares;
        cash += amount;
    }

    function redeemLiquidity(uint256 actorSeed, uint256 shareSeed) external {
        uint256 i = actorSeed % ACTORS;
        uint256 shares = sized(shareSeed, accounts[i].shares);
        if (shares == 0) return;
        uint256 amount = shares * modelEquity() / supply;
        if (amount == 0 || amount > cash) return;
        vm.prank(actors[i]);
        assertEq(market.redeem(shares), amount);
        accounts[i].shares -= shares;
        accounts[i].available[0] += amount;
        supply -= shares;
        cash -= amount;
    }

    function advanceTime(uint256 secondsSeed) external {
        vm.warp(block.timestamp + 1 + secondsSeed % 60 days);
    }

    function changePrice(uint256 priceSeed) external {
        publish(sized(priceSeed, 4_000e6));
    }

    function open(uint256 actorSeed, uint256 collateralSeed, uint256 principalSeed) external {
        uint256 i = actorSeed % ACTORS;
        ModelAccount storage a = accounts[i];
        if (a.loan.id != 0 || cash == 0 || lastPrice == 0) return;
        uint256 collateral = sized(collateralSeed, a.available[1]);
        uint256 ceiling = collateral * lastPrice * 60 / (100 * 1 ether);
        uint256 amount = sized(principalSeed, min(cash, ceiling));
        if (amount == 0) return;
        if (block.timestamp - publishedAt > 3600) publish(lastPrice);
        bool paid = block.timestamp < a.expiry;
        uint256 bps = paid ? 50 : 100;
        uint256 fee = amount * bps / 10_000;
        vm.prank(actors[i]);
        assertEq(market.openLoan(amount, collateral), ++nextId);
        a.loan = Debt(nextId, amount, 0, 0, block.timestamp, paid ? 500 : 800, bps, collateral);
        a.available[1] -= collateral;
        a.available[0] += amount - fee;
        cash -= amount;
        retained[0] += fee;
    }

    function repayLoan(uint256 actorSeed, uint256 amountSeed) external {
        uint256 i = activeBorrower(actorSeed);
        if (i == ACTORS) return;
        ModelAccount storage a = accounts[i];
        Debt storage loan = a.loan;
        (uint256 interest, uint256 carry) = project(loan);
        uint256 debt = loan.principal + interest;
        uint256 amount = sized(amountSeed, min(a.available[0], debt));
        if (amount == 0) return;
        vm.prank(actors[i]);
        if (amount == debt) {
            assertEq(market.repayAll(loan.id), debt);
            a.available[1] += loan.collateral;
            delete a.loan;
        } else {
            market.repay(loan.id, amount);
            uint256 interestPaid = min(amount, interest);
            loan.interest = interest - interestPaid;
            loan.principal -= amount - interestPaid;
            loan.carry = carry;
            loan.timestamp = block.timestamp;
        }
        a.available[0] -= amount;
        cash += amount;
    }

    function liquidateLoan(uint256 actorSeed, uint256 liquidatorSeed, uint256 priceSeed) external {
        uint256 i = activeBorrower(actorSeed);
        if (i == ACTORS) return;
        uint256 j = otherActor(i, liquidatorSeed);
        Debt storage loan = accounts[i].loan;
        (uint256 interest,) = project(loan);
        uint256 debt = loan.principal + interest;
        uint256 collateral = loan.collateral;
        // Largest price strictly below solvency at the current debt, even in the one-unit case.
        uint256 priceLimit = (debt * 1 ether * 100 - 1) / (collateral * 75);
        uint256 price = sized(priceSeed, min(priceLimit, 4_000e6));
        if (price == 0) return;
        uint256 repaid = min(debt, ceilDiv(collateral * price * 100, 105 ether));
        if (accounts[j].available[0] < repaid) return;
        uint256 seized = min(collateral, ceilDiv(repaid * 105 ether, price * 100));
        publish(price);
        vm.prank(actors[j]);
        market.liquidate(loan.id);
        accounts[j].available[0] -= repaid;
        accounts[j].available[1] += seized;
        accounts[i].available[1] += collateral - seized;
        cash += repaid;
        delete accounts[i].loan;
    }

    function withdrawRevenue(bool useEth, uint256 amountSeed) external {
        uint256 t = useEth ? 1 : 0;
        uint256 amount = sized(amountSeed, retained[t]);
        if (amount == 0) return;
        vm.prank(treasury);
        market.withdrawRevenue(address(token[t]), amount);
        retained[t] -= amount;
        treasuryWallet[t] += amount;
    }

    function assertModel() external view {
        uint256 locked;
        uint256 active;
        uint256 shareSum;
        uint256[2] memory availableSum;
        for (uint256 i; i < ACTORS; ++i) {
            ModelAccount storage a = accounts[i];
            address actor = actors[i];
            for (uint256 t; t < 2; ++t) {
                assertEq(token[t].balanceOf(actor), a.wallet[t], "actor wallet");
                assertEq(market.available(actor, address(token[t])), a.available[t], "available");
                availableSum[t] += a.available[t];
            }
            assertEq(market.sharesOf(actor), a.shares, "provider shares");
            (bool paid, uint256 expiry) = market.plan(actor);
            assertEq(paid, block.timestamp < a.expiry, "effective plan");
            assertEq(expiry, a.expiry, "plan expiry");
            shareSum += a.shares;
            assertEq(market.activeLoan(actor), a.loan.id, "active loan ID");
            if (a.loan.id == 0) continue;
            checkLoan(actor, a.loan);
            ++active;
            locked += a.loan.collateral;
        }
        assertEq(market.price(), lastPrice, "published price");
        assertEq(market.priceUpdatedAt(), publishedAt, "publication time");
        assertEq(market.activeLoanCount(), active, "active count");
        assertEq(market.totalCollateral(), locked, "collateral");
        assertEq(shareSum, supply, "model shares");
        assertEq(market.totalShares(), shareSum, "share supply");
        assertEq(market.cash(), cash, "pool cash");
        assertEq(market.equity(), modelEquity(), "pool equity");
        for (uint256 t; t < 2; ++t) {
            assertEq(market.totalAvailable(address(token[t])), availableSum[t], "total available");
            assertEq(market.retained(address(token[t])), retained[t], "retained revenue");
            assertEq(token[t].balanceOf(treasury), treasuryWallet[t], "treasury wallet");
            uint256 expectedCustody = availableSum[t] + (t == 0 ? cash : locked) + retained[t] + donated[t];
            assertEq(token[t].balanceOf(address(market)), expectedCustody, "ERC20 custody reconciliation");
        }
    }

    function checkLoan(address actor, Debt storage expected) private view {
        ILoans.LoanView memory actual = market.loan(expected.id);
        (uint256 interest, uint256 carry) = project(expected);
        assertEq(actual.borrower, actor, "borrower");
        assertEq(actual.status, 1, "loan status");
        assertEq(actual.principal, expected.principal, "principal");
        assertEq(actual.interest, interest, "interest");
        assertEq(actual.debt, expected.principal + interest, "debt");
        assertEq(actual.remainder, carry, "fractional carry");
        assertEq(actual.lastAccrued, expected.timestamp, "last accrual");
        assertEq(actual.annualRateBps, expected.annualBps, "annual bps");
        assertEq(actual.openingFeeBps, expected.openingBps, "opening bps");
        assertEq(actual.collateral, expected.collateral, "loan collateral");
    }

    function modelEquity() private view returns (uint256 equity) {
        equity = cash;
        for (uint256 i; i < ACTORS; ++i) {
            Debt storage loan = accounts[i].loan;
            if (loan.id == 0) continue;
            (uint256 interest,) = project(loan);
            equity += loan.principal + interest;
        }
    }

    function project(Debt storage loan) private view returns (uint256 interest, uint256 carry) {
        uint256 numerator = loan.principal * loan.annualBps * (block.timestamp - loan.timestamp) + loan.carry;
        return (loan.interest + numerator / YEAR_BPS, numerator % YEAR_BPS);
    }

    function activeBorrower(uint256 seed) private view returns (uint256) {
        uint256 start = seed % ACTORS;
        for (uint256 k; k < ACTORS; ++k) {
            uint256 i = (start + k) % ACTORS;
            if (accounts[i].loan.id != 0) return i;
        }
        return ACTORS;
    }

    function publish(uint256 price) private {
        vm.prank(admin);
        market.publishPrice(price);
        lastPrice = price;
        publishedAt = block.timestamp;
    }

    function otherActor(uint256 actor, uint256 seed) private pure returns (uint256) {
        return (actor + 1 + seed % (ACTORS - 1)) % ACTORS;
    }

    // Zero selects the maximum. Known positive amounts inside the interval are reproducible.
    function sized(uint256 seed, uint256 maximum) private pure returns (uint256) {
        if (maximum == 0 || seed == 0) return maximum;
        return 1 + (seed - 1) % maximum;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function ceilDiv(uint256 a, uint256 b) private pure returns (uint256) {
        return a / b + (a % b == 0 ? 0 : 1);
    }
}
