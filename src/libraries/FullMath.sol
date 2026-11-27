// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @dev Unsigned products are represented by their high and low 256-bit limbs.
library FullMath {
    error DivisionByZero();
    error QuotientOverflow();

    function product(uint256 a, uint256 b) private pure returns (uint256 high, uint256 low) {
        assembly ("memory-safe") {
            low := mul(a, b)
            let residue := mulmod(a, b, not(0))
            high := sub(sub(residue, low), lt(residue, low))
        }
    }

    /// @notice floor(a * b / denominator), including when a * b exceeds 256 bits.
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        if (denominator == 0) revert DivisionByZero();
        (uint256 high, uint256 low) = product(a, b);
        if (high == 0) return low / denominator;
        if (high >= denominator) revert QuotientOverflow();

        unchecked {
            // Subtract the remainder, making the 512-bit dividend divisible.
            uint256 remainder = mulmod(a, b, denominator);
            if (remainder > low) --high;
            low -= remainder;

            // Divide out powers of two, shifting bits from the high limb to the low limb.
            uint256 twos = denominator & (0 - denominator);
            uint256 odd = denominator / twos;
            uint256 shifted = low / twos | high * ((0 - twos) / twos + 1);

            // Newton iteration doubles the correct bits of the inverse of the odd divisor.
            // Four initial bits, followed by six doublings, give an inverse modulo 2^256.
            uint256 inverse = (3 * odd) ^ 2;
            for (uint256 i; i < 6; ++i) {
                inverse *= 2 - odd * inverse;
            }
            return shifted * inverse;
        }
    }

    function mulDivUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) != 0) ++result;
    }

    /// @notice Compare a*b*scale < c*d without truncating the ratio or either product.
    function scaledProductLessThan(uint256 a, uint256 b, uint256 scale, uint256 c, uint256 d)
        internal
        pure
        returns (bool)
    {
        (uint256 rightHigh, uint256 rightLow) = product(c, d);
        if (scale == 0) return rightHigh != 0 || rightLow != 0;
        (uint256 leftHigh, uint256 leftLow) = product(a, b);
        if (leftHigh > rightHigh / scale) return false;

        (uint256 carry, uint256 scaledLow) = product(leftLow, scale);
        uint256 scaledHigh = leftHigh * scale;
        if (carry > rightHigh - scaledHigh) return false;
        scaledHigh += carry;
        return scaledHigh < rightHigh || (scaledHigh == rightHigh && scaledLow < rightLow);
    }
}
