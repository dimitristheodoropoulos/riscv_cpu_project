"""Standalone tests for the exact binary32 RNE encoder."""

from fractions import Fraction

from reference.binary32 import (
    binary32_from_fraction,
    classify,
    exact_fraction,
)


def check(name: str, value: Fraction, expected: int) -> None:
    actual = binary32_from_fraction(value)

    assert actual == expected, (
        f"{name}: expected 0x{expected:08X}, "
        f"got 0x{actual:08X}"
    )

    print(f"PASS  {name:<38} 0x{actual:08X}")


def main() -> None:

    # Exact normal values
    check("1.0", Fraction(1), 0x3F800000)
    check("-1.0", Fraction(-1), 0xBF800000)
    check("2.0", Fraction(2), 0x40000000)
    check("0.5", Fraction(1, 2), 0x3F000000)
    check("1.5", Fraction(3, 2), 0x3FC00000)
    check("-2.5", Fraction(-5, 2), 0xC0200000)

    # Inexact normal values
    check("1/3 RNE", Fraction(1, 3), 0x3EAAAAAB)
    check("2/3 RNE", Fraction(2, 3), 0x3F2AAAAB)

    # Minimum subnormal
    min_subnormal = Fraction(1, 1 << 149)

    check(
        "minimum positive subnormal",
        min_subnormal,
        0x00000001,
    )

    check(
        "minimum negative subnormal",
        -min_subnormal,
        0x80000001,
    )

    # Largest subnormal
    largest_subnormal = Fraction(
        0x7FFFFF,
        1 << 149,
    )

    check(
        "largest positive subnormal",
        largest_subnormal,
        0x007FFFFF,
    )

    # Minimum normal
    min_normal = Fraction(1, 1 << 126)

    check(
        "minimum positive normal",
        min_normal,
        0x00800000,
    )

    check(
        "minimum negative normal",
        -min_normal,
        0x80800000,
    )

    # Subnormal -> normal rounding boundary
    halfway_to_min_normal = Fraction(
        0x7FFFFF * 2 + 1,
        2 * (1 << 149),
    )

    check(
        "subnormal/normal halfway RNE",
        halfway_to_min_normal,
        0x00800000,
    )

    # RNE halfway: even lower candidate
    halfway_down = Fraction(1) + Fraction(1, 1 << 24)

    check(
        "halfway -> even, round down",
        halfway_down,
        0x3F800000,
    )

    # RNE halfway: even upper candidate
    halfway_up = Fraction(1) + Fraction(3, 1 << 24)

    check(
        "halfway -> even, round up",
        halfway_up,
        0x3F800002,
    )

    # Maximum finite
    max_finite = exact_fraction(0x7F7FFFFF)

    check(
        "maximum finite exact",
        max_finite,
        0x7F7FFFFF,
    )

    # Overflow
    overflow_value = max_finite * 2

    overflow_bits = binary32_from_fraction(overflow_value)

    assert overflow_bits == 0x7F800000
    print(
        f"PASS  {'positive overflow':<38} "
        f"0x{overflow_bits:08X}"
    )

    negative_overflow = binary32_from_fraction(-overflow_value)

    assert negative_overflow == 0xFF800000
    print(
        f"PASS  {'negative overflow':<38} "
        f"0x{negative_overflow:08X}"
    )

    # Underflow to zero
    half_min_subnormal = Fraction(1, 1 << 150)

    check(
        "half minimum subnormal -> zero",
        half_min_subnormal,
        0x00000000,
    )

    check(
        "negative half minimum subnormal -> -zero",
        -half_min_subnormal,
        0x80000000,
    )

    # Classification sanity
    assert classify(0x00000000) == "ZERO"
    assert classify(0x80000000) == "NEG_ZERO"
    assert classify(0x00000001) == "SUBNORMAL"
    assert classify(0x80000001) == "NEG_SUBNORMAL"
    assert classify(0x00800000) == "NORMAL"
    assert classify(0x80800000) == "NEG_NORMAL"
    assert classify(0x7F800000) == "POS_INFINITY"
    assert classify(0xFF800000) == "NEG_INFINITY"
    assert classify(0x7FC00000) == "NAN"

    print("PASS  classification sanity")

    # Exact binary32 round-trip
    exact_values = [
        0x00000001,
        0x007FFFFF,
        0x00800000,
        0x3F800000,
        0x40000000,
        0x7F7FFFFF,
        0x80000001,
        0x80800000,
        0xBF800000,
    ]

    for bits in exact_values:
        value = exact_fraction(bits)
        round_trip = binary32_from_fraction(value)

        assert round_trip == bits, (
            f"round-trip failed for 0x{bits:08X}: "
            f"got 0x{round_trip:08X}"
        )

    print("PASS  exact binary32 round-trip")

    print()
    print("========================================")
    print("ALL BINARY32 RNE TESTS PASSED")
    print("========================================")


if __name__ == "__main__":
    main()
