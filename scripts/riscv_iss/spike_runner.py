#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(
        description="Run a bounded RV32I Spike architectural smoke."
    )

    parser.add_argument("--spike", required=True)
    parser.add_argument("--elf", required=True)
    parser.add_argument("--log", required=True)
    parser.add_argument("--instructions", required=True, type=int)
    parser.add_argument("--program-base", required=True, type=lambda x: int(x, 0))
    parser.add_argument("--program-end", required=True, type=lambda x: int(x, 0))
    parser.add_argument("--expected-trace", required=True)

    args = parser.parse_args()

    if args.instructions <= 0:
        print("ERROR: instruction limit must be positive", file=sys.stderr)
        return 1

    if args.program_end <= args.program_base:
        print("ERROR: invalid program address range", file=sys.stderr)
        return 1

    command = [
        args.spike,
        "--isa=rv32i",
        f"--instructions={args.instructions}",
        "--log-commits",
        f"--log={args.log}",
        args.elf,
    ]

    print("=== SPIKE COMMAND ===")
    print(" ".join(command))
    print()

    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    if result.stdout:
        print(result.stdout, end="")

    if result.stderr:
        print(result.stderr, file=sys.stderr, end="")

    if result.returncode != 0:
        print(
            f"ERROR: Spike exited with status {result.returncode}",
            file=sys.stderr,
        )
        return result.returncode

    parser_script = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "spike_commit_parser.py",
    )

    parser_command = [
        sys.executable,
        parser_script,
        "--log",
        args.log,
        "--program-base",
        hex(args.program_base),
        "--program-end",
        hex(args.program_end),
        "--expected-trace",
        args.expected_trace,
    ]

    print()
    print("=== ARCHITECTURAL TRACE ===")

    parsed = subprocess.run(parser_command)

    if parsed.returncode != 0:
        return parsed.returncode

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
