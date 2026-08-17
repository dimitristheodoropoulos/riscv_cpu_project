# Verification Plan — RISC-V CPU Digital Verification Portfolio

## 1. Purpose

This document defines the verification strategy, scope, methodology,
toolchain, coverage objectives, verification status, closure criteria, and
remaining gaps for the RISC-V CPU Digital Verification portfolio project.

The project is designed as a block-level Digital Verification Engineering
portfolio demonstrating practical verification methodology rather than
claiming complete production CPU verification.

The verification strategy emphasizes:

- Self-checking testbenches
- UVM-based environments where appropriate
- Independent scoreboards
- Reference models
- Differential verification
- Directed testing
- Pseudo-random testing
- Functional coverage
- Code coverage
- Assertion-based verification
- Formal verification
- Seed-based regression
- Reproducible simulation
- Explicit verification closure criteria
- Documented toolchain limitations
- Analysis of uncovered and unreachable implementation paths

The project intentionally distinguishes between:

1. implemented verification infrastructure;
2. exercised and verified functionality;
3. measured coverage;
4. verification closure.

An implemented testbench or verification component does not automatically
constitute verification closure.

---

# 2. Verification Scope

The RTL contains several CPU-related blocks.

The primary verification scope currently covers:

- ALU
- Control Unit
- Floating-Point Unit
- MMU
- Register File
- CPU Execution Core

System-level `cpu_core` integration remains outside the current verification
closure scope.

The CPU is based on a deliberately scoped RV32I subset.

The current instruction-level scope includes:

- R-type operations
- LW
- SW

The following instruction classes are outside the current CPU integration
scope:

- Branch instructions
- Jump instructions
- I-type ALU immediate instructions
- LUI
- AUIPC
- Complete instruction fetch/decode/execute pipeline verification

This is a deliberate scope decision intended to produce measurable
block-level verification closure instead of broad but shallow CPU coverage.

---

# 3. Verification Matrix

| Block | RTL | Verification Environment | Current Status |
|---|---|---|---|
| ALU | `rtl/alu.sv` | UVM + scoreboard + functional coverage + formal | ✅ Closed for defined scope |
| Control Unit | `rtl/cu.sv` | UVM + scoreboard + independent decode model | ✅ Closed for defined scope |
| FPU | `rtl/fpu.sv`, `rtl/fpu_add.sv`, `rtl/fpu_sub.sv`, `rtl/fpu_mul.sv`, `rtl/fpu_div.sv` | Directed TB + Python reference/differential flow + UVM environment + code coverage + formal | ✅ Reachable coverage closure |
| MMU | `rtl/mmu.sv` | Directed TB + CPU execution integration + RTL coverage | ✅ Verified for current CPU execution scope |
| Register File | `rtl/register_file.sv` | Self-checking TB + scoreboard + reference model + coverage | ✅ Verified for defined register-file behavior |
| CPU Execution Core | `rtl/cpu_exec_core.sv` | UVM agent + reference model + scoreboard + architectural checking + RTL coverage | ✅ Closed for defined RV32I execution subset |
| CPU Core | `rtl/cpu_core.sv` | System-level integration | ⚪ Not yet verified |

The status labels are intentionally conservative.

A block may have extensive verification infrastructure while still remaining
open because coverage, corner-case analysis, assertions, or integration
verification are incomplete.

---

# 4. Verification Methodology

The project uses multiple complementary verification techniques.

The methodology is adapted to the capabilities and licensing limitations
of the selected simulator environment.

---

## 4.1 Directed Testing

Directed tests are used for:

- Reset behavior
- Deterministic corner cases
- Boundary values
- Illegal inputs
- Arithmetic corner cases
- IEEE-754 floating-point edge cases
- Rounding boundaries
- Overflow and underflow boundaries
- Regression reproduction
- Debugging

Directed testing provides deterministic, easy-to-reproduce failures.

It is particularly valuable for arithmetic blocks where specific internal
conditions must be exercised deliberately.

---

## 4.2 Pseudo-Random Testing

The selected simulator environment does not provide the complete licensed
SystemVerilog constrained-random feature set required for unrestricted use
of:

```systemverilog
rand
constraint
randomize()
```

Therefore the project uses simulator-supported pseudo-random stimulus
generation through:

```systemverilog
$urandom
$urandom_range
```

Seeds can be controlled from the simulator command line, allowing failed
randomized scenarios to be reproduced.

This is intentionally described as pseudo-random testing and is not claimed
to be equivalent to full constrained-random verification.

---

## 4.3 Scoreboard-Based Checking

Scoreboards independently determine expected DUT behavior and compare it
against observed RTL outputs.

This prevents a testbench from being limited to simple procedural checks
against a small collection of hard-coded expected values.

Where appropriate, the scoreboard is backed by an independent reference
model.

---

## 4.4 Reference Models

Reference models provide executable representations of expected behavior.

They are intentionally implemented independently from the DUT algorithm
where practical.

Current examples include:

```text
tests/register_file_reference_model.sv

reference/binary32.py
reference/fpu_reference_model.py
reference/scoreboard_bridge.py

uvm_tb/cpu_model/cpu_reference_model.sv
```

The objective is to minimize the risk of reproducing an RTL implementation
bug inside the verification environment.

---

## 4.5 Differential Verification

Differential verification is used particularly for the FPU.

The main FPU differential testbench is:

```text
tests/fpu_differential_tb.sv
```

The verification architecture compares the RTL implementation against an
independent reference implementation.

The current FPU differential vector regression has completed with:

```text
4154 generated differential vectors
0 mismatches
0 errors
```

This is a strong verification result for the tested reference-model
behavior, but it does not by itself constitute full FPU closure.

---

# 5. ALU Verification

## 5.1 RTL

The ALU is implemented in:

```text
rtl/alu.sv
```

Supported operations:

* ADD
* SUB
* AND
* OR
* XOR
* SLL
* SRA
* SLT

Additional outputs include:

* Zero
* Signed overflow

---

## 5.2 UVM Environment

The ALU environment contains:

* Agent
* Driver
* Monitor
* Scoreboard
* Functional coverage

The scoreboard calculates expected ALU behavior independently and compares
each transaction against the DUT.

---

## 5.3 Functional Coverage

ALU functional coverage tracks:

* All 8 operations
* Zero/non-zero behavior
* Overflow/no-overflow behavior

Current closure for the defined ALU functional scope:

* 8/8 opcode bins hit
* Zero and non-zero behavior exercised
* Overflow and non-overflow behavior exercised

Because native SystemVerilog covergroup functionality is not available in
the selected free simulator configuration, coverage is implemented through
explicit/manual bin accounting where required.

---

## 5.4 Formal Verification

The ALU has been formally verified using:

* SymbiYosys
* Boolector
* Bounded model checking

Current result:

```text
ALU formal properties: 4/4 PASS
```

Boolector completed the tested properties significantly faster than the
evaluated Z3 configuration.

---

# 6. Control Unit Verification

## 6.1 RTL

The Control Unit is implemented in:

```text
rtl/cu.sv
```

The current instruction decoding scope is:

* R-type
* LW
* SW

---

## 6.2 Verification Environment

The Control Unit verification environment contains:

* UVM agent
* Driver
* Monitor
* Scoreboard
* Independent decode/reference model

The reference model independently reconstructs the expected control signals
from the instruction encoding.

The Control Unit is considered closed for the currently defined RV32I
instruction subset.

---

# 7. Floating-Point Unit Verification

## 7.1 RTL Structure

The FPU is implemented through dedicated arithmetic blocks:

```text
rtl/fpu.sv
rtl/fpu_add.sv
rtl/fpu_sub.sv
rtl/fpu_mul.sv
rtl/fpu_div.sv
```

The FPU supports the currently implemented arithmetic operations:

```text
ADD
SUB
MUL
DIV
```

The FPU operates on 32-bit IEEE-754 binary32 representations.

The project does **not** claim complete IEEE-754 compliance.

The exact supported, partially supported, unsupported, and out-of-scope
behavior is defined in:

```text
docs/fpu_ieee754_verification_matrix.md
```

---

## 7.2 Directed Verification

The FPU directed testbench is:

```text
tests/fpu_tb.sv
```

The directed test suite exercises arithmetic operations and important
boundary conditions, including:

* Normal numbers
* Signed values
* Positive and negative zero
* Infinity
* NaN
* Subnormal values
* Overflow
* Underflow
* Exponent transitions
* Sign handling
* Rounding
* Rounding carry
* Multiplication normalization
* Division normalization
* Division underflow
* Representation boundaries

The testbench is self-checking and reports mismatches explicitly.

---

## 7.3 Independent Python Reference Model

The project contains an independent Python reference-model infrastructure:

```text
reference/binary32.py
reference/fpu_reference_model.py
reference/scoreboard_bridge.py
```

The reference model provides an executable expected-behavior model that is
independent from the RTL implementation.

---

## 7.4 Differential Verification

The FPU differential verification flow uses:

```text
tests/fpu_differential_tb.sv
```

The current differential regression contains:

```text
4154 vectors
0 errors
```

This demonstrates agreement between the FPU RTL and the independent
reference model for the tested vector set.

---

## 7.5 FPU UVM Environment

The FPU UVM infrastructure includes:

```text
uvm_tb/fpu_agent/fpu_pkg.sv
uvm_tb/fpu_agent/fpu_if.sv
uvm_tb/tb_top_fpu.sv
uvm_tb/tests/fpu_smoke_test.sv
```

The FPU package also contains dedicated sequences for:

* constrained-style pseudo-random testing;
* corner-case testing;
* general testing;
* coverage-closure testing.

---

## 7.6 FPU Coverage Closure

The FPU coverage closure flow is executed through the project simulation
infrastructure using the dedicated closure target.

The closure flow uses Questa coverage collection including:

```text
+cover=bcesf
```

where supported by the simulator configuration.

The latest detailed FPU closure analysis reports:

| Coverage Metric    | Raw Coverage | Reachable Coverage | Waivers |
| ------------------ | -----------: | -----------------: | ------: |
| Branch Coverage    |        96.72% |            100.00% |       6 |
| Condition Coverage |        88.50% |            100.00% |      13 |
| Statement Coverage |        95.37% |            100.00% |      17 |
| Toggle Coverage    |        79.95% |                  - |       - |

The closure process distinguishes between:

```text
Reachable verification gap
```

and:

```text
Legitimate/unreachable implementation path
```

Any justified exclusion must be documented rather than silently ignored.

Detailed branch/condition/statement waivers are documented in:

```text
docs/fpu_branch_waivers.md
```

The formal evidence is documented in the same report and includes:

- MUL `subnormal_shift >= 25` formal PASS
- DIV `shift_cnt >= 10` mathematical proof
- DIV full-DUT formal blocked by variable-bound loop at `fpu_div.sv:387`

---

# 8. CPU Execution Core Verification

## 8.1 RTL

The CPU Execution Core is implemented in:

```text
rtl/cpu_exec_core.sv
```

This is a minimal single-cycle RV32I execution datapath.

It integrates:

- `cu`
- `register_file`
- `alu`
- `mmu`

and includes:

- PC logic
- Instruction memory
- Writeback multiplexing
- Load/store address generation
- Testbench-only register initialization interface
- Testbench-only execution control

---

## 8.2 Verification Environment

The CPU Execution Core verification environment includes:

```text
uvm_tb/cpu_agent/cpu_exec_if.sv
uvm_tb/cpu_agent/cpu_exec_uvm_wrapper.sv
uvm_tb/cpu_agent/cpu_transaction.sv
uvm_tb/cpu_agent/cpu_driver.sv
uvm_tb/cpu_agent/cpu_monitor.sv
uvm_tb/cpu_agent/cpu_scoreboard.sv
uvm_tb/cpu_model/cpu_reference_model.sv
uvm_tb/sequences/cpu_exec_sequence.sv
uvm_tb/tests/cpu_exec_test.sv
```

Additional standalone smoke tests include:

```text
tests/cpu_exec_tb.sv
tests/cpu_exec_reg_init_smoke_tb.sv
```

---

## 8.3 Reference Model

The CPU reference model independently models the architectural effects of
the supported instruction subset.

Supported instructions:

```text
ADD
SUB
AND
OR
XOR
SLL
SRA
SLT
LW
SW
```

The reference model maintains:

- architectural integer register state
- data memory state
- PC

It does not access DUT internals.

---

## 8.4 Scoreboard

The scoreboard compares the architectural state predicted by the reference
model with the observed DUT state.

The current directed CPU execution suite includes:

| Instruction / Case | Status |
|--------------------|--------|
| ADD                | ✅ Pass |
| SUB                | ✅ Pass |
| AND                | ✅ Pass |
| OR                 | ✅ Pass |
| XOR                | ✅ Pass |
| SLL                | ✅ Pass |
| SRA                | ✅ Pass |
| SLT                | ✅ Pass |
| SW + LW            | ✅ Pass |
| x0 write suppression | ✅ Pass |
| Unsupported R-type funct3 | ✅ Pass |
| Zero-instruction PC behavior | ✅ Pass |
| FP register initialization | ✅ Pass |

Scoreboard summary:

```text
Architectural verification PASSED

UVM_ERROR = 0
UVM_FATAL = 0
```

---

## 8.5 CPU Execution RTL Coverage Closure

RTL coverage was collected using Questa Coverage (UCDB).

Verified RTL blocks:

| Block | Branch | Statement |
|-------|--------|-----------|
| `cpu_exec_core` | 100% | 100% |
| `cu` | 100% | 100% |
| `alu` | 100% | 100% |
| `register_file` | 100% | 100% |
| `mmu` | 100% | 100% |

The achieved result is:

- 100% reachable RTL branch coverage
- 100% RTL statement coverage
- Condition coverage: 100% reported bins
- Full coverage of all implemented RV32I execution paths

Remaining toggle coverage gaps correspond to unused/unreachable
instruction encoding fields outside the implemented CPU subset.

This does **not** represent complete RV32I processor coverage.

Full RV32I processor verification remains outside the current scope.

---

# 9. MMU Verification

The MMU is implemented in:

```text
rtl/mmu.sv
```

The current verification infrastructure includes:

```text
tests/mmu_tb.sv
tests/mmu_coverage.sv
```

The MMU has been integrated into the CPU execution core load/store path.

A reset mechanism was added to ensure proper memory isolation between
directed CPU execution tests.

MMU verification is currently classified as:

```text
Verified for current CPU execution scope
```

Full virtual-memory/page-table architecture is outside the present project
scope.

---

# 10. Register File Verification

The Register File is implemented in:

```text
rtl/register_file.sv
```

A dedicated self-checking verification environment has been developed.

Current artifacts include:

```text
tests/register_file_tb.sv
tests/register_file_scoreboard.sv
tests/register_file_reference_model.sv
tests/register_file_assertions.sv
tests/register_file_coverage.sv
```

The Register File has been covered at standalone level with:

```text
12/12 branch coverage
```

---

# 11. Functional Coverage Strategy

Coverage is treated as a verification planning and closure mechanism rather
than merely as a percentage.

For each verified block, coverage should answer:

* What functionality is intended to be tested?
* Which bins represent that functionality?
* What stimulus reaches each bin?
* Which bins remain uncovered?
* Are uncovered bins legitimate exclusions or verification gaps?
* Are uncovered RTL structures actually reachable?

---

# 12. Code Coverage

The project supports simulator-based code coverage collection using the
Questa verification environment.

Coverage categories used during FPU closure analysis include:

```text
Branch
Condition
Statement
Toggle
```

The latest FPU reachable coverage summary is:

| Metric    | Raw Coverage | Reachable Coverage | Waived |
|-----------|-------------:|-------------------:|-------:|
| Branch    |        96.72% |            100.00% |      6 |
| Condition |        88.50% |            100.00% |     13 |
| Statement |        95.37% |            100.00% |     17 |

CPU execution RTL coverage is documented in:

```text
docs/cpu_exec_verification_plan.md
```

Project-wide code-coverage closure is not currently claimed.

---

# 13. Assertion-Based Verification

Assertions provide a verification layer independent of scoreboards.

Existing assertion infrastructure includes:

```text
tests/register_file_assertions.sv
```

as well as assertion support in the ALU/CU verification environment.

Assertions are used for properties such as:

* Output consistency
* Illegal operation behavior
* Flag correctness
* Register-file invariants
* Interface/protocol conditions

---

# 14. Formal Verification Strategy

Formal verification currently targets:

- ALU
- FPU unreachable-branch invariants

The flow uses:

```text
SymbiYosys
    │
    ▼
Boolector
```

Current results:

```text
ALU formal properties: 4/4 PASS

FPU MUL waiver invariant:
  subnormal_shift >= 25
  PASS

FPU DIV shift invariant:
  shift_cnt >= 10
  PASS
```

The DIV full-DUT formal proof is blocked by a Yosys limitation on the
variable-bound loop at `fpu_div.sv:387`.

---

# 15. Regression Strategy

The project provides a seed-based regression framework:

```text
run_regression.sh
```

Usage:

```bash
./run_regression.sh <target> <num_seeds>
```

The FPU also has a dedicated coverage-closure target.

The formal regression is available through:

```bash
./run_formal.sh
```

---

# 16. Simulation Scripts

The primary simulation entry point is:

```text
run_sim.sh
```

Examples:

```bash
./run_sim.sh alu
./run_sim.sh cu
./run_sim.sh fpu_closure
./run_sim.sh cpu_exec
```

---

# 17. Toolchain Strategy

The project intentionally uses free/open-source tools or free-licensed
tools wherever practical.

The primary UVM simulation environment uses:

```text
Questa - Altera FPGA Starter Edition
```

Formal verification uses:

```text
SymbiYosys
Boolector
```

---

# 18. License-Constrained Verification Adaptations

Because full constrained-random solving and native functional coverage are
not available under the selected free simulator environment, the project
uses:

| Licensed / Commercial Feature     | Current Alternative                  |
| --------------------------------- | ------------------------------------ |
| `randomize()` / constraints       | `$urandom` / `$urandom_range`        |
| Native `covergroup` functionality | Manual bin accounting where required |
| Commercial formal tools           | SymbiYosys + Boolector               |
| Commercial verification IP        | Custom UVM/testbench components      |
| Proprietary reference model       | Independent project reference models |

---

# 19. Verification Findings

Several real RTL and verification issues were identified during development.

---

## 19.1 ALU/CU Control Encoding Mismatch

The original ALU implementation used a 3-bit operation encoding while the
verification environment expected a 4-bit encoding.

The issue was corrected by unifying the operation encoding and adding the
required ALU status outputs.

---

## 19.2 Control Unit Opcode Interpretation

The original Control Unit used MIPS-style opcode fields:

```text
instruction[31:26]
```

instead of the RV32I opcode field:

```text
instruction[6:0]
```

The Control Unit was rewritten to decode the intended RV32I subset.

---

## 19.3 UVM Sampling Race

The driver and monitor initially synchronized to the same positive clock
edge.

The issue was corrected by introducing a small post-edge sampling delay in
the monitor.

---

## 19.4 FPU Coverage Closure Analysis

During FPU coverage closure, uncovered branches were inspected directly in
the RTL rather than simply adding random stimulus until the coverage
percentage increased.

The analysis identified branches whose triggering conditions are either:

* difficult or impossible to reach using valid binary32 operands;
* dependent on internal states that cannot be produced by the legal input
  domain;
* better treated as justified implementation exclusions.

The closure methodology therefore distinguishes between genuine reachable
verification gaps and structurally unreachable implementation paths.

---

## 19.5 CPU Register Initialization Ordering

During CPU execution core verification, register initialization was
initially performed before reset release.

This caused the reset logic in the register file to clear the initialized
values.

The issue was corrected by releasing reset before performing register
initialization through the testbench interface.

---

## 19.6 CPU Memory Reset Isolation

The MMU initially had no reset mechanism.

This caused store data from a previous test to persist across multiple
CPU execution transactions.

The issue was corrected by adding a reset mechanism to the MMU and
connecting it to the CPU execution core reset.

---

# 20. Current Verification Status

| Verification Area              | Status         | Notes                                       |
| ------------------------------ | -------------- | ------------------------------------------- |
| ALU functional verification    | ✅ Closed       | Scoreboard + directed/pseudo-random testing |
| ALU functional coverage        | ✅ Closed       | 8/8 opcode bins hit                         |
| ALU formal verification        | ✅ Passed       | 4/4 properties                              |
| Control Unit verification      | ✅ Closed       | UVM + independent decode model              |
| FPU directed verification      | ✅ Passed       | Extensive arithmetic/corner-case testing    |
| FPU differential verification  | ✅ Passed       | 4154 vectors, 0 mismatches                  |
| FPU UVM infrastructure         | ✅ Implemented  | Transaction and regression foundation       |
| FPU reachable coverage closure | ✅ Closed       | Branch/condition/statement reachable 100%   |
| MMU directed verification      | ✅ Verified     | Integrated into CPU exec load/store path    |
| MMU coverage                   | ✅ Closed       | 100% branch coverage in CPU exec            |
| Register File verification     | ✅ Closed       | 12/12 branch coverage standalone            |
| Register File assertions       | ✅ Implemented  | Independent invariant checking              |
| CPU Execution Core verification| ✅ Closed       | Closed for defined RV32I execution subset   |
| CPU Execution directed suite   | ✅ Passed       | Supported cases + architectural checks      |
| CPU Execution RTL branch analysis | ✅ Closed for analyzed DUT hierarchy | 63/63 analyzed branches covered |
| Code coverage closure          | 🟡 In progress  | Block-level reports require further analysis|
| Formal verification            | ✅ Partial      | ALU 4/4, FPU MUL/DIV invariants PASS        |
| Unified CI regression          | 🟡 In progress  | Local regression exists                     |
| CPU integration verification   | 🟢 Initial      | CPU exec core being verified                |
| Full-system verification       | ⚪ Not started  | Outside current scope                       |

---

# 21. Industry-Style Gap Analysis

The following gaps remain relative to a full professional IC verification
environment.

| Area                  | Current State                   | Remaining Work                                         |
| --------------------- | ------------------------------- | ------------------------------------------------------ |
| UVM methodology       | ALU/CU/FPU/CPU-exec infrastructure | Extend consistently to remaining blocks                |
| Constrained random    | Simulator-license constrained   | Requires licensed simulator or alternative methodology |
| Functional coverage   | Block-specific implementations  | Complete closure and consolidation                     |
| Code coverage         | Questa collection available     | Complete analysis and justified exclusions             |
| Assertions            | Implemented for selected blocks | Expand and integrate into regression                   |
| Formal                | ALU + FPU invariants            | Add additional block properties                        |
| Regression            | Seed-based local flow           | Unified CI and artifact reporting                      |
| Reference models      | FPU/Register File/CPU exec      | Expand where appropriate                               |
| Differential testing  | FPU                             | Extend to additional datapath blocks                   |
| CPU integration       | Initial CPU exec verification   | Build full integration environment                     |
| System-level checking | Not started                     | Add instruction-level reference model                  |
| VHDL                  | Not present                     | Not currently part of project scope                    |

These gaps are documented intentionally.

---

# 22. CPU Integration Verification — Future Phase

The CPU integration phase has begun with the `cpu_exec_core` verification
environment.

This is an intermediate integration block containing:

- CU
- Register File
- ALU
- MMU

It supports a minimal RV32I execution datapath.

The planned future CPU-level verification includes:

```text
                 Instruction Stimulus
                         │
                         ▼
                 ┌───────────────┐
                 │   CPU Core    │
                 └───────┬───────┘
                         │
               ┌─────────┴─────────┐
               ▼                   ▼
        ┌─────────────┐     ┌─────────────┐
        │   Memory    │     │ Integration │
        │    Model    │     │  Monitor    │
        └─────────────┘     └──────┬──────┘
                                   │
                                   ▼
                            ┌─────────────┐
                            │ Integration │
                            │  Scoreboard │
                            └──────┬──────┘
                                   │
                                   ▼
                            Reference Model
```

Planned capabilities include:

* Instruction-level reference model
* Memory model
* End-to-end scoreboard
* CPU-level assertions
* Instruction coverage
* Register-state checking
* Memory-access checking
* Seed-based integration regression

The CPU integration phase will continue after the current block-level
verification infrastructure reaches sufficient maturity.

---

# 23. Verification Closure Philosophy

Verification closure is not defined as achieving an arbitrary percentage.

A block is considered closed only when:

1. The functional specification is defined.
2. Verification scenarios are identified.
3. Expected behavior is independently modeled.
4. Self-checking mechanisms are active.
5. Required functional coverage is exercised.
6. Relevant assertions are evaluated.
7. Regression stability is demonstrated.
8. Code coverage is reviewed where applicable.
9. Uncovered implementation paths are analyzed.
10. Legitimate exclusions are justified and documented.
11. No known reachable verification gap remains unexplained.

---

# 24. FPU Closure Criteria

The FPU has a dedicated closure methodology because floating-point arithmetic
contains substantially more corner cases than the simpler CPU blocks.

FPU closure requires:

* Supported IEEE-754 binary32 behavior explicitly defined
* Directed corner cases exercised
* Independent Python reference model operational
* Differential verification passing
* Rounding behavior exercised
* Overflow behavior exercised
* Underflow behavior exercised
* Subnormal behavior exercised where supported
* NaN/Infinity behavior exercised where supported
* Sign and zero behavior exercised
* FPU UVM environment operational
* Coverage regression executed
* Branch coverage reviewed
* Condition coverage reviewed
* Statement coverage reviewed
* Toggle coverage reviewed
* Remaining uncovered paths classified
* Legitimate unreachable paths documented
* No known reachable functional gap left unexplained

The current FPU status is:

```text
Verification: active
Differential flow: passing
Code coverage reachable closure: complete
Full IEEE-754 compliance: not claimed
```

---

# 25. Summary

The project has evolved from a simple RTL simulation exercise into a
multi-layer Digital Verification Engineering portfolio.

The current methodology combines:

* UVM
* Directed testing
* Pseudo-random testing
* Scoreboards
* Reference models
* Differential verification
* Functional coverage
* Code coverage
* Assertions
* Formal verification
* Seed-based regression
* Toolchain analysis
* Coverage reachability analysis

The current verification position is:

```text
ALU
  └── Defined-scope verification closed
  └── Functional coverage closed
  └── Formal verification passed

Control Unit
  └── Defined-scope verification closed

FPU
  ├── Directed verification active
  ├── Independent reference model implemented
  ├── Differential verification passing
  ├── 4154 vectors / 0 mismatches
  ├── Reachable branch coverage: 100%
  ├── Reachable condition coverage: 100%
  ├── Reachable statement coverage: 100%
  └── 6 branch + 13 condition + 17 statement waivers documented

MMU
  ├── Reset mechanism added
  ├── Integrated into CPU exec load/store path
  └── 100% branch coverage in CPU exec

Register File
  ├── Self-checking environment implemented
  ├── Reference model implemented
  ├── Scoreboard implemented
  ├── Assertions implemented
  └── 12/12 branch coverage standalone

CPU Execution Core
  ├── UVM agent/driver/monitor/scoreboard implemented
  ├── Reference model implemented
  ├── Directed execution suite passed
  └── RTL branch analysis closed: 63/63 analyzed branches covered

CPU Core
  └── Full integration verification not yet started
```

The project intentionally documents both achievements and limitations.

The immediate verification focus is completing defensible block-level
closure for the MMU, Register File, and initial CPU execution core.

The next major phase is continued CPU integration verification.

The ultimate objective is to demonstrate the engineering discipline
required to:

```text
Define Scope
     ↓
Define Expected Behavior
     ↓
Build Independent Checking
     ↓
Create Directed / Pseudo-Random Stimulus
     ↓
Run Differential Verification
     ↓
Measure Functional Coverage
     ↓
Measure Code Coverage
     ↓
Run Assertions / Formal Checks
     ↓
Run Reproducible Regression
     ↓
Analyze Failures
     ↓
Analyze Uncovered Paths
     ↓
Distinguish Reachable Gaps from Legitimate Exclusions
     ↓
Drive Coverage Closure
     ↓
Document Remaining Gaps
```

This repository therefore presents both the verification infrastructure that
has been implemented and the limitations that remain.
