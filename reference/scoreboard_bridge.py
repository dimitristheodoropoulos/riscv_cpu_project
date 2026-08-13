#!/usr/bin/env python3

import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from reference.fpu_reference_model import reference_model, SUPPORTED


def main():
    if len(sys.argv) != 3:
        print("Usage: scoreboard_bridge.py <input_file> <output_file>")
        sys.exit(1)

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])

    with input_path.open("r", encoding="ascii") as fin, \
         output_path.open("w", encoding="ascii") as fout:

        for line in fin:
            line = line.strip()

            if not line or line.startswith("#"):
                continue

            parts = line.split()

            if len(parts) != 3:
                continue

            a = int(parts[0], 16)
            b = int(parts[1], 16)
            op = int(parts[2], 16)

            result = reference_model(a, b, op)

            if result.status == SUPPORTED:
                fout.write(f"{result.result:08X}\n")
            else:
                fout.write("UNSUPPORTED\n")


if __name__ == "__main__":
    main()
