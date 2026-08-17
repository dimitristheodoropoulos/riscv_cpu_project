# Module-Level Coverage Status

## Purpose

This document records standalone RTL module coverage for blocks used in
the CPU execution datapath and FPU.

Standalone unit tests are used to cover module-level functionality that
is not exercised through the current CPU execution subset.

## Results

| Module | Branches | Covered | Coverage |
|---|---:|---:|---:|
| `alu.sv` | 11 | 11 | 100.00% |
| `register_file.sv` | 12 | 12 | 100.00% |
| `mmu.sv` | 5 | 5 | 100.00% |

## Notes

- `alu.sv` standalone coverage includes XOR, SLL, SRA, SLT, ADD, SUB, AND, OR, and default unsupported opcode.
- `register_file.sv` standalone coverage includes integer and FP read/write paths, including `is_fp=1`.
- `mmu.sv` coverage was closed through the CPU execution integration tests.

## Relation to CPU Execution Coverage

These module-level results are complementary to:

- `docs/cpu_exec_verification_plan.md`
- `docs/cpu_exec_verification_summary.md`
- `docs/cpu_exec_coverage_report.md`
- `docs/cpu_exec_formal_verification.md`
- `docs/fpu_branch_waivers.md`

The CPU execution path remains scoped to the currently supported RV32I subset:

- R-type: ADD, SUB, AND, OR, XOR, SLL, SRA, SLT
- I-type: LW
- S-type: SW

Explicitly unsupported and out-of-scope for the current CPU execution scope:

- SRL
- SLTU
- FP arithmetic instruction execution
- branch instructions
- jump instructions
- U-type instructions
- complete instruction fetch/decode/execute pipeline

The standalone module-level tests provide coverage for functionality that is
outside the current CPU execution integration scope.

No RTL modifications were made solely to close these coverage items.