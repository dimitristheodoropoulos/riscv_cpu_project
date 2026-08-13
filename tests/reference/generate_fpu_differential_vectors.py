"""Generate deterministic FPU differential-verification vectors."""

from pathlib import Path
from reference.fpu_reference_model import (
    ADD,
    SUB,
    MUL,
    DIV,
    SUPPORTED,
    reference_model,
)


OUTPUT = Path("sim/output/fpu_differential_vectors.txt")


def add_vector(vectors, a, b, op):
    result = reference_model(a, b, op)

    if result.status != SUPPORTED:
        return

    vectors.append(
        (
            a & 0xFFFFFFFF,
            b & 0xFFFFFFFF,
            op,
            result.result & 0xFFFFFFFF,
        )
    )


def main() -> None:
    vectors = []

    # ------------------------------------------------------------
    # Basic arithmetic
    # ------------------------------------------------------------

    add_vector(vectors, 0x3F800000, 0x40000000, ADD)  # 1 + 2
    add_vector(vectors, 0x40400000, 0x3F800000, SUB)  # 3 - 1
    add_vector(vectors, 0x40000000, 0x40400000, MUL)  # 2 * 3
    add_vector(vectors, 0x40C00000, 0x40000000, DIV)  # 6 / 2

    # ------------------------------------------------------------
    # RNE-sensitive arithmetic
    # ------------------------------------------------------------

    add_vector(vectors, 0x3F800000, 0x40400000, DIV)  # 1 / 3
    add_vector(vectors, 0x40000000, 0x40400000, DIV)  # 2 / 3

    # ------------------------------------------------------------
    # Sign / cancellation
    # ------------------------------------------------------------

    add_vector(vectors, 0x3F800000, 0xBF800000, ADD)
    add_vector(vectors, 0x3F800000, 0x3F800000, SUB)

    add_vector(vectors, 0xBF800000, 0x3F800000, ADD)
    add_vector(vectors, 0xBF800000, 0xBF800000, SUB)

    # ------------------------------------------------------------
    # Subnormal boundaries
    # ------------------------------------------------------------

    add_vector(vectors, 0x00000001, 0x00000001, ADD)
    add_vector(vectors, 0x007FFFFF, 0x00000001, ADD)
    add_vector(vectors, 0x00800000, 0x00000001, ADD)

    add_vector(vectors, 0x00800000, 0x40000000, DIV)
    add_vector(vectors, 0x00000002, 0x40000000, DIV)

    # ------------------------------------------------------------
    # Signed zero / division by zero
    # ------------------------------------------------------------

    add_vector(vectors, 0x3F800000, 0x00000000, DIV)
    add_vector(vectors, 0x3F800000, 0x80000000, DIV)
    add_vector(vectors, 0xBF800000, 0x00000000, DIV)
    add_vector(vectors, 0xBF800000, 0x80000000, DIV)

    # ------------------------------------------------------------
    # Powers of two
    # ------------------------------------------------------------

    for exponent in range(-20, 21):
        if exponent >= 0:
            a = (127 + exponent) << 23
        else:
            a = (127 + exponent) << 23

        add_vector(vectors, a, 0x3F800000, ADD)
        add_vector(vectors, a, 0x3F800000, SUB)
        add_vector(vectors, a, 0x40000000, MUL)
        add_vector(vectors, a, 0x40000000, DIV)

    # ------------------------------------------------------------
    # Various normal operands
    # ------------------------------------------------------------

    normal_values = [
        0x3F000000,  # 0.5
        0x3F400000,  # 0.75
        0x3F800000,  # 1.0
        0x3FC00000,  # 1.5
        0x40000000,  # 2.0
        0x40400000,  # 3.0
        0x40800000,  # 4.0
        0x40A00000,  # 5.0
        0x40C00000,  # 6.0
        0x41200000,  # 10.0
        0x3EAAAAAB,  # ~1/3
        0x3F2AAAAB,  # ~2/3
        0xC0200000,  # -2.5
        0xBF800000,  # -1.0
        0xC0000000,  # -2.0
    ]

    for a in normal_values:
        for b in normal_values:
            add_vector(vectors, a, b, ADD)
            add_vector(vectors, a, b, SUB)
            add_vector(vectors, a, b, MUL)
            add_vector(vectors, a, b, DIV)

    # ------------------------------------------------------------
    # Deterministic bit-pattern sweep
    # ------------------------------------------------------------

    patterns = [
        0x00000001,
        0x00000002,
        0x00000003,
        0x00000010,
        0x00000100,
        0x00010000,
        0x007FFFFF,
        0x00800000,
        0x00800001,
        0x3E800000,
        0x3F000001,
        0x3F7FFFFF,
        0x3F800001,
        0x3FFFFFFF,
        0x40000001,
        0x407FFFFF,
        0x40800000,
        0x7F000000,
        0x7F7FFFFE,
        0x7F7FFFFF,
        0x80000001,
        0x807FFFFF,
        0x80800000,
        0xBF800001,
        0xBF800000,
        0xC0000000,
        0xFF000000,
        0xFF7FFFFF,
    ]

    for a in patterns:
        for b in patterns:
            add_vector(vectors, a, b, ADD)
            add_vector(vectors, a, b, SUB)
            add_vector(vectors, a, b, MUL)
            add_vector(vectors, a, b, DIV)

    # Remove duplicate vectors while preserving order.
    vectors = list(dict.fromkeys(vectors))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    with OUTPUT.open("w", encoding="ascii") as fd:
        fd.write("# FPU differential vectors\n")
        fd.write("# a b op expected\n")

        for a, b, op, expected in vectors:
            fd.write(
                f"{a:08X} {b:08X} {op:X} {expected:08X}\n"
            )

    print(f"Generated {len(vectors)} vectors")
    print(f"Output: {OUTPUT}")


if __name__ == "__main__":
    main()
