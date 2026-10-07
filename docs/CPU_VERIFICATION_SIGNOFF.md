# CPU Execution Verification Sign-Off

## 1. Scope

This sign-off covers the current RV32I CPU execution block and its directly instantiated RTL design units.

The verified instruction scope is:

- R-type: ADD, SUB, AND, OR, XOR, SLL, SRA, SLT
- I-type memory operation: LW
- S-type memory operation: SW
- B-type conditional branches:
  - BEQ
  - BNE
  - BLT
  - BGE
- Unsupported branch `funct3` handling
- Register x0 architectural behavior
- Reset behavior
- Sequential PC progression
- Taken and not-taken branch PC progression
- Memory read/write control behavior
- Integer and FP register-file initialization paths

The current CPU execution block does not claim implementation or verification of:

- JAL/JALR
- Privileged instructions
- Exceptions/interrupts
- Floating-point execution instructions

This is a block-level CPU execution verification scope, not a claim of full RISC-V processor compliance.

---

## 2. Verification Environment

The CPU execution testbench uses SystemVerilog/UVM components including:

- `cpu_exec_test`
- `cpu_exec_sequence`
- `cpu_exec_random_sequence`
- CPU agent/sequencer/driver/monitor
- CPU reference model
- Scoreboard
- Assertions
- Functional coverage
- Questa coverage collection

The default `cpu_exec` simulation target uses:

- Test: `cpu_exec_test`
- Top: `tb_top_cpu_exec`
- Coverage-enabled Questa simulation
- UCDB output: `sim/output/cpu_exec.ucdb`
- Coverage report: `sim/output/cpu_exec_coverage_report.txt`

---

## 3. Directed Branch Verification

The current directed sequence contains explicit coverage-closure stimulus for the implemented branch operations.

The branch sequence exercises:

- BEQ taken
- BNE taken
- BLT taken
- BGE taken
- BEQ not taken
- BNE not taken
- BLT not taken
- BGE not taken
- Unsupported branch `funct3`
- Negative BGE branch displacement

The sequence also checks the resulting PC progression.

The directed branch task is invoked from `cpu_exec_sequence::body()` through:

`test_branch_execution()`

Therefore the implemented branch RTL is not merely present in the source tree; the branch-directed stimulus is connected to the normal CPU execution test path.

---

## 4. Current RTL Code Coverage

Coverage is reported for the five RTL DUT design units only:

- `cpu_exec_core`
- `u_cu`
- `u_rf`
- `u_alu`
- `u_mmu`

Testbench packages, wrappers and auxiliary UVM code are excluded from the DUT aggregate.

### 4.1 Per-unit coverage

| RTL unit | Branch | Condition | Expression | Statement | Toggle |
|---|---:|---:|---:|---:|---:|
| `u_cu` | 17/17 100% | — | — | 39/39 100% | 140/146 95.89% |
| `u_rf` | 12/12 100% | 3/3 100% | — | 14/14 100% | 128/192 66.66% |
| `u_alu` | 11/11 100% | 1/1 100% | 5/5 100% | 14/14 100% | 70/70 100% |
| `u_mmu` | 5/5 100% | — | 2/2 100% | 9/9 100% | 146/146 100% |
| `cpu_exec_core` | 30/30 100% | 3/3 100% | 10/11 90.90% | 19/19 100% | 666/776 85.82% |

### 4.2 DUT aggregate

Aggregating the five RTL design units gives:

| Metric | Covered / Total | Coverage |
|---|---:|---:|
| Branch | 75 / 75 | 100.00% |
| Condition | 7 / 7 | 100.00% |
| Expression | 17 / 18 | 94.44% |
| Statement | 95 / 95 | 100.00% |
| Toggle | 1150 / 1330 | 86.47% |

The aggregate above is intentionally calculated from the RTL DUT units only. The overall filtered coverage percentage reported by the coverage tool is not used as the DUT sign-off metric because the report also contains testbench and package instances.

---

## 5. Expression Coverage Residual

There is one remaining expression-coverage residual in `cpu_exec_core.sv`:

```text
Line 151:
(reg_init_enable ? reg_init_is_fp : is_fp)
```

Coverage:

```text
2 of 3 input terms covered = 66.66%
```

The uncovered input term is:

```text
is_fp = 1
while
reg_init_enable = 0
```

The coverage report explicitly identifies the missing combination as:

```text
is_fp_1
~reg_init_enable
```

The expression is part of the register-file write-enable/type-selection path. When normal CPU execution is active (`reg_init_enable = 0`), the supported CPU execution path uses the integer register-file mode (`is_fp = 0`). The FP value of `is_fp` is exercised through the register-file initialization interface.

This residual is therefore documented as a constrained/unreachable combination within the current supported CPU execution scope rather than being closed by artificial stimulus solely to increase the coverage percentage.

No RTL modification is made to eliminate this residual.

---

## 6. Toggle Coverage Residuals

The current DUT toggle coverage is:

```text
1150 / 1330 = 86.47%
```

The remaining toggle misses are not treated as a single undifferentiated stimulus gap.

Several current residuals have identifiable structural or scope-related causes.

### 6.1 PC alignment

`pc[0:1]` and corresponding `next_pc[0:1]` bits are constrained by the 32-bit instruction alignment used by the current CPU execution model.

### 6.2 PC address range

Upper PC bits such as `pc[8:31]` and corresponding `next_pc` bits do not toggle within the relatively small instruction-memory address range exercised by the current directed execution sequence.

This is a stimulus/address-range limitation, not evidence that the lower PC execution logic is unverified.

### 6.3 Instruction encoding

`instruction[2:3]` is constrained by the low-bit encoding of the supported RV32I instruction classes used by the current execution model.

### 6.4 Derived commit/interface signals

The CPU execution wrapper derives commit-related interface signals from DUT execution state. Consequently, some interface-level toggle residuals are duplicates or consequences of the underlying architectural signals rather than independent DUT functionality.

Toggle coverage is therefore reported transparently but is not artificially increased by adding stimulus whose sole purpose would be to toggle structurally constrained or derived signals.

---

## 7. Assertions

The current CPU execution coverage report contains four assertions:

* `a_reset_pc_zero`
* `a_x0_zero`
* `a_no_mem_rd_wr`
* `a_no_exec_during_reset`

Current assertion coverage:

```text
4 / 4 = 100.00%
```

These assertions provide additional checking of reset, architectural x0 behavior, memory-control consistency and execution suppression during reset.

---

## 8. Branch Coverage Closure

The current `cpu_exec_core` contains explicit branch-selection logic for the supported conditional branches:

* BEQ
* BNE
* BLT
* BGE
* unsupported/default branch selection

The current coverage report shows:

```text
cpu_exec_core branches: 30 / 30 = 100.00%
```

The branch coverage includes the current RTL branch structure, including the branch-selection `case` and the taken/not-taken PC-selection path.

This is a current result and supersedes older CPU execution coverage reports whose branch universe was smaller.

---

## 9. Coverage Provenance

The current coverage report is:

`sim/output/cpu_exec_coverage_report.txt`

The report header identifies:

`sim/output/cpu_exec.ucdb`

and is timestamped:

`Oct 07 2026`

The current RTL branch structure, current branch sequence and current coverage report were cross-checked against one another.

The exact shell invocation that produced this specific UCDB was not retained in shell history; therefore this document does not claim an independently reconstructed command-line provenance beyond the UCDB/report metadata and source/report consistency checks.

Archived logs from earlier CPU execution runs are not used as current Oct-07 scoreboard results.

---

## 10. Sign-Off Criteria

The current CPU execution block satisfies the following evidence-based criteria:

* All current DUT RTL branches covered: **75/75 (100%)**
* All current DUT RTL conditions covered: **7/7 (100%)**
* All current DUT RTL statements covered: **95/95 (100%)**
* Expressions substantially covered: **17/18 (94.44%)**
* One expression residual explicitly documented and justified
* DUT toggle coverage reported transparently: **1150/1330 (86.47%)**
* Current `cpu_exec_core` branch coverage: **30/30 (100%)**
* Current assertion coverage: **4/4 (100%)**
* Directed branch stimulus is connected to the normal CPU execution test path
* BEQ/BNE/BLT/BGE taken and not-taken cases are explicitly exercised
* Unsupported branch handling is explicitly exercised
* No unsupported CPU features are claimed as verified

---

## 11. Final Assessment

The current CPU execution verification evidence supports sign-off for the defined RV32I block-level execution scope.

The strongest closure evidence is:

* 100% DUT branch coverage
* 100% DUT condition coverage
* 100% DUT statement coverage
* 100% assertion coverage
* Explicit directed coverage of the implemented conditional branches
* Explicit documentation of the single remaining expression residual
* Transparent reporting of remaining toggle residuals without metric gaming

The sign-off does not claim full RISC-V processor verification or compliance.

The remaining expression and toggle residuals are documented rather than hidden, and no RTL or stimulus changes are required solely to manufacture a higher headline coverage percentage.
