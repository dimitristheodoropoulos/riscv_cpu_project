#!/usr/bin/env python3

import argparse
import re
import sys


COMMIT_RE = re.compile(
    r"^core\s+(?P<core>\d+):\s+"
    r"(?:\d+\s+)?"
    r"0x(?P<pc>[0-9a-fA-F]+)\s+"
    r"\(0x(?P<instr>[0-9a-fA-F]+)\)"
    r"(?:.*?\s+x(?P<rd>\d+)\s+0x(?P<value>[0-9a-fA-F]+))?"
)


def load_expected_trace(path):
    expected = []

    with open(path, "r", encoding="utf-8") as stream:
        for line_number, line in enumerate(stream, start=1):
            stripped = line.strip()

            if not stripped:
                continue

            fields = stripped.split()

            if len(fields) != 2:
                raise RuntimeError(
                    f"invalid expected trace at line {line_number}: "
                    f"expected '<pc> <instruction>'"
                )

            try:
                pc = int(fields[0], 0)
                instruction = int(fields[1], 0)
            except ValueError as exc:
                raise RuntimeError(
                    f"invalid expected trace at line {line_number}"
                ) from exc

            expected.append((pc, instruction))

    if not expected:
        raise RuntimeError("expected trace is empty")

    return expected


def parse_log(
    path,
    program_base,
    program_end,
    expected_trace,
):
    regs = [0] * 32
    accepted = []

    expected_index = 0

    with open(path, "r", encoding="utf-8") as stream:
        for line_number, line in enumerate(stream, start=1):
            match = COMMIT_RE.match(line)

            if match is None:
                continue

            core = int(match.group("core"))
            pc = int(match.group("pc"), 16)
            instruction = int(match.group("instr"), 16)

            if core != 0:
                continue

            if not (program_base <= pc < program_end):
                continue

            if pc & 0x3:
                raise RuntimeError(
                    f"unaligned accepted PC at line {line_number}: "
                    f"0x{pc:08x}"
                )

            if expected_index >= len(expected_trace):
                raise RuntimeError(
                    f"unexpected extra architectural commit at line "
                    f"{line_number}: pc=0x{pc:08x}"
                )

            expected_pc, expected_instruction = expected_trace[expected_index]

            if pc != expected_pc:
                raise RuntimeError(
                    f"PC mismatch at architectural commit "
                    f"{expected_index}: "
                    f"expected 0x{expected_pc:08x}, "
                    f"observed 0x{pc:08x}"
                )

            if instruction != expected_instruction:
                raise RuntimeError(
                    f"instruction mismatch at architectural commit "
                    f"{expected_index}: "
                    f"expected 0x{expected_instruction:08x}, "
                    f"observed 0x{instruction:08x}"
                )

            rd_text = match.group("rd")
            value_text = match.group("value")

            if rd_text is not None:
                rd = int(rd_text)

                if not (0 <= rd < 32):
                    raise RuntimeError(
                        f"invalid destination register at line "
                        f"{line_number}: x{rd}"
                    )

                value = int(value_text, 16)
                regs[rd] = value & 0xffffffff

            accepted.append(
                {
                    "pc": pc,
                    "instruction": instruction,
                    "rd": None if rd_text is None else int(rd_text),
                    "value": (
                        None
                        if value_text is None
                        else int(value_text, 16) & 0xffffffff
                    ),
                }
            )

            expected_index += 1

            if expected_index == len(expected_trace):
                break

    regs[0] = 0

    if len(accepted) != len(expected_trace):
        raise RuntimeError(
            f"architectural commit count mismatch: "
            f"expected {len(expected_trace)}, "
            f"observed {len(accepted)}"
        )

    return regs, accepted


def main():
    parser = argparse.ArgumentParser(
        description="Parse a Spike RV32I commit log into architectural state."
    )

    parser.add_argument("--log", required=True)
    parser.add_argument(
        "--program-base",
        required=True,
        type=lambda x: int(x, 0),
    )
    parser.add_argument(
        "--program-end",
        required=True,
        type=lambda x: int(x, 0),
    )
    parser.add_argument("--expected-trace", required=True)

    args = parser.parse_args()

    try:
        expected_trace = load_expected_trace(args.expected_trace)

        regs, accepted = parse_log(
            args.log,
            args.program_base,
            args.program_end,
            expected_trace,
        )

    except (OSError, RuntimeError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    print("SPIKE ARCHITECTURAL TRACE: PASS")
    print(f"accepted_commits={len(accepted)}")

    if accepted:
        print(f"first_pc=0x{accepted[0]['pc']:08x}")
        print(f"last_pc=0x{accepted[-1]['pc']:08x}")

    for index, value in enumerate(regs):
        print(f"x{index}=0x{value:08x}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
