"""Independent IEEE-754 binary32 utilities.

This module provides representation-level helpers and an exact
Fraction -> binary32 round-to-nearest-even encoder.

The arithmetic reference model uses Fraction for exact mathematical
operations and calls binary32_from_fraction() only at the architectural
boundary.
"""

from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction
import struct


SIGN_MASK = 0x80000000
EXP_MASK = 0x7F800000
FRAC_MASK = 0x007FFFFF

EXP_SHIFT = 23
EXP_BIAS = 127

MIN_NORMAL_EXP = 1
MAX_NORMAL_EXP = 254

MIN_NORMAL_E = -126
MAX_NORMAL_E = 127
SUBNORMAL_E = -149

MAX_FINITE = 0x7F7FFFFF
POS_INFINITY = 0x7F800000
NEG_INFINITY = 0xFF800000


@dataclass(frozen=True)
class Binary32:
    """Decoded IEEE-754 binary32 value."""

    bits: int
    sign: int
    exponent: int
    fraction: int

    @property
    def is_zero(self) -> bool:
        return self.exponent == 0 and self.fraction == 0

    @property
    def is_subnormal(self) -> bool:
        return self.exponent == 0 and self.fraction != 0

    @property
    def is_infinity(self) -> bool:
        return self.exponent == 0xFF and self.fraction == 0

    @property
    def is_nan(self) -> bool:
        return self.exponent == 0xFF and self.fraction != 0

    @property
    def is_normal(self) -> bool:
        return 0 < self.exponent < 0xFF


def decode(bits: int) -> Binary32:
    """Decode a 32-bit integer into binary32 fields."""

    bits &= 0xFFFFFFFF

    return Binary32(
        bits=bits,
        sign=(bits >> 31) & 0x1,
        exponent=(bits >> EXP_SHIFT) & 0xFF,
        fraction=bits & FRAC_MASK,
    )


def encode(sign: int, exponent: int, fraction: int) -> int:
    """Encode binary32 fields into a 32-bit integer."""

    if sign not in (0, 1):
        raise ValueError("sign must be 0 or 1")

    if not 0 <= exponent <= 0xFF:
        raise ValueError("exponent must fit in 8 bits")

    if not 0 <= fraction <= FRAC_MASK:
        raise ValueError("fraction must fit in 23 bits")

    return (
        (sign << 31)
        | (exponent << EXP_SHIFT)
        | fraction
    )


def from_float(value: float) -> int:
    """Convert Python float to IEEE-754 binary32 bits.

    Python float is used only as a representation conversion mechanism.
    The FPU arithmetic reference model does not use Python float
    arithmetic.
    """

    return struct.unpack(
        ">I",
        struct.pack(">f", value),
    )[0]


def to_float(bits: int) -> float:
    """Convert binary32 bits to Python float."""

    return struct.unpack(
        ">f",
        struct.pack(">I", bits & 0xFFFFFFFF),
    )[0]


def classify(bits: int) -> str:
    """Return the architectural binary32 classification."""

    value = decode(bits)

    if value.is_zero:
        return "NEG_ZERO" if value.sign else "ZERO"

    if value.is_subnormal:
        return "NEG_SUBNORMAL" if value.sign else "SUBNORMAL"

    if value.is_infinity:
        return "NEG_INFINITY" if value.sign else "POS_INFINITY"

    if value.is_nan:
        return "NAN"

    return "NEG_NORMAL" if value.sign else "NORMAL"


def exact_fraction(bits: int) -> Fraction:
    """Return the exact mathematical value represented by binary32.

    NaN and infinity are intentionally rejected.
    """

    value = decode(bits)

    if value.is_nan or value.is_infinity:
        raise ValueError(
            "NaN/infinity do not have finite Fraction values"
        )

    sign = -1 if value.sign else 1

    if value.exponent == 0:
        # Subnormal:
        #
        # value = fraction * 2^-149
        significand = value.fraction
        exponent = -149
    else:
        # Normal:
        #
        # value = (2^23 + fraction) * 2^(exponent-127-23)
        significand = (1 << 23) | value.fraction
        exponent = value.exponent - EXP_BIAS - 23

    if exponent >= 0:
        magnitude = Fraction(significand << exponent)
    else:
        magnitude = Fraction(
            significand,
            1 << (-exponent),
        )

    return sign * magnitude


def _floor_log2(value: Fraction) -> int:
    """Return floor(log2(value)) for a positive Fraction exactly."""

    if value <= 0:
        raise ValueError("_floor_log2 requires a positive value")

    numerator = value.numerator
    denominator = value.denominator

    exponent = numerator.bit_length() - denominator.bit_length()

    if exponent >= 0:
        power_of_two = Fraction(1 << exponent, 1)
    else:
        power_of_two = Fraction(1, 1 << (-exponent))

    if value < power_of_two:
        exponent -= 1

    return exponent


def _round_to_nearest_even(value: Fraction) -> int:
    """Round a non-negative Fraction to the nearest integer.

    Ties are resolved using IEEE-754 round-to-nearest-even.

    Examples:
        2.4 -> 2
        2.5 -> 2
        3.5 -> 4
        2.6 -> 3
    """

    if value < 0:
        raise ValueError(
            "_round_to_nearest_even requires a non-negative value"
        )

    lower = value.numerator // value.denominator
    remainder = value - lower

    half = Fraction(1, 2)

    if remainder < half:
        return lower

    if remainder > half:
        return lower + 1

    # Exact halfway case: choose the even integer.
    return lower if lower % 2 == 0 else lower + 1


def binary32_from_fraction(value: Fraction) -> int:
    """Convert an exact finite Fraction to binary32 using RNE.

    The conversion is exact with respect to the input Fraction and
    implements IEEE-754 binary32 round-to-nearest-even.

    Handles:
      - zero
      - normal values
      - subnormal values
      - underflow to zero
      - rounding carry into the exponent
      - overflow to infinity
      - signed zero
    """

    if not isinstance(value, Fraction):
        value = Fraction(value)

    if value == 0:
        return 0

    sign = 1 if value < 0 else 0
    magnitude = abs(value)

    exponent = _floor_log2(magnitude)

    # ------------------------------------------------------------
    # Normal result
    #
    # Binary32 normal numbers have:
    #
    #   1.xxxxxxxxxxxxxxxxxxxxxxx * 2^e
    #
    # with 24 significant bits including the hidden leading 1.
    # ------------------------------------------------------------
    if exponent >= MIN_NORMAL_E:

        scale = exponent - 23

        if scale >= 0:
            scaled = magnitude / (1 << scale)
        else:
            scaled = magnitude * (1 << (-scale))

        significand = _round_to_nearest_even(scaled)

        # Rounding can turn:
        #
        #   1.111... -> 10.000...
        #
        # which requires an exponent increment.
        if significand == (1 << 24):
            significand >>= 1
            exponent += 1

        # Overflow after rounding.
        if exponent > MAX_NORMAL_E:
            return (
                (sign << 31)
                | POS_INFINITY
            )

        encoded_exponent = exponent + EXP_BIAS
        fraction = significand & FRAC_MASK

        return encode(
            sign,
            encoded_exponent,
            fraction,
        )

    # ------------------------------------------------------------
    # Subnormal / underflow region
    #
    # Smallest binary32 quantum:
    #
    #   2^-149
    #
    # Therefore:
    #
    #   encoded_fraction = round(value / 2^-149)
    #                     = round(value * 2^149)
    # ------------------------------------------------------------
    scaled_subnormal = magnitude * (1 << 149)

    fraction = _round_to_nearest_even(scaled_subnormal)

    # Rounding a subnormal can produce exactly 2^23, which is the
    # smallest normal binary32 value.
    if fraction >= (1 << 23):
        return encode(
            sign,
            MIN_NORMAL_EXP,
            0,
        )

    # Non-zero value can round all the way to zero.
    if fraction == 0:
        return sign << 31

    return (
        (sign << 31)
        | fraction
    )


def is_exact_binary32(value: Fraction) -> bool:
    """Return whether a finite Fraction is exactly representable.

    This checks representability by encoding with RNE and then
    converting the resulting binary32 value back to an exact Fraction.
    """

    if not isinstance(value, Fraction):
        value = Fraction(value)

    if value == 0:
        return True

    encoded = binary32_from_fraction(value)

    # Overflow to infinity is not an exact finite representation.
    decoded = decode(encoded)

    if decoded.is_infinity:
        return False

    # A non-zero finite value that rounded to zero is not exact.
    if decoded.is_zero:
        return False

    return exact_fraction(encoded) == value
