"""Independent reference model for the project FPU.

The model is intentionally independent from the RTL implementation.

Arithmetic is performed exactly using Fraction. The exact mathematical
result is converted to IEEE-754 binary32 only at the architectural
boundary using round-to-nearest-even (RNE).

The model does not reproduce RTL implementation details such as:
- exponent alignment
- mantissa shifting
- normalization loops
- quotient generation
- truncation
"""

from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction

from .binary32 import (
    binary32_from_fraction,
    classify,
    decode,
    exact_fraction,
)


ADD = 0b000
SUB = 0b001
MUL = 0b010
DIV = 0b011

SUPPORTED = "SUPPORTED"
PARTIAL = "PARTIAL"
UNSUPPORTED = "UNSUPPORTED"


@dataclass(frozen=True)
class ReferenceResult:
    status: str
    result: int | None
    classification: str
    reason: str = ""


SUPPORTED_CLASSES = {
    "ZERO",
    "NEG_ZERO",
    "NORMAL",
    "NEG_NORMAL",
    "SUBNORMAL",
    "NEG_SUBNORMAL",
}


def _operation_name(op: int) -> str:
    return {
        ADD: "ADD",
        SUB: "SUB",
        MUL: "MUL",
        DIV: "DIV",
    }.get(op, "UNKNOWN")


def _unsupported(reason: str) -> ReferenceResult:
    return ReferenceResult(
        status=UNSUPPORTED,
        result=None,
        classification="UNSUPPORTED",
        reason=reason,
    )


def _supported(result: int) -> ReferenceResult:
    result &= 0xFFFFFFFF

    return ReferenceResult(
        status=SUPPORTED,
        result=result,
        classification=classify(result),
    )


def _classify_operand(bits: int) -> str:
    return classify(bits)


def _is_nan(bits: int) -> bool:
    return decode(bits).is_nan


def _is_infinity(bits: int) -> bool:
    return decode(bits).is_infinity


def _is_nan_or_infinity(bits: int) -> bool:
    value = decode(bits)
    return value.is_nan or value.is_infinity


def _finite_fraction(bits: int) -> Fraction:
    """Return exact finite mathematical value."""

    return exact_fraction(bits)


def reference_model(
    a: int,
    b: int,
    op: int,
) -> ReferenceResult:
    """Calculate the expected architectural FPU result.

    Supported arithmetic:

        ADD
        SUB
        MUL
        DIV

    Finite arithmetic is performed exactly using Fraction and then
    converted to binary32 using IEEE-754 round-to-nearest-even.

    Architectural special-case policy:

        NaN operand       -> UNSUPPORTED
        infinity operand  -> UNSUPPORTED
        0 / 0             -> UNSUPPORTED
        finite / zero     -> signed infinity

    """

    a &= 0xFFFFFFFF
    b &= 0xFFFFFFFF

    if op not in (ADD, SUB, MUL, DIV):
        return _unsupported(
            f"Unsupported FPU operation: {op:#x}"
        )

    operation = _operation_name(op)

    class_a = _classify_operand(a)
    class_b = _classify_operand(b)

    # ------------------------------------------------------------
    # NaN
    # ------------------------------------------------------------

    if _is_nan(a) or _is_nan(b):
        return _unsupported(
            f"{operation} with NaN operand"
        )

    # ------------------------------------------------------------
    # Infinity
    #
    # Infinity is currently outside the supported architectural
    # contract for arithmetic operands.
    # ------------------------------------------------------------

    if _is_infinity(a) or _is_infinity(b):
        return _unsupported(
            f"{operation} with infinity operand"
        )

    # ------------------------------------------------------------
    # Division by zero
    #
    # Current architectural contract:
    #
    #     finite / +0 -> signed infinity
    #     finite / -0 -> signed infinity
    #
    #     0 / 0 -> unsupported
    # ------------------------------------------------------------

    if op == DIV and b in (0x00000000, 0x80000000):

        if a in (0x00000000, 0x80000000):
            return _unsupported(
                "0/0 is outside the supported contract"
            )

        sign = ((a >> 31) ^ (b >> 31)) & 0x1

        return _supported(
            (sign << 31) | 0x7F800000
        )

    # ------------------------------------------------------------
    # Exact finite arithmetic
    # ------------------------------------------------------------

    value_a = _finite_fraction(a)
    value_b = _finite_fraction(b)

    if op == ADD:
        exact_result = value_a + value_b

    elif op == SUB:
        exact_result = value_a - value_b

    elif op == MUL:
        exact_result = value_a * value_b

    elif op == DIV:
        # Defensive check. Division by zero is handled above.
        if value_b == 0:
            return _unsupported(
                "division by zero"
            )

        exact_result = value_a / value_b

    else:
        raise AssertionError("unreachable")

    # ------------------------------------------------------------
    # Architectural binary32 conversion
    #
    # This is where exact Fraction arithmetic becomes a finite
    # binary32 result using IEEE-754 round-to-nearest-even.
    # ------------------------------------------------------------

    result_bits = binary32_from_fraction(exact_result)

    return _supported(result_bits)


def reference_add(a: int, b: int) -> ReferenceResult:
    """Reference ADD operation."""

    return reference_model(a, b, ADD)


def reference_sub(a: int, b: int) -> ReferenceResult:
    """Reference SUB operation."""

    return reference_model(a, b, SUB)


def reference_mul(a: int, b: int) -> ReferenceResult:
    """Reference MUL operation."""

    return reference_model(a, b, MUL)


def reference_div(a: int, b: int) -> ReferenceResult:
    """Reference DIV operation."""

    return reference_model(a, b, DIV)
