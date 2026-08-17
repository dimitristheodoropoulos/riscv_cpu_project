# CPU Execution Coverage Status

## Scope

The coverage target is the current `cpu_exec_core` architectural
execution path for the implemented RV32I subset:

- R-type: ADD, SUB, AND, OR, SLT
- I-type: LW
- S-type: SW

## RTL Coverage

| Module             | Branches | Covered | Coverage |
| ------------------ | -------: | ------: | -------: |
| `cu.sv`            |       11 |      11 |  100.00% |
| `mmu.sv`           |        4 |       4 |  100.00% |
| `cpu_exec_core.sv` |        8 |       8 |  100.00% |

## Scoped Module-Level Exclusions

### `alu.sv`

The `XOR`, `SLL`, and `SRA` ALU operations are implemented in
`alu.sv`, but the current `cu.sv` does not generate the corresponding
ALU operation codes.

Therefore these branches are not reachable through the current
`cpu_exec_core` instruction subset.

They are **not classified as RTL-unreachable**.

They remain candidates for separate ALU unit-level verification.

### `register_file.sv`

The `is_fp == 1` read/write paths are implemented in the register file,
but `cpu_exec_core` currently has no FPU execution path and therefore
never asserts `is_fp`.

These branches are therefore outside the current CPU-exec architectural
scope.

They are **not classified as RTL-unreachable**.

They remain candidates for separate register-file unit-level verification.

## Closure Statement

The current CPU execution/integration verification scope is CLOSED:

> 100% branch coverage has been achieved for the `cu`, `mmu`, and
> `cpu_exec_core` RTL participating in the currently supported
> instruction subset.

The remaining `alu` and `register_file` branch misses are scoped
module-level coverage items and are not CPU-exec integration failures.