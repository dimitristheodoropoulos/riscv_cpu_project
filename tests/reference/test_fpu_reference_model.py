"""Standalone tests for the independent FPU reference model."""

from reference.fpu_reference_model import (
    ADD,
    SUB,
    MUL,
    DIV,
    SUPPORTED,
    UNSUPPORTED,
    reference_model,
)


def check(
    name: str,
    a: int,
    b: int,
    op: int,
    expected: int,
) -> None:
    result = reference_model(a, b, op)

    assert result.status == SUPPORTED, (
        f"{name}: expected SUPPORTED, "
        f"got {result.status}: {result.reason}"
    )

    assert result.result == expected, (
        f"{name}: expected 0x{expected:08X}, "
        f"got 0x{result.result:08X}"
    )

    print(
        f"PASS  {name:<35} "
        f"0x{result.result:08X}"
    )


def check_unsupported(
    name: str,
    a: int,
    b: int,
    op: int,
) -> None:
    result = reference_model(a, b, op)

    assert result.status == UNSUPPORTED, (
        f"{name}: expected UNSUPPORTED, "
        f"got {result.status}"
    )

    print(
        f"PASS  {name:<35} "
        f"UNSUPPORTED"
    )


def main() -> None:

    # Basic arithmetic

    check(
        "ADD 1.0 + 2.0",
        0x3F800000,
        0x40000000,
        ADD,
        0x40400000,
    )

    check(
        "SUB 3.0 - 1.0",
        0x40400000,
        0x3F800000,
        SUB,
        0x40000000,
    )

    check(
        "MUL 2.0 * 3.0",
        0x40000000,
        0x40400000,
        MUL,
        0x40C00000,
    )

    check(
        "DIV 6.0 / 2.0",
        0x40C00000,
        0x40000000,
        DIV,
        0x40400000,
    )

    # Inexact arithmetic requiring RNE

    check(
        "DIV 1.0 / 3.0 RNE",
        0x3F800000,
        0x40400000,
        DIV,
        0x3EAAAAAB,
    )

    check(
        "DIV 2.0 / 3.0 RNE",
        0x40000000,
        0x40400000,
        DIV,
        0x3F2AAAAB,
    )

    # Cancellation

    check(
        "ADD 1.0 + (-1.0)",
        0x3F800000,
        0xBF800000,
        ADD,
        0x00000000,
    )

    check(
        "SUB 1.0 - 1.0",
        0x3F800000,
        0x3F800000,
        SUB,
        0x00000000,
    )

    # Signed-zero division

    check(
        "1.0 / +0",
        0x3F800000,
        0x00000000,
        DIV,
        0x7F800000,
    )

    check(
        "1.0 / -0",
        0x3F800000,
        0x80000000,
        DIV,
        0xFF800000,
    )

    check(
        "-1.0 / +0",
        0xBF800000,
        0x00000000,
        DIV,
        0xFF800000,
    )

    check(
        "-1.0 / -0",
        0xBF800000,
        0x80000000,
        DIV,
        0x7F800000,
    )

    # Subnormal arithmetic

    check(
        "minimum subnormal + minimum subnormal",
        0x00000001,
        0x00000001,
        ADD,
        0x00000002,
    )

    check(
        "minimum normal / 2.0",
        0x00800000,
        0x40000000,
        DIV,
        0x00400000,
    )

    # Unsupported special cases

    check_unsupported(
        "0.0 / 0.0",
        0x00000000,
        0x00000000,
        DIV,
    )

    check_unsupported(
        "NaN + 1.0",
        0x7FC00000,
        0x3F800000,
        ADD,
    )

    check_unsupported(
        "1.0 + infinity",
        0x3F800000,
        0x7F800000,
        ADD,
    )

    check_unsupported(
        "infinity * 2.0",
        0x7F800000,
        0x40000000,
        MUL,
    )

    # Invalid opcode

    result = reference_model(
        0x3F800000,
        0x3F800000,
        0b111,
    )

    assert result.status == UNSUPPORTED

    print(
        f"PASS  {'invalid opcode':<35} "
        f"UNSUPPORTED"
    )

    print()
    print("========================================")
    print("ALL FPU REFERENCE TESTS PASSED")
    print("========================================")


if __name__ == "__main__":
    main()