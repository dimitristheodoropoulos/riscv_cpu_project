# CPU Execution Core RTL Coverage Report

## 1. Scope

This report documents the RTL coverage results for the CPU execution core
(`cpu_exec_core`) verification environment.

The scope is limited to the currently supported RV32I execution subset and
does not include full processor-level verification.

The verification target is:

```text
/tb_top_cpu_exec/dut_wrapper/dut
```

The analyzed RTL hierarchy includes:

- `cpu_exec_core`
- `cu`
- `register_file`
- `alu`
- `mmu`

## 2. DUT Hierarchy

| RTL Instance | Design Unit | Function |
|---|---|---|
| `dut` | `cpu_exec_core` | CPU execution core |
| `dut/u_cu` | `cu` | Instruction decode / control |
| `dut/u_rf` | `register_file` | Integer register file |
| `dut/u_alu` | `alu` | Arithmetic / logic unit |
| `dut/u_mmu` | `mmu` | Data memory / load-store path |

## 3. Covered Instructions

The current CPU execution core supports and verifies the following
RV32I instructions:

| Instruction | Type | Status |
|---|---|---|
| ADD | R-type | Verified |
| SUB | R-type | Verified |
| AND | R-type | Verified |
| OR  | R-type | Verified |
| XOR | R-type | Verified |
| SLL | R-type | Verified |
| SRA | R-type | Verified |
| SLT | R-type | Verified |
| LW  | I-type | Verified |
| SW  | S-type | Verified |

The following instruction categories are explicitly **outside** the current
CPU execution coverage scope:

- Branch instructions
- Jump instructions
- I-type ALU immediate instructions
- LUI / AUIPC
- FPU arithmetic instructions
- CSR / system instructions
- Full pipeline / hazard / exception behavior

## 4. RTL Coverage Results

RTL coverage was collected using Questa coverage analysis.

| Metric | Result |
|---|---:|
| Branch Coverage | **63/63 = 100%** |
| Condition Coverage | **100% reported bins** |
| Statement Coverage | **100% reported RTL instances** |

Branch and statement coverage per RTL instance:

| RTL Instance | Branch Coverage | Statement Coverage |
|---|---:|---:|
| `cpu_exec_core` | 100% | 100% |
| `cu` | 100% | 100% |
| `register_file` | 100% | 100% |
| `alu` | 100% | 100% |
| `mmu` | 100% | 100% |

The achieved closure is therefore:

- 100% reachable RTL branch coverage
- 100% RTL statement coverage
- Full coverage of all implemented RV32I execution paths

This result is scoped to the analyzed DUT hierarchy and does **not**
represent complete RV32I processor coverage.

## 5. Toggle Coverage Residual

Toggle coverage is reported separately and is not used as a closure metric
for the current CPU execution scope.

Observed toggle coverage per RTL instance:

| RTL Instance | Toggle Coverage |
|---|---:|
| `cpu_exec_core` | 67.52% |
| `cu` | 26.38% |
| `register_file` | 66.66% |
| `alu` | 94.28% |
| `mmu` | 73.97% |

### 5.1 Explanation of Toggle Gaps

The remaining toggle coverage gaps are expected and are caused by:

- **Unreachable instruction encoding fields**  
  The CPU supports only a limited RV32I subset; therefore many opcode,
  funct3, and funct7 bit combinations are never exercised.

- **No FPU path in the CPU execution core**  
  The `is_fp` and floating-point register-file write/read paths are
  intentionally outside the current CPU execution subset.

- **No branch/jump support**  
  Branch and jump instructions are not implemented, leaving associated
  control and PC-update paths inactive.

- **Unused datapath bits**  
  Some 32-bit datapath signals do not toggle all bit positions under the
  limited instruction set.

These toggle gaps do not indicate missing functional coverage for the
currently supported instructions.

## 6. Coverage Evidence

Coverage database:

```text
sim/output/cpu_exec.ucdb
```

Detailed coverage report:

```text
sim/output/cpu_exec_coverage_report.txt
```

The RTL coverage numbers in this document are taken from the detailed
Questa coverage report generated from the above UCDB.

## 7. Conclusion

The CPU execution core RTL coverage analysis has achieved closure for the
analyzed DUT hierarchy:

- Branch coverage: **63/63 (100%)**
- Condition coverage: **100% reported bins**
- Statement coverage: **100% reported RTL instances**

The remaining toggle coverage gaps are explained by unsupported/unreachable
instruction fields and are documented in Section 5.

This report provides RTL coverage evidence for the supported RV32I
execution subset and intentionally does **not** claim complete RV32I
processor verification.

Full processor integration verification remains a future phase.
