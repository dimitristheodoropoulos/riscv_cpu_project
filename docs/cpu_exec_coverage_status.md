# CPU Execution Coverage Status

## Scope

The coverage target is the current `cpu_exec_core` architectural
execution path for the implemented RV32I subset.

Supported instructions:

- R-type: ADD, SUB, AND, OR, XOR, SLL, SRA, SLT
- I-type: LW
- S-type: SW

Explicitly unsupported and out-of-scope:

- SRL
- SLTU
- FP register file access
- branch instructions
- jump instructions
- U-type instructions
- complete instruction fetch/decode/execute pipeline

## Functional Result

The directed CPU execution suite completed with:

```text
Expected transactions : 12
Observed transactions : 12
Matches               : 12
Mismatches            : 0

UVM_ERROR : 0
UVM_FATAL : 0
```

Architectural verification PASSED.

## RTL Branch Coverage

| Module | Branches | Covered | Misses | Coverage |
|---|---:|---:|---:|---:|
| `cu.sv` | 16 | 15 | 1 | 93.75% |
| `register_file.sv` | 12 | 10 | 2 | 83.33% |
| `alu.sv` | 11 | 11 | 0 | 100.00% |
| `mmu.sv` | 5 | 5 | 0 | 100.00% |
| `cpu_exec_core.sv` | 19 | 19 | 0 | 100.00% |

## Scoped Exclusions

### `cu.sv` — 1 missing branch

The uncovered branch is the false path for:

```systemverilog
if (funct7[5])
    ALU_op = 4'b0101;   // SRA
else
    ALU_op = 4'b1111;   // SRL unsupported
```

The false branch corresponds to `SRL`, which is not part of the current
CPU execution subset.

### `register_file.sv` — 2 missing branches

Both missing branches belong to `is_fp == 1` paths:

- FP register read path
- FP register write path

The CPU execution core does not issue floating-point operations, so these
paths are outside the current CPU-exec scope.

## Condition Note

`cpu_exec_core.sv` condition coverage remains below 100% because the
following condition is not hit in its false case:

```systemverilog
if (instruction != 32'h00000000)
```

`instruction == 0` is not a valid architectural instruction in the current
execution model, therefore it is intentionally not exercised.

## Closure Statement

For the currently supported RV32I CPU execution subset:

> All reachable RTL branches within the defined CPU execution scope are
> covered.

The remaining uncovered branches are explicitly documented as scoped
exclusions:

- 1 unsupported instruction decode path
- 2 out-of-scope FP register paths

No RTL bug was detected for the tested and supported CPU-exec scope.
