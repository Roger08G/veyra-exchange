// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FullMath} from "../libraries/FullMath.sol";

/// @dev EC-05 through EC-07. All amounts use the native units of their respective tokens.
library Loans {
    uint256 internal constant MAX_LTV_BPS = 6_000;
    uint256 internal constant LIQUIDATION_LTV_BPS = 7_500;
    uint256 internal constant BONUS_BPS = 500;
    uint256 private constant BPS = 10_000;
    uint256 private constant INTEREST_DENOMINATOR = BPS * 365 days;
    uint256 private constant LTV_SCALE = 1e18 * BPS;
    uint256 private constant BONUS_SCALE = (1e18 * (BPS + BONUS_BPS)) / BPS;

    error InvalidLoanTerms();
    error ActiveLoanExists();
    error InactiveLoan();
    error NotBorrower();
    error SelfLiquidation();
    error OpeningLtvExceeded();
    error NotLiquidatable();
    error InvalidRepayment();

    enum Status {
        None,
        Active,
        Repaid,
        Liquidated
    }

    struct Position {
        address borrower;
        Status status;
        uint256 principal;
        uint256 collateral;
        uint256 interest;
        uint256 remainder;
        uint256 openedAt;
        uint256 lastAccrued;
        uint256 annualRateBps;
        uint256 openingFeeBps;
    }

    struct State {
        uint256 lastId;
        uint256 totalCollateral;
        mapping(address => uint256) activeId;
        mapping(uint256 => Position) positions;
        uint256[] activeIds;
        mapping(uint256 => uint256) activeIndex;
    }

    struct Settlement {
        address borrower;
        uint256 debt;
        uint256 repaid;
        uint256 badDebt;
        uint256 seized;
        uint256 returnedCollateral;
        uint256 interestPaid;
        uint256 principalPaid;
    }

    function open(
        State storage self,
        address borrower,
        uint256 principal,
        uint256 collateral,
        uint256 price,
        uint256 annualRateBps,
        uint256 openingFeeBps
    ) internal returns (uint256 id) {
        if (principal == 0 || collateral == 0 || price == 0 || openingFeeBps >= BPS) {
            revert InvalidLoanTerms();
        }
        if (self.activeId[borrower] != 0) revert ActiveLoanExists();
        if (FullMath.scaledProductLessThan(collateral, price, MAX_LTV_BPS, principal, LTV_SCALE)) {
            revert OpeningLtvExceeded();
        }

        id = ++self.lastId;
        Position storage position = self.positions[id];
        position.borrower = borrower;
        position.status = Status.Active;
        position.principal = principal;
        position.collateral = collateral;
        position.openedAt = block.timestamp;
        position.lastAccrued = block.timestamp;
        position.annualRateBps = annualRateBps;
        position.openingFeeBps = openingFeeBps;
        self.activeId[borrower] = id;
        self.activeIndex[id] = self.activeIds.length;
        self.activeIds.push(id);
        self.totalCollateral += collateral;
    }

    function projected(State storage self, uint256 id) internal view returns (uint256 interest, uint256 remainder) {
        Position storage position = self.positions[id];
        if (position.status == Status.None) revert InactiveLoan();
        if (position.status != Status.Active) return (0, 0);
        return projectActive(position);
    }

    function totalDebt(State storage self) internal view returns (uint256 debt) {
        uint256 count = self.activeIds.length;
        for (uint256 i; i < count; ++i) {
            Position storage position = self.positions[self.activeIds[i]];
            (uint256 interest,) = projectActive(position);
            debt += position.principal + interest;
        }
    }

    function projectActive(Position storage position) private view returns (uint256 interest, uint256 remainder) {
        uint256 elapsed = block.timestamp - position.lastAccrued;
        uint256 rate = position.annualRateBps;
        interest = position.interest;
        remainder = position.remainder;
        if (elapsed == 0 || rate == 0) return (interest, remainder);

        // Split principal*elapsed into whole units and a residual before multiplying by rate.
        // This also covers a large elapsed value when rate*elapsed itself would overflow.
        uint256 denominator = INTEREST_DENOMINATOR;
        uint256 principal = position.principal;
        uint256 whole = FullMath.mulDiv(principal, elapsed, denominator);
        uint256 residual = mulmod(principal, elapsed, denominator);
        interest += whole * rate + FullMath.mulDiv(residual, rate, denominator);
        remainder += mulmod(residual, rate, denominator);
        if (remainder >= denominator) {
            ++interest;
            remainder -= denominator;
        }
    }

    function repay(State storage self, address borrower, uint256 id, uint256 amount, bool full)
        internal
        returns (uint256 interestPaid, uint256 principalPaid, uint256 releasedCollateral)
    {
        Position storage position = self.positions[id];
        if (position.status != Status.Active) revert InactiveLoan();
        if (position.borrower != borrower) revert NotBorrower();
        (uint256 interest, uint256 remainder) = projectActive(position);
        uint256 debt = position.principal + interest;
        if (full) amount = debt;
        if (amount == 0 || amount > debt) revert InvalidRepayment();
        interestPaid = amount > interest ? interest : amount;
        principalPaid = amount - interestPaid;
        if (amount == debt) {
            releasedCollateral = position.collateral;
            close(self, id, position, Status.Repaid);
        } else {
            position.principal -= principalPaid;
            position.interest = interest - interestPaid;
            position.remainder = remainder;
            position.lastAccrued = block.timestamp;
        }
    }

    function liquidate(State storage self, address liquidator, uint256 id, uint256 price)
        internal
        returns (Settlement memory settlement)
    {
        Position storage position = self.positions[id];
        if (position.status != Status.Active) revert InactiveLoan();
        if (liquidator == position.borrower) revert SelfLiquidation();
        if (price == 0) revert InvalidLoanTerms();
        (uint256 interest,) = projectActive(position);
        uint256 debt = position.principal + interest;
        uint256 collateral = position.collateral;
        if (!FullMath.scaledProductLessThan(collateral, price, LIQUIDATION_LTV_BPS, debt, LTV_SCALE)) {
            revert NotLiquidatable();
        }

        // Choose the smaller side before division so even an uncapped quote above uint256 is valid.
        // The first branch buys all collateral. The other pays all debt and rounds the award up.
        if (FullMath.scaledProductLessThan(collateral, price, 1, debt, BONUS_SCALE)) {
            settlement.repaid = FullMath.mulDivUp(collateral, price, BONUS_SCALE);
            settlement.seized = collateral;
        } else {
            settlement.repaid = debt;
            settlement.seized = FullMath.mulDivUp(debt, BONUS_SCALE, price);
        }
        settlement.borrower = position.borrower;
        settlement.debt = debt;
        settlement.badDebt = debt - settlement.repaid;
        settlement.returnedCollateral = collateral - settlement.seized;
        settlement.interestPaid = settlement.repaid > interest ? interest : settlement.repaid;
        settlement.principalPaid = settlement.repaid - settlement.interestPaid;
        close(self, id, position, Status.Liquidated);
    }

    function close(State storage self, uint256 id, Position storage position, Status status) private {
        uint256 index = self.activeIndex[id];
        uint256 lastIndex = self.activeIds.length - 1;
        if (index != lastIndex) {
            uint256 moved = self.activeIds[lastIndex];
            self.activeIds[index] = moved;
            self.activeIndex[moved] = index;
        }
        self.activeIds.pop();
        delete self.activeIndex[id];
        delete self.activeId[position.borrower];
        self.totalCollateral -= position.collateral;
        position.collateral = 0;
        position.principal = 0;
        position.interest = 0;
        position.remainder = 0;
        position.lastAccrued = block.timestamp;
        position.status = status;
    }
}
