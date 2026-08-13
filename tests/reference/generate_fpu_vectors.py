from pathlib import Path
import random

from reference.fpu_reference_model import (
    ADD,
    SUB,
    MUL,
    DIV,
    SUPPORTED,
    reference_model,
)

OUTPUT = Path("sim/output/fpu_differential_vectors.txt")

SEED = 0xF02026
TARGET_PER_OP = 250


def add_case(cases, a, b, op):
    result = reference_model(a, b, op)

    if result.status == SUPPORTED:
        cases.append((a & 0xFFFFFFFF, b & 0xFFFFFFFF, op, result.result))


def main():
    rng = random.Random(SEED)

    cases = {
        ADD: [],
        SUB: [],
        MUL: [],
        DIV: [],
    }

    # ------------------------------------------------------------
    # Deterministic architectural corner cases.
    # ------------------------------------------------------------

    fixed = [
        # zeros
        (0x00000000, 0x00000000),
        (0x00000000, 0x3F800000),
        (0x3F800000, 0x00000000),
        (0x80000000, 0x3F800000),
        (0x3F800000, 0x80000000),

        # simple normals
        (0x3F800000, 0x3F800000),  # 1 + 1
        (0x40000000, 0x40400000),  # 2 + 3
        (0x40A00000, 0x40400000),  # 5 - 3
        (0x40000000, 0x40400000),  # 2 * 3
        (0x40C00000, 0x40000000),  # 6 / 2

        # signs
        (0xBF800000, 0x3F800000),
        (0x3F800000, 0xBF800000),
        (0xC0000000, 0x40000000),
        (0xC0000000, 0xC0000000),

        # subnormals
        (0x00000001, 0x00000001),
        (0x00000002, 0x00000001),
        (0x007FFFFF, 0x00000001),
        (0x00800000, 0x00000001),
        (0x00800000, 0x00800000),
    ]

    for a, b in fixed:
        for op in (ADD, SUB, MUL, DIV):
            add_case(cases[op], a, b, op)

    # ------------------------------------------------------------
    # Generate additional random supported cases.
    #
    # We deliberately use structured binary32 values rather than
    # arbitrary floats. Powers of two and small exact significands
    # produce many exactly representable results.
    # ------------------------------------------------------------

    def make_normal():
        sign = rng.randrange(2)
        exponent = rng.randrange(100, 151)
        fraction = rng.choice([
            0,
            1,
            2,
            3,
            0x400000,
            0x200000,
            0x100000,
            0x7FFFFF,
        ])

        return (
            (sign << 31)
            | (exponent << 23)
            | fraction
        )

    def make_subnormal():
        sign = rng.randrange(2)
        fraction = rng.randrange(1, 0x800000)
        return (sign << 31) | fraction

    while any(len(cases[op]) < TARGET_PER_OP for op in cases):

        a = make_normal()
        b = make_normal()

        # Occasionally exercise subnormal operands.
        if rng.random() < 0.10:
            a = make_subnormal()

        if rng.random() < 0.10:
            b = make_subnormal()

        for op in (ADD, SUB, MUL, DIV):
            if len(cases[op]) >= TARGET_PER_OP:
                continue

            add_case(cases[op], a, b, op)

    # ------------------------------------------------------------
    # Remove duplicates while preserving deterministic order.
    # ------------------------------------------------------------

    all_cases = []

    seen = set()

    for op in (ADD, SUB, MUL, DIV):
        for case in cases[op]:
            if case not in seen:
                seen.add(case)
                all_cases.append(case)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    with OUTPUT.open("w", encoding="ascii") as f:
        f.write("# a b op expected\n")

        for a, b, op, expected in all_cases:
            f.write(
                f"{a:08x} {b:08x} {op:01x} {expected:08x}\n"
            )

    print(f"Generated {len(all_cases)} differential vectors")
    print(f"ADD: {sum(1 for x in all_cases if x[2] == ADD)}")
    print(f"SUB: {sum(1 for x in all_cases if x[2] == SUB)}")
    print(f"MUL: {sum(1 for x in all_cases if x[2] == MUL)}")
    print(f"DIV: {sum(1 for x in all_cases if x[2] == DIV)}")
    print(f"Output: {OUTPUT}")


if __name__ == "__main__":
    main()
