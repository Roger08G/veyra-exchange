// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {FullMath} from "../../src/libraries/FullMath.sol";
import {Loans} from "../../src/modules/Loans.sol";
import {Pool} from "../../src/modules/Pool.sol";

contract CreditMathTest is Test {
    using Loans for Loans.State;
    using Pool for Pool.State;

    Loans.State private loans;
    Pool.State private pool;

    /// EC-04 / INV-02 / CL-17 and EC-07 / INV-02 / CL-04.
    function testFuzzProductsAgainstNativeIntegers(uint96 a, uint96 b, uint32 scale, uint96 c, uint96 d) public pure {
        uint256 product = uint256(a) * b;
        assertEq(FullMath.scaledProductLessThan(a, b, scale, c, d), product * scale < uint256(c) * d);
        uint256 divisor = uint256(d) + 1;
        assertEq(FullMath.mulDiv(a, b, divisor), product / divisor);
        uint256 expectedCeiling = product / divisor + (product % divisor == 0 ? 0 : 1);
        assertEq(FullMath.mulDivUp(a, b, divisor), expectedCeiling);
    }

    function testFuzzWideProductExactDivision(uint256 a, uint256 b) public pure {
        vm.assume(b != 0);
        assertEq(FullMath.mulDiv(a, b, b), a);
        assertEq(FullMath.mulDivUp(a, b, b), a);
        assertFalse(FullMath.scaledProductLessThan(a, b, 1, b, a));
    }

    function testWideDivisionWithRemainderAtMaximum() public pure {
        uint256 max = type(uint256).max;
        // (M-1)^2 = M*(M-2) + 1
        assertEq(FullMath.mulDiv(max - 1, max - 1, max), max - 2);
        assertEq(FullMath.mulDivUp(max - 1, max - 1, max), max - 1);
        assertFalse(FullMath.scaledProductLessThan(max, max, max, max, max));
        assertTrue(FullMath.scaledProductLessThan(max, max - 1, 1, max, max));
    }

    // Independent base-2^128 multiplication for the identity a*b = quotient*divisor + remainder.
    function schoolbook(uint256 a, uint256 b) private pure returns (uint256 high, uint256 low) {
        uint256 mask = type(uint128).max;
        uint256 lowProduct = (a & mask) * (b & mask);
        uint256 cross1 = (a >> 128) * (b & mask);
        uint256 cross2 = (b >> 128) * (a & mask);
        uint256 middle = (lowProduct >> 128) + (cross1 & mask) + (cross2 & mask);
        high = (a >> 128) * (b >> 128) + (cross1 >> 128) + (cross2 >> 128) + (middle >> 128);
        low = (middle << 128) | (lowProduct & mask);
    }

    function testFuzzWideQuotientIdentity(uint256 a, uint256 b, uint256 divisor) public pure {
        (uint256 high, uint256 low) = schoolbook(a, b);
        if (divisor <= high) divisor = high + 1;
        uint256 quotient = FullMath.mulDiv(a, b, divisor);
        uint256 remainder = mulmod(a, b, divisor);
        (uint256 observedHigh, uint256 observedLow) = schoolbook(quotient, divisor);
        if (remainder > type(uint256).max - observedLow) ++observedHigh;
        unchecked {
            observedLow += remainder;
        }
        assertEq(observedHigh, high);
        assertEq(observedLow, low);
    }

    /// EC-07 / INV-03. The uncapped nominal recovery can exceed uint256.
    function testLiquidationWithWideRecoveryQuote() public {
        uint256 max = type(uint256).max;
        uint256 price = max / 20 * 11;
        uint256 id = loans.open(address(1), max, 2 ether, max, 800, 100);
        Loans.Settlement memory settlement = loans.liquidate(address(2), id, price);
        assertEq(settlement.debt, max);
        assertEq(settlement.repaid, max);
        assertEq(settlement.seized, 1_909_090_909_090_909_091);
        assertEq(settlement.returnedCollateral, 2 ether - settlement.seized);
        assertEq(settlement.badDebt, 0);
    }

    /// EC-07 / INV-03. Seizing all collateral remains representable when the uncapped award is wider.
    function testLiquidationWithWideCollateralAward() public {
        uint256 max = type(uint256).max;
        uint256 id = loans.open(address(1), max, max, 2 ether, 800, 100);
        Loans.Settlement memory settlement = loans.liquidate(address(2), id, 1);
        assertEq(settlement.repaid, max / 1.05e18 + 1);
        assertEq(settlement.seized, max);
        assertEq(settlement.returnedCollateral, 0);
        assertEq(settlement.badDebt, max - settlement.repaid);
    }

    /// EC-06 / INV-01 / CL-05. Exact carry and simple interest despite a wide elapsed product.
    function testInterestOnLargePrincipal() public {
        uint256 principal = type(uint256).max / 4;
        uint256 id = loans.open(address(1), principal, type(uint256).max, 1 ether, 800, 100);
        vm.warp(vm.getBlockTimestamp() + 365 days);
        (uint256 interest, uint256 carry) = loans.projected(id);
        uint256 expectedInterest = principal / 25 * 2 + (principal % 25) * 2 / 25;
        assertEq(interest, expectedInterest);
        assertEq(carry, (principal % 25 * 2 % 25) * (10_000 * 365 days / 25));
        assertEq(loans.totalDebt(), principal + expectedInterest);
    }

    /// EC-06 / INV-01 / CL-05, CL-19. After a partial payment, the fractional carry is
    /// preserved but the second interval accrues on the reduced principal.
    function testFuzzPiecewiseSimpleInterest(uint64 rawPrincipal, uint32 firstInterval, uint32 secondInterval) public {
        uint256 principal = uint256(rawPrincipal) + 2;
        uint256 annualRate = 800;
        uint256 denominator = 10_000 * 365 days;
        uint256 start = vm.getBlockTimestamp();
        uint256 id = loans.open(address(1), principal, 1 ether, 2 * principal, annualRate, 100);
        vm.warp(start + firstInterval);
        uint256 firstNumerator = principal * annualRate * firstInterval;
        uint256 principalPaid = principal / 2;
        loans.repay(address(1), id, firstNumerator / denominator + principalPaid, false);
        vm.warp(start + firstInterval + secondInterval);
        uint256 nextNumerator = firstNumerator % denominator + (principal - principalPaid) * annualRate * secondInterval;
        (uint256 interest, uint256 carry) = loans.projected(id);
        assertEq(interest, nextNumerator / denominator);
        assertEq(carry, nextNumerator % denominator);
        assertEq(loans.totalDebt(), principal - principalPaid + interest);
    }

    /// EC-04 / INV-07 + EC-06 / INV-01. Each floor is taken before summing the receivables.
    function testIndependentRemaindersAndRemovingAnActivePosition() public {
        uint256 first = loans.open(address(1), 10, 1 ether, 100, 800, 100);
        uint256 second = loans.open(address(2), 10, 1 ether, 100, 800, 100);
        uint256 third = loans.open(address(3), 10, 1 ether, 100, 800, 100);
        vm.warp(vm.getBlockTimestamp() + 365 days);
        assertEq(loans.totalDebt(), 30);
        loans.repay(address(2), second, 0, true);
        assertEq(loans.activeIds[1], third);
        assertEq(loans.totalDebt(), 20);
        vm.warp(vm.getBlockTimestamp() + 365 days);
        assertEq(loans.totalDebt(), 22);
        loans.repay(address(1), first, 11, false);
        assertEq(loans.activeIds[0], third);
        assertEq(loans.totalDebt(), 11);
        assertEq(loans.totalCollateral, 1 ether);
    }

    /// EC-04 / INV-02 / CL-17. Both the share mint and redemption require wide multiplication.
    function testWidePoolMintAndRedemption() public {
        uint256 half = type(uint256).max / 2;
        assertEq(pool.supply(address(1), half, 0), half);
        assertEq(pool.supply(address(2), half, half), half);
        assertEq(pool.redeem(address(2), half, half * 2), half);
        assertEq(pool.cash, half);
        assertEq(pool.shares[address(1)], half);
    }
}
