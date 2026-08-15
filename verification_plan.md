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

System-level `cpu_core` integration remains outside the current verification
closure scope.

The CPU itself is based on a deliberately scoped RV32I subset.

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
| FPU | `rtl/fpu.sv`, `rtl/fpu_add.sv`, `rtl/fpu_sub.sv`, `rtl/fpu_mul.sv`, `rtl/fpu_div.sv` | Directed TB + Python reference/differential flow + UVM environment + code coverage | 🟡 Closure in progress |
| MMU | `rtl/mmu.sv` | Directed TB + coverage | 🟡 Verification in progress |
| Register File | `rtl/register_file.sv` | Self-checking TB + scoreboard + reference model + assertions + coverage | 🟢 Active verification |
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
````

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

Conceptually:

```text
                  Stimulus
                     │
              ┌──────┴──────┐
              │             │
              ▼             ▼
         ┌─────────┐   ┌─────────────┐
         │ FPU RTL │   │  Reference  │
         │         │   │    Model    │
         └────┬────┘   └──────┬──────┘
              │               │
              └───────┬───────┘
                      ▼
                  Comparator
                      │
              PASS / MISMATCH
```

This approach is particularly valuable for floating-point arithmetic,
where exhaustive hand-written expected-value tests are impractical.

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

This provides measurable coverage without depending on a license-gated
feature.

---

## 5.4 Formal Verification

The ALU has been formally verified using:

* SymbiYosys
* Boolector
* Bounded model checking

The current formal environment verifies properties including:

* Zero flag consistency
* Overflow behavior
* ADD/SUB overflow restrictions
* Illegal opcode behavior

The formal proof uses a depth of 2, which is sufficient for the current
combinational ALU properties.

Current result:

```text
ALU formal properties: 4/4 PASS
```

The result provides stronger evidence than simulation-only checking because
the implemented properties are proven across the modeled input space rather
than only across generated simulation vectors.

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

This provides protection against the verification environment accidentally
assuming the same incorrect encoding as the RTL.

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

That document is the authoritative verification contract for the currently
claimed FPU subset.

---

## 7.2 Directed Verification

The FPU directed testbench is:

```text
tests/fpu_tb.sv
```

The directed test suite exercises arithmetic operations and important
boundary conditions.

Particular attention is given to:

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
* Arithmetic corner cases

The testbench is self-checking and reports mismatches explicitly.

Several targeted tests were added specifically to exercise difficult
internal floating-point paths, including:

* multiplication rounding overflow;
* multiplication overflow;
* multiplication subnormal normalization;
* very small subnormal operands;
* division subnormal results;
* extreme division underflow;
* addition overflow;
* addition rounding carry;
* rounding boundary transitions.

These tests are intended to improve both functional confidence and
implementation coverage.

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

The model explicitly works with binary32 representation and provides the
foundation for differential verification.

The reference model includes binary32 conversion and rounding behavior
needed by the differential flow.

Python tests are provided under:

```text
tests/reference/
```

The reference implementation is intentionally separated from the
SystemVerilog RTL so that the verification environment does not simply
reproduce the same arithmetic algorithm used by the DUT.

---

## 7.4 Differential Verification

The FPU differential verification flow uses:

```text
tests/fpu_differential_tb.sv
```

Differential vectors are generated using the Python reference-model
infrastructure.

The current differential regression contains:

```text
4154 vectors
0 errors
```

This demonstrates agreement between the FPU RTL and the independent
reference model for the tested vector set.

Differential verification is particularly valuable for floating-point
arithmetic because a finite collection of manually calculated expected
values is insufficient to provide broad confidence.

The differential flow is therefore considered an important verification
layer, while FPU closure remains dependent on the complete verification
contract and coverage analysis.

---

## 7.5 FPU UVM Environment

The FPU UVM infrastructure includes:

```text
uvm_tb/fpu_agent/fpu_pkg.sv
uvm_tb/fpu_agent/fpu_if.sv
uvm_tb/tb_top_fpu.sv
uvm_tb/tests/fpu_smoke_test.sv
```

The environment provides:

* Transaction-based stimulus
* Driver/monitor separation
* Scoreboard infrastructure
* Regression integration
* Pseudo-random stimulus
* Coverage-closure stimulus sequences

The FPU package also contains dedicated sequences for:

* constrained-style pseudo-random testing;
* corner-case testing;
* general testing;
* coverage-closure testing.

Because of simulator licensing limitations, these sequences use supported
pseudo-random mechanisms rather than relying on native SystemVerilog
constraint solving.

---

## 7.6 FPU Coverage Closure

The FPU coverage closure flow is executed through the project simulation
infrastructure using the dedicated closure target.

The closure flow uses Questa coverage collection including:

```text
+cover=bcesf
```

where supported by the simulator configuration.

The closure sequence is configured for a large pseudo-random regression and
is supplemented by targeted directed vectors.

The latest detailed FPU code-coverage report reports:

| Coverage Metric    | Current Result |
| ------------------ | -------------: |
| Branch Coverage    |         90.56% |
| Condition Coverage |         85.00% |
| Statement Coverage |         92.85% |
| Toggle Coverage    |         77.59% |

These results demonstrate substantial RTL implementation coverage, but the
FPU is **not yet considered fully closed**.

Coverage analysis is performed at the RTL branch/condition/statement/toggle
level, together with functional scenario analysis.

The remaining uncovered paths are reviewed individually rather than being
treated as automatic verification failures.

In particular, some uncovered implementation branches were analyzed as
practically unreachable under valid IEEE-754 binary32 operand combinations
or dependent on internal states that cannot be produced through legal DUT
inputs.

Such branches should not be artificially stimulated merely to increase a
coverage percentage.

The closure process therefore distinguishes between:

```text
Reachable verification gap
```

and:

```text
Legitimate/unreachable implementation path
```

Any justified exclusion must be documented rather than silently ignored.

---

# 8. MMU Verification

The MMU is implemented in:

```text
rtl/mmu.sv
```

The current verification infrastructure includes:

```text
tests/mmu_tb.sv
tests/mmu_coverage.sv
```

Verification focuses on:

* Address behavior
* Boundary conditions
* Valid/invalid input scenarios
* Expected translation/control behavior
* Functional coverage

The MMU is currently classified as:

```text
Verification in progress
```

Full virtual-memory/page-table architecture is outside the present project
scope.

---

# 9. Register File Verification

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

---

## 9.1 Reference Model

The Register File reference model provides an independent expected-state
representation.

The scoreboard compares DUT state and outputs against this model.

This separates expected behavior from the RTL implementation.

---

## 9.2 Scoreboard

The Register File scoreboard independently determines expected register
state and compares it with the DUT behavior.

This provides transaction-level checking rather than relying only on
directed expected-value comparisons.

---

## 9.3 Assertions

The Register File has a dedicated assertion layer:

```text
tests/register_file_assertions.sv
```

Assertions are intended to detect invariant and interface violations
independently of scoreboard checking.

This provides complementary verification:

```text
                  Register File DUT
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
     Scoreboard      Assertions      Coverage
          │
          ▼
   Reference Model
```

---

## 9.4 Functional Coverage

Dedicated Register File coverage infrastructure exists in:

```text
tests/register_file_coverage.sv
```

Coverage infrastructure is implemented, while complete closure remains an
active verification task.

---

# 10. Functional Coverage Strategy

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

## 10.1 Manual Functional Coverage

Where native SystemVerilog covergroup functionality is unavailable under
the selected simulator license, explicit/manual bin accounting is used.

Manual coverage provides:

* Explicit bin definitions
* Hit counters
* Coverage percentage
* Missing-bin visibility
* Regression-readable output

This approach is currently used for selected verification environments.

---

## 10.2 Code Coverage

Questa code coverage is used where applicable to measure implementation
execution.

The current FPU closure report includes:

```text
Branch
Condition
Statement
Toggle
```

Code coverage is analyzed separately from functional coverage.

---

## 10.3 Coverage Closure Criteria

A block is not considered functionally closed merely because a testbench
executes successfully.

Closure requires:

* Required functional scenarios defined
* Required bins exercised
* Corner cases exercised
* Scoreboard/reference checking active
* Assertions reviewed where applicable
* Regression stability demonstrated
* Coverage report reviewed
* Uncovered implementation paths analyzed
* Legitimate exclusions documented
* No known reachable verification gap left unexplained

High code coverage alone is not sufficient for closure.

---

# 11. Code Coverage

The simulation infrastructure supports Questa code coverage collection.

The project uses coverage options such as:

```text
+cover=bcesf
```

for the coverage-closure flow.

Code coverage is considered a separate metric from functional coverage.

Functional coverage answers:

```text
Did we exercise the intended verification scenarios?
```

Code coverage answers:

```text
Which implementation structures were executed?
```

The latest detailed FPU coverage report is:

```text
Branch     : 90.56%
Condition  : 85.00%
Statement  : 92.85%
Toggle     : 77.59%
```

These results represent the current detailed FPU code-coverage state.

Project-wide code-coverage closure is not currently claimed.

---

# 12. Assertion-Based Verification

Assertions provide a verification layer independent of scoreboards.

Existing assertion infrastructure includes:

```text
tests/register_file_assertions.sv
```

as well as assertion support in the ALU/CU verification environment.

The project uses assertions for properties such as:

* Output consistency
* Illegal operation behavior
* Flag correctness
* Register-file invariants
* Interface/protocol conditions

Assertion execution and coverage are progressively integrated into the
regression flow.

Assertion infrastructure is considered complementary to scoreboards and
functional/code coverage.

---

# 13. Formal Verification Strategy

Formal verification currently targets the ALU.

The flow uses:

```text
SymbiYosys
    │
    ▼
Boolector
```

The ALU properties are proven using bounded model checking.

Current result:

```text
ALU formal properties: 4/4 PASS
```

The current properties include:

* Zero flag correctness
* Overflow behavior
* ADD/SUB overflow restrictions
* Illegal opcode behavior

The current proof depth is:

```text
depth = 2
```

This is sufficient for the implemented combinational ALU properties.

---

## 13.1 Z3 Investigation

Z3 was evaluated for the ALU formal properties.

The tested Z3 configuration did not complete the evaluated property within
the observed five-minute evaluation window.

The ALU contains 32-bit variable-shift datapath logic, which can create
significant bit-vector solving complexity.

---

## 13.2 Boolector

Boolector completed the tested ALU properties in under one second.

This makes Boolector the preferred solver for the current ALU formal target.

The solver difference is treated as a tool-selection and performance
finding rather than as evidence of an RTL problem.

---

# 14. Regression Strategy

The project provides a seed-based regression framework:

```text
run_regression.sh
```

Usage:

```bash
./run_regression.sh <target> <num_seeds>
```

The regression framework:

1. selects the requested verification target;
2. generates simulator seeds;
3. runs the corresponding simulation;
4. captures pass/fail results;
5. produces a regression summary.

Seeds are retained so that failures can be reproduced.

This is an important requirement for pseudo-random verification.

The FPU also has a dedicated coverage-closure target which combines
pseudo-random stimulus with directed coverage-oriented tests.

---

# 15. Simulation Scripts

The primary simulation entry point is:

```text
run_sim.sh
```

Examples:

```bash
./run_sim.sh alu
./run_sim.sh cu
./run_sim.sh fpu_closure
```

The FPU closure flow compiles the required RTL and UVM verification
environment and enables Questa coverage collection.

The verification infrastructure is intended to provide a consistent
command-line interface for local verification and future CI integration.

---

# 16. Toolchain Strategy

The project intentionally uses free/open-source tools or free-licensed
tools wherever practical.

---

## 16.1 Primary Simulation Environment

The primary UVM simulation environment is:

```text
Questa - Altera FPGA Starter Edition
```

The simulator provides the UVM infrastructure required for the current
verification environment.

It was selected after evaluating Verilator compatibility with the required
SystemVerilog/UVM features.

The RTL remains technology-independent.

---

## 16.2 Open-Source Formal Verification

Formal verification uses:

```text
SymbiYosys
Boolector
```

These provide an open-source formal verification flow.

---

# 17. Toolchain Investigation

## 17.1 Verilator

Verilator was evaluated as an open-source simulation alternative.

The investigation identified limitations relevant to the intended
verification environment, including:

* SystemVerilog functional coverage limitations
* Clocking-block/modport limitations
* Virtual-interface clocking-block event handling
* UVM compatibility issues
* Compatibility issues with the evaluated UVM/Verilator environment

A compiler failure was encountered when class-based UVM code waited on a
clocking-block event through a virtual interface.

Because the project depends on transaction-level UVM infrastructure, these
issues made Verilator unsuitable as the primary UVM simulator for the
current environment.

Verilator may still be useful as a secondary open-source lint or simulation
tool for compatible individual testbenches.

---

## 17.2 Questa Starter Edition

Questa provided the required native UVM simulation environment.

Further investigation identified an important licensing limitation.

The selected free environment does not provide the complete licensed
SystemVerilog verification feature set required for unrestricted use of:

* SystemVerilog `randomize()`
* `rand` / `constraint` solving
* Native SystemVerilog `covergroup` functionality

The simulator reported:

```text
Failure to checkout svverification license feature
```

when the relevant licensed functionality was attempted.

The verification architecture was therefore adapted rather than silently
assuming commercial-only features were available.

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

This demonstrates an important engineering principle:

> Verification methodology should adapt to tool constraints without
> compromising the independence of checking.

The limitation is explicitly documented rather than hidden.

---

# 19. Verification Findings

Several real RTL and verification issues were identified during development.

---

## 19.1 ALU/CU Control Encoding Mismatch

The original ALU implementation used a 3-bit operation encoding while the
verification environment expected a 4-bit encoding.

The original implementation also used an encoding inconsistent with the
intended RV32I-oriented design.

The issue was corrected by unifying the operation encoding and adding the
required ALU status outputs.

This demonstrates the value of independent verification expectations
rather than assuming the RTL interface is automatically correct.

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

The Control Unit was rewritten to decode the intended RV32I subset:

* R-type
* LW
* SW

The issue was detected through independent scoreboard/reference-model
checking.

---

## 19.3 UVM Sampling Race

The driver and monitor initially synchronized to the same positive clock
edge.

This caused the monitor to observe values before NBA/combinational
settling in the first transaction.

The issue was corrected by introducing a small post-edge sampling delay in
the monitor.

The finding demonstrates why clocking and sampling semantics must be
explicitly controlled in a cycle-based verification environment.

---

## 19.4 FPU Coverage Closure Analysis

During FPU coverage closure, uncovered branches were inspected directly in
the RTL rather than simply adding random stimulus until the coverage
percentage increased.

The analysis identified branches whose triggering conditions are either:

* difficult or impossible to reach using valid binary32 operands;
* dependent on internal states that cannot be produced by the legal input
  domain;
* or better treated as justified implementation exclusions.

The closure methodology therefore distinguishes between genuine reachable
verification gaps and structurally unreachable implementation paths.

This prevents artificial stimulus from being added solely to improve a
coverage number without corresponding functional value.

---

# 20. Current Verification Status

| Verification Area              | Status           | Notes                                                            |
| ------------------------------ | ---------------- | ---------------------------------------------------------------- |
| ALU functional verification    | ✅ Closed         | Scoreboard + directed/pseudo-random testing                      |
| ALU functional coverage        | ✅ Closed         | 8/8 opcode bins hit                                              |
| ALU formal verification        | ✅ Passed         | 4/4 properties                                                   |
| Control Unit verification      | ✅ Closed         | UVM + independent decode model                                   |
| FPU directed verification      | 🟢 Active        | Extensive arithmetic and corner-case testing                     |
| FPU differential verification  | 🟢 Verified flow | 4154 vectors, 0 mismatches                                       |
| FPU Python reference model     | 🟢 Implemented   | Independent binary32 reference infrastructure                    |
| FPU UVM infrastructure         | 🟢 Implemented   | Transaction and regression foundation                            |
| FPU code coverage              | 🟡 In progress   | Branch 90.56%, Condition 85.00%, Statement 92.85%, Toggle 77.59% |
| FPU coverage closure           | 🟡 In progress   | Remaining paths require reachability/exclusion analysis          |
| MMU directed verification      | 🟡 In progress   | Dedicated TB exists                                              |
| MMU coverage                   | 🟡 In progress   | Dedicated coverage infrastructure exists                         |
| Register File verification     | 🟢 Active        | Self-checking environment                                        |
| Register File reference model  | 🟢 Implemented   | Independent model                                                |
| Register File scoreboard       | 🟢 Implemented   | DUT/model comparison                                             |
| Register File assertions       | 🟢 Implemented   | Independent invariant checking                                   |
| Register File coverage         | 🟡 In progress   | Coverage infrastructure implemented                              |
| Code coverage closure          | 🟡 In progress   | Block-level reports require further analysis                     |
| Formal verification beyond ALU | ⚪ Future         | Additional targets planned                                       |
| Seed-based regression          | 🟢 Implemented   | Reproducible local regression flow                               |
| Unified CI regression          | 🟡 In progress   | Local regression exists                                          |
| CPU integration verification   | ⚪ Not started    | Future phase                                                     |
| Full-system verification       | ⚪ Not started    | Outside current scope                                            |

---

# 21. Production-Grade Gap Analysis

The following gaps remain relative to a full production IC verification
environment.

| Area                  | Current State                   | Remaining Work                                         |
| --------------------- | ------------------------------- | ------------------------------------------------------ |
| UVM methodology       | ALU/CU/FPU infrastructure       | Extend consistently to remaining blocks                |
| Constrained random    | Simulator-license constrained   | Requires licensed simulator or alternative methodology |
| Functional coverage   | Block-specific implementations  | Complete closure and consolidation                     |
| Code coverage         | Questa collection available     | Complete analysis and justified exclusions             |
| Assertions            | Implemented for selected blocks | Expand and integrate into regression                   |
| Formal                | ALU complete                    | Add additional block properties                        |
| Regression            | Seed-based local flow           | Unified CI and artifact reporting                      |
| Reference models      | FPU/Register File               | Expand where appropriate                               |
| Differential testing  | FPU                             | Extend to additional datapath blocks                   |
| CPU integration       | Not started                     | Build integration environment                          |
| System-level checking | Not started                     | Add instruction-level reference model                  |
| VHDL                  | Not present                     | Not currently part of project scope                    |

These gaps are documented intentionally.

The project does not attempt to disguise incomplete areas as completed
verification.

---

# 22. CPU Integration Verification — Future Phase

Once block-level verification reaches sufficient maturity, the next major
verification phase is CPU-level integration.

The planned environment includes:

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

The CPU integration phase will begin only after the relevant block-level
verification infrastructure has reached sufficient maturity.

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

This distinction is important because high code coverage does not
necessarily mean high functional confidence.

Similarly, a passing testbench does not constitute verification closure
without independent checking and coverage analysis.

For arithmetic RTL, closure also requires explicit analysis of corner cases
and numerical boundary behavior.

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

The current FPU status is therefore:

```text
Verification: active
Differential flow: passing
Code coverage: substantial
Coverage closure: in progress
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
  ├── Branch coverage: 90.56%
  ├── Condition coverage: 85.00%
  ├── Statement coverage: 92.85%
  ├── Toggle coverage: 77.59%
  └── Coverage closure in progress

MMU
  └── Verification in progress

Register File
  ├── Self-checking environment implemented
  ├── Reference model implemented
  ├── Scoreboard implemented
  ├── Assertions implemented
  └── Coverage closure in progress

CPU Core
  └── Integration verification not yet started
```

The project intentionally documents both achievements and limitations.

The immediate verification focus is completing defensible block-level
closure for the FPU, MMU, and Register File.

The next major phase is CPU-core integration verification.

The ultimate objective is not to present an artificially complete CPU
verification environment, but to demonstrate the engineering discipline
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

It deliberately avoids claiming complete CPU verification or complete
IEEE-754 compliance where those claims are not supported by the current
verification evidence.
