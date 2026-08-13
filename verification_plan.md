Παρακάτω είναι ολόκληρο το αρχείο `verification_plan.md` όπως το έστειλες, έτοιμο για αντιγραφή και επικόλληση.
(Διατήρησα ακριβώς το περιεχόμενο που παρείχες, χωρίς αλλαγές.)

```markdown
# Verification Plan — RISC-V CPU Digital Verification Portfolio

## 1. Purpose

This document defines the verification strategy, scope, methodology,
toolchain, coverage objectives, verification status, and remaining gaps for
the RISC-V CPU verification portfolio project.

The project is designed as a block-level Digital Verification Engineering
portfolio demonstrating practical verification methodology rather than
claiming complete production CPU verification.

The verification strategy emphasizes:

- Self-checking testbenches
- UVM-based environments where appropriate
- Independent scoreboards
- Reference models
- Differential verification
- Functional coverage
- Assertion-based verification
- Formal verification
- Seed-based regression
- Reproducible simulation
- Explicit verification closure criteria
- Documented toolchain limitations

The project intentionally distinguishes between implemented verification
infrastructure and verified/closed functionality.

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
| ALU | `rtl/alu.sv` | UVM + scoreboard + functional coverage + formal | ✅ Verified |
| Control Unit | `rtl/cu.sv` | UVM + scoreboard + reference decode model | ✅ Verified |
| FPU | `rtl/fpu.sv`, `rtl/fpu_add.sv`, `rtl/fpu_sub.sv`, `rtl/fpu_mul.sv`, `rtl/fpu_div.sv` | Directed TB + differential/reference model + UVM smoke environment | 🟢 Active verification |
| MMU | `rtl/mmu.sv` | Directed TB + coverage | 🟡 Verification in progress |
| Register File | `rtl/register_file.sv` | Self-checking TB + scoreboard + reference model + assertions + coverage | 🟢 Active verification |
| CPU Core | `rtl/cpu_core.sv` | System-level integration | ⚪ Not yet verified |

The status labels are intentionally conservative.

An implemented testbench or verification component does not automatically
constitute verification closure.

---

# 4. Verification Methodology

The project uses multiple complementary verification techniques.

## 4.1 Directed Testing

Directed tests are used for:

- Reset behavior
- Deterministic corner cases
- Boundary values
- Illegal inputs
- Arithmetic corner cases
- IEEE-754 floating-point edge cases
- Regression reproduction
- Debugging

Directed testing provides deterministic, easy-to-reproduce failures.

It is particularly valuable for arithmetic blocks where specific boundary
conditions must be exercised deliberately.

---

## 4.2 Pseudo-Random Testing

The available simulator environment does not provide the full licensed
SystemVerilog constrained-random feature set.

Therefore the project uses:

```systemverilog
$urandom
$urandom_range
```

for pseudo-random stimulus generation.

Seeds can be controlled from the simulator command line, allowing failed
randomized scenarios to be reproduced.

This should not be confused with full SystemVerilog constrained-random
verification using:

```systemverilog
rand
constraint
randomize()
```

The limitation is explicitly documented as a simulator licensing
constraint.

## 4.3 Scoreboard-Based Checking

Scoreboards independently determine expected DUT behavior and compare it
against observed RTL outputs.

This prevents a testbench from being limited to simple procedural checks
against a small collection of hard-coded expected values.

Where appropriate, the scoreboard is backed by an independent reference
model.

## 4.4 Reference Models

Reference models provide an executable representation of expected behavior.

They are intentionally implemented independently from the DUT algorithm
where practical.

Current examples include:

```text
tests/register_file_reference_model.sv
```

and the independent FPU reference/differential verification flow.

The objective is to minimize the risk of reproducing an RTL implementation
bug inside the verification environment.

## 4.5 Differential Verification

Differential verification is used particularly for the FPU.

The FPU differential testbench is:

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

---

# 5. ALU Verification

## 5.1 RTL

The ALU is implemented in:

```text
rtl/alu.sv
```

Supported operations:

- ADD
- SUB
- AND
- OR
- XOR
- SLL
- SRA
- SLT

Additional outputs include:

- Zero
- Signed overflow

## 5.2 UVM Environment

The ALU environment contains:

- Agent
- Driver
- Monitor
- Scoreboard
- Functional coverage

The scoreboard calculates expected ALU behavior independently and compares
each transaction against the DUT.

## 5.3 Functional Coverage

ALU functional coverage tracks:

- All 8 operations
- Zero/non-zero behavior
- Overflow/no-overflow behavior

Current closure:

- 8/8 opcode bins hit
- Zero and non-zero behavior exercised
- Overflow and non-overflow behavior exercised

Because native SystemVerilog covergroup functionality is not available
under the selected free simulator license, coverage is implemented through
explicit/manual bin accounting.

This provides measurable coverage without depending on the
license-gated feature.

## 5.4 Formal Verification

The ALU has been formally verified using:

- SymbiYosys
- Boolector
- Bounded model checking

The current formal environment verifies properties including:

- Zero flag consistency
- Overflow behavior
- ADD/SUB overflow restrictions
- Illegal opcode behavior

The formal proof uses a depth of 2, which is sufficient for the current
combinational ALU properties.

All implemented ALU formal properties pass.

The result is stronger than simulation-only checking because the properties
are proven across the modeled input space rather than only across the
generated simulation vectors.

---

# 6. Control Unit Verification

## 6.1 RTL

The Control Unit is implemented in:

```text
rtl/cu.sv
```

The current instruction decoding scope is:

- R-type
- LW
- SW

## 6.2 Verification Environment

The Control Unit verification environment contains:

- UVM agent
- Driver
- Monitor
- Scoreboard
- Independent decode/reference model

The reference model independently reconstructs the expected control signals
from the instruction encoding.

This provides protection against the verification environment accidentally
assuming the same incorrect encoding as the RTL.

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

## 7.2 Directed Verification

The FPU directed testbench is:

```text
tests/fpu_tb.sv
```

The directed test suite exercises arithmetic operations and important
boundary conditions.

Particular attention is given to:

- Rounding
- Overflow boundaries
- Exponent transitions
- Sign handling
- Zero-related cases
- Division corner cases
- Floating-point representation boundaries

The testbench is self-checking and reports mismatches explicitly.

## 7.3 Differential Verification

The FPU also has an independent differential verification flow:

```text
tests/fpu_differential_tb.sv
```

The purpose is to compare DUT behavior against an independent reference
implementation.

This provides an additional verification layer beyond fixed expected-value
tests.

## 7.4 UVM Verification

The FPU verification infrastructure includes:

```text
uvm_tb/fpu_agent/fpu_pkg.sv
uvm_tb/fpu_agent/fpu_if.sv
uvm_tb/tb_top_fpu.sv
uvm_tb/tests/fpu_smoke_test.sv
```

The UVM environment provides the foundation for:

- Transaction-based stimulus
- Driver/monitor separation
- Scoreboard-based checking
- Regression integration
- Future coverage expansion

The current FPU UVM environment is considered an active verification
environment rather than a fully closed production environment.

## 7.5 FPU Coverage

FPU functional and code coverage are being progressively expanded.

Coverage closure is not claimed until the relevant bins and coverage
reports have been reviewed.

This is intentionally treated as an ongoing closure activity.

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

- Address behavior
- Boundary conditions
- Valid/invalid input scenarios
- Expected translation/control behavior
- Functional coverage

The MMU is currently classified as verification in progress.

Full virtual-memory/page-table architecture is outside the present project
scope.

---

# 9. Register File Verification

The Register File is implemented in:

```text
rtl/register_file.sv
```

A dedicated verification environment has been developed.

Current artifacts include:

```text
tests/register_file_tb.sv
tests/register_file_scoreboard.sv
tests/register_file_reference_model.sv
tests/register_file_assertions.sv
tests/register_file_coverage.sv
```

## 9.1 Reference Model

The Register File reference model provides an independent expected-state
representation.

The scoreboard compares the DUT state/outputs against this model.

This separates the expected behavior from the RTL implementation.

## 9.2 Assertions

The Register File has a dedicated assertion layer:

```text
tests/register_file_assertions.sv
```

Assertions are intended to detect invariant violations independently of
scoreboard checking.

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

## 9.3 Functional Coverage

Dedicated Register File coverage infrastructure exists in:

```text
tests/register_file_coverage.sv
```

Coverage closure remains an active verification task.

---

# 10. Functional Coverage Strategy

Coverage is treated as a verification planning mechanism rather than merely
as a percentage.

For each verified block, coverage should answer:

- What functionality is intended to be tested?
- Which bins represent that functionality?
- What stimulus reaches each bin?
- Which bins remain uncovered?
- Are uncovered bins legitimate exclusions or verification gaps?

## 10.1 Manual Coverage

Where native SystemVerilog covergroup functionality is unavailable under
the selected simulator license, explicit bin accounting is used.

This approach has been applied to ALU coverage and is being extended to
other blocks where appropriate.

Manual coverage provides:

- Explicit bin definitions
- Hit counters
- Coverage percentage
- Missing-bin visibility
- Regression-readable output

## 10.2 Coverage Closure Criteria

A block is not considered functionally closed merely because a testbench
executes successfully.

Closure requires:

- Required functional scenarios defined
- Required bins exercised
- Corner cases exercised
- Scoreboard/reference checking active
- Assertions reviewed where applicable
- Regression stability demonstrated
- Coverage report reviewed
- Remaining exclusions documented

---

# 11. Code Coverage

The simulation infrastructure supports Questa code coverage collection.

The project can use coverage options such as:

```text
+cover=bcesf
```

where supported by the selected simulator configuration.

Code coverage is considered a separate metric from functional coverage.

Functional coverage answers:

```text
Did we exercise the intended verification scenarios?
```

Code coverage answers:

```text
Which implementation structures were executed?
```

Complete project-wide code-coverage closure is not currently claimed.

Coverage reports must be generated and reviewed before declaring closure.

---

# 12. Assertion-Based Verification

Assertions provide a verification layer independent of scoreboards.

Existing assertion infrastructure includes ALU/CU assertion support and the
Register File assertion layer.

The project uses assertions for properties such as:

- Output consistency
- Illegal operation behavior
- Flag correctness
- Register-file invariants
- Interface/protocol conditions

Assertion execution and coverage are being progressively integrated into
the regression flow.

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

The current formal result is:

```text
ALU formal properties: 4/4 PASS
```

## Z3

Z3 did not complete the tested ALU property within the observed five-minute
evaluation window.

The ALU contains 32-bit variable-shift datapath logic, which can create
significant bit-vector solving complexity.

## Boolector

Boolector completed the tested properties in under one second.

This makes it the preferred solver for the current ALU formal target.

The solver difference is treated as a tool-selection/performance finding,
not as evidence of a design problem.

---

# 14. Regression Strategy

The project provides a seed-based regression framework:

```text
run_regression.sh
```

Usage:

```text
./run_regression.sh <target> <num_seeds>
```

The regression framework:

- Selects the requested verification target.
- Generates multiple simulator seeds.
- Runs the corresponding simulation.
- Captures pass/fail results.
- Produces a regression summary.

The seed is retained so that failures can be reproduced.

This is an important requirement for pseudo-random verification.

---

# 15. Simulation Scripts

The primary simulation entry point is:

```text
run_sim.sh
```

Examples:

```text
./run_sim.sh alu
./run_sim.sh cu
```

Additional block-specific flows are being incorporated as the verification
environment expands.

The objective is to provide a consistent command-line interface for local
verification and future CI integration.

---

# 16. Toolchain Strategy

The project intentionally uses free/open-source tools or free-licensed
tools wherever practical.

## Primary simulation environment

Questa - Altera FPGA Starter Edition

The simulator provides the UVM infrastructure required for the current
verification environment.

It was selected after evaluating Verilator compatibility.

The RTL remains technology-independent.

## Open-source formal verification

Formal verification uses:

- SymbiYosys
- Boolector

These provide an open-source formal verification flow.

---

# 17. Toolchain Investigation

## Verilator

Verilator was evaluated as an open-source simulation alternative.

The investigation identified several issues relevant to the intended
verification environment:

- Functional coverage limitations
- Clocking-block/modport limitations
- Problems involving virtual interfaces and clocking-block event handling
- UVM compatibility issues
- Incomplete compatibility patches in the evaluated
  chipsalliance/uvm-verilator environment

A compiler failure was encountered when class-based UVM code waited on a
clocking-block event through a virtual interface.

Because the project depends on transaction-level UVM infrastructure, these
issues made Verilator unsuitable as the primary UVM simulator for the
current environment.

## Questa Starter Edition

Questa provided the required native UVM simulation environment.

However, further investigation revealed an important licensing limitation.

The selected free environment does not provide the complete
svverification feature set required for:

- SystemVerilog `randomize()`
- `rand` / `constraint` solving
- Native SystemVerilog `covergroup` functionality

The failure was confirmed through the simulator's:

```text
Failure to checkout svverification license feature
```

diagnostic.

The verification architecture was therefore adapted rather than silently
assuming commercial-only features were available.

---

# 18. License-Constrained Verification Adaptations

Because full constrained-random and native functional coverage are not
available under the selected free simulator environment, the project uses:

| Commercial feature          | Current alternative                  |
| --------------------------- | ------------------------------------ |
| `randomize()` / constraints | `$urandom` / `$urandom_range`        |
| Native `covergroup`         | Manual bin accounting                |
| Commercial formal tools     | SymbiYosys + Boolector               |
| Commercial verification IP  | Custom UVM/testbench components      |
| Proprietary reference model | Independent project reference models |

This demonstrates an important engineering principle:

Verification methodology should adapt to tool constraints without
compromising the independence of checking.

---

# 19. Verification Findings

Several real RTL/verification issues were identified during development.

## 19.1 ALU/CU Control Encoding Mismatch

The original ALU implementation used a 3-bit operation encoding while the
verification environment expected a 4-bit encoding.

The original implementation also used an encoding inconsistent with the
intended RV32I-oriented design.

The issue was corrected by unifying the operation encoding and adding the
required ALU status outputs.

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

- R-type
- LW
- SW

This was detected through independent scoreboard/reference-model checking.

## 19.3 UVM Sampling Race

The driver and monitor initially synchronized to the same positive clock
edge.

This caused the monitor to observe values before NBA/combinational
settling in the first transaction.

The issue was corrected by introducing a small post-edge sampling delay in
the monitor.

The finding demonstrates why clocking/sampling semantics must be explicitly
controlled in a cycle-based verification environment.

---

# 20. Current Verification Status

| Verification Area              | Status         | Notes                                       |
| ------------------------------ | -------------- | ------------------------------------------- |
| ALU functional verification    | ✅ Closed       | Scoreboard + directed/pseudo-random testing |
| ALU functional coverage        | ✅ Closed       | 8/8 opcode bins hit                         |
| ALU formal verification        | ✅ Passed       | 4/4 properties                              |
| Control Unit verification      | ✅ Closed       | UVM + independent decode model              |
| FPU directed verification      | 🟢 Active      | Extensive arithmetic/corner-case testing    |
| FPU differential verification  | 🟢 Active      | Independent reference comparison            |
| FPU UVM infrastructure         | 🟢 Implemented | Smoke/regression foundation                 |
| FPU coverage closure           | 🟡 In progress | Further closure required                    |
| MMU directed verification      | 🟡 In progress | Dedicated TB exists                         |
| MMU coverage                   | 🟡 In progress | Dedicated coverage infrastructure exists    |
| Register File verification     | 🟢 Active      | Self-checking environment                   |
| Register File reference model  | 🟢 Implemented | Independent model                           |
| Register File scoreboard       | 🟢 Implemented | DUT/model comparison                        |
| Register File assertions       | 🟢 Implemented | Independent invariant checking              |
| Register File coverage         | 🟡 In progress | Coverage infrastructure exists              |
| Code coverage closure          | 🟡 In progress | Reports require further closure analysis    |
| Formal verification beyond ALU | ⚪ Future       | Additional targets planned                  |
| Unified CI regression          | 🟡 In progress | Local regression exists                     |
| CPU integration verification   | ⚪ Not started  | Future phase                                |
| Full-system verification       | ⚪ Not started  | Outside current scope                       |

---

# 21. Production-Grade Gap Analysis

The following gaps remain relative to a full production IC verification
environment.

| Area                  | Current State                           | Remaining Work                                         |
| --------------------- | --------------------------------------- | ------------------------------------------------------ |
| UVM methodology       | ALU/CU/FPU infrastructure               | Extend consistently to remaining blocks                |
| Constrained random    | License constrained                     | Requires licensed simulator or alternative methodology |
| Functional coverage   | Multiple block-specific implementations | Complete closure and consolidation                     |
| Code coverage         | Tooling available                       | Generate and analyze closure reports                   |
| Assertions            | Implemented for selected blocks         | Expand and integrate into regression                   |
| Formal                | ALU complete                            | Add additional block properties                        |
| Regression            | Seed-based local flow                   | Unified CI and artifact reporting                      |
| Reference models      | FPU/Register File                       | Expand where appropriate                               |
| Differential testing  | FPU                                     | Extend to additional datapath blocks                   |
| CPU integration       | Not started                             | Build integration environment                          |
| System-level checking | Not started                             | Add instruction-level reference model                  |
| VHDL                  | Not present                             | Not currently part of project scope                    |

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

- Instruction-level reference model
- Memory model
- End-to-end scoreboard
- CPU-level assertions
- Instruction coverage
- Register-state checking
- Memory-access checking
- Seed-based integration regression

---

# 23. Verification Closure Philosophy

Verification closure is not defined as achieving an arbitrary percentage.

A block is considered closed only when:

- The functional specification is defined.
- Verification scenarios are identified.
- Expected behavior is independently modeled.
- Self-checking mechanisms are active.
- Required functional coverage is exercised.
- Relevant assertions are evaluated.
- Regression stability is demonstrated.
- Code coverage is reviewed where applicable.
- Remaining exclusions are justified and documented.

This distinction is important because high code coverage does not necessarily
mean high functional confidence.

Similarly, a passing testbench does not constitute verification closure
without independent checking and coverage analysis.

---

# 24. Summary

The project has evolved from a simple RTL simulation exercise into a
multi-layer Digital Verification Engineering portfolio.

The current methodology combines:

- UVM
- Scoreboards
- Reference models
- Differential verification
- Functional coverage
- Assertions
- Formal verification
- Seed-based regression
- Toolchain analysis

The project intentionally documents both achievements and limitations.

The primary current focus is completing block-level verification and
coverage closure for the FPU, MMU, and Register File before progressing to
full CPU-core integration verification.

The ultimate objective is not to present an artificially complete CPU
verification environment, but to demonstrate the engineering discipline
required to define scope, identify failures, build independent checking,
measure coverage, analyze tool limitations, and drive a design toward
defensible verification closure.
```