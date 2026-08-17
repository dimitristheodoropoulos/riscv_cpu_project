# CPU Execution RTL Coverage Summary

## 1. Scope

This report documents the RTL code coverage results for the RISC-V CPU
execution core (`cpu_exec`) using Questa coverage analysis.

The coverage database analyzed is:

    sim/output/cpu_exec.ucdb

The report is based on:

    sim/output/cpu_exec_code_coverage.txt

The coverage scope is restricted to the CPU execution DUT hierarchy:

    /tb_top_cpu_exec/dut_wrapper/dut

and its RTL sub-instances.

The verification environment contains additional UVM/testbench code.
Coverage from those components is reported separately and is not used as
the RTL DUT coverage metric.

---

## 2. RTL Instances

The following RTL instances are included in the CPU execution RTL coverage
scope:

| Instance | Design Unit | Function |
|---|---|---|
| `/tb_top_cpu_exec/dut_wrapper/dut` | `cpu_exec_core` | CPU execution core |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `cu` | Control unit |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `register_file` | Integer register file |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_alu` | `alu` | Arithmetic/logic unit |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `mmu` | Data memory / MMU |

---

## 3. RTL Branch Coverage

| RTL Instance | Branch Bins | Covered | Missed | Coverage |
|---|---:|---:|---:|---:|
| `cpu_exec_core` | 19 | 19 | 0 | **100.00%** |
| `cu` | 16 | 16 | 0 | **100.00%** |
| `register_file` | 12 | 12 | 0 | **100.00%** |
| `alu` | 11 | 11 | 0 | **100.00%** |
| `mmu` | 5 | 5 | 0 | **100.00%** |
| **Total** | **63** | **63** | **0** | **100.00%** |

Therefore:

> **63/63 RTL branch bins are covered, resulting in 100% RTL branch
> coverage for the CPU execution DUT hierarchy.**

No RTL branch misses are present in the analyzed DUT hierarchy.

---

## 4. RTL Condition Coverage

Condition coverage is reported by Questa for the RTL instances where
condition coverage is applicable.

| RTL Instance | Condition Bins | Covered | Missed | Coverage |
|---|---:|---:|---:|---:|
| `cpu_exec_core` | 1 | 1 | 0 | **100.00%** |
| `register_file` | 3 | 3 | 0 | **100.00%** |
| `alu` | 1 | 1 | 0 | **100.00%** |

All reported RTL condition bins are covered.

---

## 5. RTL Statement Coverage

| RTL Instance | Statements | Covered | Missed | Coverage |
|---|---:|---:|---:|---:|
| `cpu_exec_core` | 10 | 10 | 0 | **100.00%** |
| `cu` | 34 | 34 | 0 | **100.00%** |
| `register_file` | 14 | 14 | 0 | **100.00%** |
| `alu` | 14 | 14 | 0 | **100.00%** |
| `mmu` | 9 | 9 | 0 | **100.00%** |

All reported RTL statements in the CPU execution DUT hierarchy are
covered.

---

## 6. RTL Toggle Coverage

Toggle coverage is reported separately from branch, condition, and
statement coverage.

| RTL Instance | Toggle Coverage |
|---|---:|
| `cpu_exec_core` | 67.52% |
| `cu` | 26.38% |
| `register_file` | 66.66% |
| `alu` | 94.28% |
| `mmu` | 73.97% |

The toggle results are not used to claim 100% overall RTL coverage.

The current verification objective is RTL functional/code coverage closure
for branches, conditions, and statements. Toggle coverage remains a
separate metric and may be improved with additional stimulus if required.

---

## 7. Excluded Coverage

The following hierarchy is not considered part of the RTL DUT coverage
metric:

- `cpu_if`
- `dut_wrapper`
- `cpu_pkg`
- `cpu_exec_sequence_pkg`
- `cpu_model_pkg`
- `cpu_scoreboard_pkg`
- `cpu_monitor_pkg`
- `cpu_driver_pkg`
- `cpu_agent_pkg`
- `cpu_env_pkg`
- `cpu_exec_test_pkg`

These components belong to the verification environment, interface, or
testbench infrastructure.

Their lower coverage percentages therefore do not represent uncovered
RTL functionality.

For example, the Questa report shows:

    /cpu_pkg
    Branch Coverage: 6.89%

and:

    /cpu_scoreboard_pkg
    Branch Coverage: 41.81%

These are testbench coverage results and are intentionally excluded from
the RTL DUT coverage metric.

---

## 8. Coverage Interpretation

The Questa UCDB demonstrates:

- 63/63 RTL branch bins covered
- 0 RTL branch misses
- 100% branch coverage for every RTL instance in the DUT hierarchy
- 100% reported RTL condition coverage
- 100% RTL statement coverage for every reported RTL instance
- Toggle coverage reported separately

The aggregate Questa value:

    Total Coverage By Instance (filtered view): 57.75%

is not used as the CPU RTL coverage result because the filtered hierarchy
also contains verification/testbench components.

---

## 9. Final RTL Coverage Status

The CPU execution RTL has achieved:

> **100% RTL branch coverage (63/63 branch bins).**

Additionally, all reported RTL condition and statement coverage bins are
covered.

This report does **not** claim unconditional 100% overall code coverage,
because toggle coverage is below 100% and the complete UCDB contains
testbench/verification code with lower coverage.

The appropriate verification conclusion is therefore:

> **CPU execution RTL branch coverage is closed at 100%, with 63/63 RTL
> branch bins covered. Reported RTL condition and statement coverage are
> also 100%. Toggle coverage is tracked separately.**

---

## 10. Evidence

Coverage was generated with Questa:

    vcover report output/cpu_exec.ucdb \
        -codeAll \
        -details \
        -output output/cpu_exec_code_coverage.txt

The resulting report completed successfully with:

    Errors: 0
    Warnings: 0

The coverage database used for this report is:

    sim/output/cpu_exec.ucdb
