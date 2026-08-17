# Module-Level Coverage Status

## Purpose

This document records standalone RTL module coverage for blocks used in
the CPU execution datapath and FPU.

Standalone unit tests are used to cover module-level functionality that
is not exercised through the current CPU execution subset.

## Results

| Module           | Branches | Covered | Coverage |
| ---------------- | -------: | ------: | -------: |
| `alu.sv`         |       11 |      11 |  100.00% |
| `register_file.sv`|       12 |      12 |  100.00% |
| `mmu.sv`          |        4 |       4 |  100.00% |

## Notes

- `alu.sv` standalone coverage includes XOR, SLL, SRA, SLT, ADD, SUB, AND, OR, and default unsupported opcode.
- `register_file.sv` standalone coverage includes integer and FP read/write paths, including `is_fp=1`.
- `mmu.sv` coverage was already closed through the CPU execution integration tests.

## Relation to CPU Execution Coverage

These module-level results are complementary to:

- `docs/cpu_exec_coverage_status.md`
- `docs/fpu_branch_waivers.md`

The CPU execution path remains scoped to the currently supported RV32I subset:

- R-type: ADD, SUB, AND, OR, SLT
- I-type: LW
- S-type: SW

No RTL modifications were made to close these coverage holes.
