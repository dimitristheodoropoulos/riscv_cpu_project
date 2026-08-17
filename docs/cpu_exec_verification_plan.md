# CPU Execution Core Verification Plan

## 1. Objective

This document defines the RTL verification strategy for the RISC-V CPU
execution core (`cpu_exec`).

The objective is to verify the functional correctness of the supported
RV32I execution functionality and to provide measurable evidence of RTL
verification closure.

The verification environment is implemented in SystemVerilog and UVM,
with additional reference-model-based checking, architectural checking,
and RTL code coverage analysis.

The plan describes only verification capabilities that are implemented and
used in the current project.

---

## 2. DUT Scope

The verification scope is the CPU execution RTL hierarchy:

    /tb_top_cpu_exec/dut_wrapper/dut

The DUT consists of:

| RTL Instance | Design Unit | Function |
|---|---|---|
| `dut` | `cpu_exec_core` | CPU execution core |
| `dut/u_cu` | `cu` | Instruction decode and control |
| `dut/u_rf` | `register_file` | Integer register file |
| `dut/u_alu` | `alu` | Arithmetic and logic operations |
| `dut/u_mmu` | `mmu` | Data memory / memory access |

---

## 3. Instruction Scope

The current CPU execution core implements the following RV32I
instruction subset:

| Instruction | Type | Verification Status |
|---|---|---|
| ADD | R-type | Verified |
| SUB | R-type | Verified |
| AND | R-type | Verified |
| OR | R-type | Verified |
| SLT | R-type | Verified |
| LW | I-type | Verified |
| SW | S-type | Verified |

The following functionality is outside the current CPU execution-core
scope:

- Branch instructions
- Jump instructions
- U-type instructions
- FPU instructions
- Caches
- Other unsupported RV32I instructions

Unsupported functionality is not interpreted as missing verification
coverage for the current DUT scope.

---

## 4. Verification Methodology

The verification environment uses a layered SystemVerilog/UVM methodology.

The implemented verification flow includes:

- UVM testbench infrastructure
- UVM sequence generation
- UVM driver
- UVM monitor
- Scoreboard-based checking
- Reference-model-based expected results
- Directed stimulus
- Architectural invariant checking
- RTL code coverage
- Regression/simulation execution

The verification environment is designed to compare DUT behavior against
expected architectural results rather than relying only on simulation
completion.

---

## 5. UVM Environment

The CPU execution verification environment contains the following
functional components:

| Component | Purpose |
|---|---|
| Sequence | Generates CPU execution transactions |
| Driver | Applies transactions to the DUT |
| Monitor | Observes DUT outputs and architectural state |
| Scoreboard | Compares observed and expected behavior |
| Reference model | Produces expected CPU behavior |
| Interface | Connects the UVM environment to the DUT |

The monitor observes:

- Program counter
- Integer register state
- Data memory state
- Execution results

The verification environment also checks the RISC-V `x0` architectural
invariant.

---

## 6. Stimulus Strategy

### 6.1 Directed Testing

Directed tests are used to explicitly exercise individual supported
instructions and important architectural states.

Examples include:

- Register initialization
- R-type arithmetic and logical operations
- Load operations
- Store operations
- Register and memory state verification

Directed stimulus is also used when a specific RTL behavior needs to be
targeted for coverage closure.

---

### 6.2 Targeted Coverage-Closure Stimulus

Targeted stimulus is used to exercise specific RTL behaviors identified
during coverage analysis.

When uncovered branches or architectural cases are identified, dedicated
transactions are added to the CPU execution sequence and the coverage
database is regenerated.

The current CPU execution verification flow uses primarily directed and
coverage-driven stimulus.

Constrained-random methodology is planned for future extension of the
verification environment.

---

## 7. Reference Model

A CPU reference model is used to calculate expected architectural
behavior for supported instructions.

The reference model provides expected values for:

- Integer registers
- Program counter
- Data memory
- Instruction execution results

The DUT observations are compared against these expected values by the
verification scoreboard.

This provides differential checking between the RTL implementation and
the expected CPU behavior.

---

## 8. Scoreboard Checking

The scoreboard compares DUT-observed state against reference-model
expectations.

The comparison includes, where applicable:

- Integer register values
- Program counter
- Data memory contents
- Execution results

A mismatch between expected and observed architectural state is reported
as a verification failure.

The scoreboard therefore provides functional correctness checking
independently of RTL code coverage.

---

## 9. Reset and Register Initialization

Reset behavior is explicitly handled by the verification environment.

The implemented execution sequence is:

1. Assert reset.
2. Program instruction memory.
3. Release reset.
4. Initialize integer registers.
5. Execute the program.
6. Observe and compare architectural state.

Register initialization is performed after reset release because the
register-file RTL resets registers while reset is asserted.

This sequencing ensures that intended initial register values are not
overwritten by reset logic.

---

## 10. Architectural Checks

The CPU execution environment includes architectural checking in the
monitor and verification sequences.

A primary invariant is the RISC-V `x0` rule:

> Register `x0` must remain zero.

The monitor explicitly checks the observed integer register state and
reports an error if `x0` becomes non-zero.

Additional x0 behavior is exercised through dedicated directed stimulus,
including an attempted write to `x0`.

The CPU execution environment does not currently claim dedicated SVA
properties. SVA-based verification is implemented elsewhere in the
project, including the FPU verification environment.

The current CPU verification strategy relies on architectural checking,
scoreboard comparison, and RTL coverage analysis.

---

## 11. RTL Code Coverage

RTL code coverage is collected using Questa coverage analysis.

The primary closure metrics are:

- Branch coverage
- Condition coverage
- Statement coverage

Coverage is restricted to the CPU execution RTL hierarchy and is kept
separate from UVM/testbench coverage.

The current RTL coverage result is:

| Metric | Result |
|---|---:|
| RTL Branch Coverage | **63/63 = 100%** |
| RTL Condition Coverage | **100% of reported bins** |
| RTL Statement Coverage | **100% of reported RTL instances** |

Branch coverage by RTL instance:

| RTL Instance | Branches | Covered | Coverage |
|---|---:|---:|---:|
| `cpu_exec_core` | 19 | 19 | 100% |
| `cu` | 16 | 16 | 100% |
| `register_file` | 12 | 12 | 100% |
| `alu` | 11 | 11 | 100% |
| `mmu` | 5 | 5 | 100% |
| **Total** | **63** | **63** | **100%** |

---

## 12. Toggle Coverage

Toggle coverage is collected and reported separately from functional/code
coverage.

The current toggle results are:

| RTL Instance | Toggle Coverage |
|---|---:|
| `cpu_exec_core` | 67.52% |
| `cu` | 26.38% |
| `register_file` | 66.66% |
| `alu` | 94.28% |
| `mmu` | 73.97% |

Toggle coverage is not used to claim 100% overall RTL coverage.

It is maintained as a separate coverage metric and may be improved with
additional stimulus if toggle closure becomes a project requirement.

---

## 13. Coverage Closure Strategy

Coverage closure is performed by:

1. Running the CPU verification tests.
2. Collecting RTL coverage.
3. Identifying uncovered RTL branches, conditions, and statements.
4. Determining whether the uncovered behavior is reachable within the
   supported CPU functionality.
5. Adding targeted stimulus where required.
6. Re-running the verification environment.
7. Re-analyzing the resulting coverage database.

The current CPU execution RTL branch coverage has reached:

> **63/63 covered RTL branch bins (100%).**

No RTL branch misses remain in the analyzed CPU execution DUT hierarchy.

---

## 14. Separation of RTL and Testbench Coverage

Coverage from verification infrastructure is not used as evidence of RTL
functional coverage.

The following categories are treated separately:

### RTL DUT

- `cpu_exec_core`
- `cu`
- `register_file`
- `alu`
- `mmu`

### Verification Environment

- UVM packages
- Sequences
- Driver
- Monitor
- Scoreboard
- Reference model
- Testbench interfaces
- Test infrastructure

Lower coverage in verification/testbench code does not imply uncovered
RTL functionality.

The CPU RTL coverage claim is therefore based only on the explicitly
identified DUT hierarchy.

---

## 15. Coverage Evidence

The RTL coverage database is:

    sim/output/cpu_exec.ucdb

The corresponding detailed Questa coverage report is:

    sim/output/cpu_exec_coverage_report.txt

Coverage is generated with:

    vcover report output/cpu_exec.ucdb \
        -codeAll \
        -details \
        -output output/cpu_exec_coverage_report.txt

The detailed report is used as the evidence source for the RTL coverage
numbers documented in this plan.

---

## 16. Verification Status

The current CPU execution verification status is:

| Area | Status |
|---|---|
| SystemVerilog RTL verification | Complete for current scope |
| UVM environment | Implemented |
| Directed testing | Implemented |
| Targeted coverage-closure stimulus | Implemented |
| Constrained-random CPU stimulus | Planned for future extension |
| Reference model | Implemented |
| Scoreboard checking | Implemented |
| Architectural x0 checking | Implemented |
| CPU-specific SVA | Not currently claimed |
| RTL branch coverage | **100% (63/63)** |
| RTL condition coverage | **100% reported bins** |
| RTL statement coverage | **100% reported RTL instances** |
| Toggle coverage | Tracked separately |
| Unsupported CPU functionality | Explicitly out of scope |

---

## 17. Verification Conclusion

The current CPU execution verification environment provides functional
and structural verification evidence for the supported RV32I execution
subset.

The strongest current coverage result is:

> **100% RTL branch coverage with 63/63 branch bins covered.**

All reported RTL condition and statement coverage bins are also covered.

Toggle coverage is reported independently and is not included in the
100% functional/code coverage claim.

The verification conclusion is therefore intentionally scoped:

> **The supported CPU execution RTL has achieved 100% branch coverage
> (63/63), with all reported RTL condition and statement coverage bins
> covered. Toggle coverage remains a separate metric.**

This conclusion applies only to the implemented and verified CPU execution
scope described in this document.