


# RISC-V CPU — Digital Verification Portfolio

A block-level Digital Verification Engineering portfolio project for a
deliberately scoped RV32I-based CPU.

The project follows a verification-first methodology and demonstrates
practical verification techniques including:

- SystemVerilog self-checking testbenches
- UVM-based verification environments
- Independent scoreboards
- Reference models
- Differential verification
- Directed testing
- Pseudo-random testing
- Functional coverage
- Assertion-based verification
- Formal verification
- Seed-based regression
- Coverage reporting
- Reproducible command-line verification flows
- Explicit verification closure criteria
- Toolchain and licensing analysis

The objective is **not** to claim complete CPU verification or complete
IEEE-754 compliance.

Instead, the project demonstrates how verification scope is defined,
expected behavior is independently modeled, failures are detected,
coverage is measured, tool limitations are handled, and verification
closure is approached systematically.

For the detailed verification strategy and current status, see:

- `verification_plan.md`
- `docs/fpu_ieee754_verification_matrix.md`

---

# Verification Scope

The RTL contains several CPU-related blocks.

The current primary verification scope covers:

- ALU
- Control Unit
- Floating-Point Unit
- MMU
- Register File

System-level CPU integration remains a future verification phase.

The CPU is based on a deliberately scoped RV32I subset.

Current instruction-level scope:

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

This deliberate scope allows the project to demonstrate measurable
block-level verification rather than broad but shallow CPU coverage.

---

# Current Verification Matrix

| Block | RTL | Verification Environment | Status |
|---|---|---|---|
| ALU | `rtl/alu.sv` | UVM + scoreboard + functional coverage + formal | ✅ Verified |
| Control Unit | `rtl/cu.sv` | UVM + scoreboard + independent decode model | ✅ Verified |
| FPU | `rtl/fpu.sv`, `rtl/fpu_add.sv`, `rtl/fpu_sub.sv`, `rtl/fpu_mul.sv`, `rtl/fpu_div.sv` | Directed TB + Python reference/differential flow + UVM smoke environment | 🟢 Active verification |
| MMU | `rtl/mmu.sv` | Directed TB + coverage | 🟡 Verification in progress |
| Register File | `rtl/register_file.sv` | Self-checking TB + scoreboard + reference model + assertions + coverage | 🟢 Active verification |
| CPU Core | `rtl/cpu_core.sv` | System-level integration | ⚪ Not yet verified |

The status labels intentionally distinguish between:

1. implemented verification infrastructure;
2. verified scenarios;
3. actual verification closure.

An implemented testbench does not automatically constitute verification
closure.

---

# Verification Architecture

The project uses multiple complementary verification layers rather than
relying on a single testbench.

```text
                    ┌─────────────────────────┐
                    │       Test Stimulus      │
                    │ Directed / Pseudo-Random │
                    └────────────┬────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │          DUT            │
                    │       RTL Block         │
                    └────────────┬────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
       ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
       │ Scoreboard  │    │ Assertions  │    │  Coverage   │
       └──────┬──────┘    └─────────────┘    └─────────────┘
              │
              ▼
       ┌─────────────┐
       │  Reference  │
       │    Model    │
       └─────────────┘
````

Different blocks use different combinations of these components according
to their verification requirements.

The overall methodology emphasizes independence between:

* stimulus generation;
* DUT behavior;
* expected-value calculation;
* assertions;
* coverage measurement;
* regression infrastructure.

---

# ALU Verification

## RTL

The ALU is implemented in:

```text
rtl/alu.sv
```

Supported operations:

```text
ADD
SUB
AND
OR
XOR
SLL
SRA
SLT
```

Additional outputs include:

```text
Zero
Signed overflow
```

## Verification Environment

The ALU verification environment includes:

* UVM agent
* Driver
* Monitor
* Scoreboard
* Functional coverage
* Golden reference model
* Assertions
* Formal verification

The scoreboard independently calculates the expected ALU behavior and
compares it against the RTL output.

## Functional Coverage

ALU functional coverage tracks:

* all 8 ALU operations;
* zero/non-zero behavior;
* overflow/no-overflow behavior.

Current closure:

```text
8/8 opcode bins hit
Zero and non-zero behavior exercised
Overflow and non-overflow behavior exercised
```

Because native SystemVerilog covergroup functionality is not available
under the selected free simulator license, the project uses explicit
manual bin accounting.

This provides measurable functional coverage without depending on
license-gated functionality.

## Formal Verification

The ALU has also been formally verified using:

```text
SymbiYosys
Boolector
Bounded Model Checking
```

The current formal environment verifies properties including:

* zero flag consistency;
* overflow behavior;
* ADD/SUB overflow restrictions;
* illegal opcode behavior.

Current result:

```text
4/4 implemented ALU formal properties PASS
```

The current proof uses bounded model checking with depth 2, which is
sufficient for the implemented combinational ALU properties.

Boolector completed the tested properties significantly faster than the
evaluated Z3 configuration.

The solver difference is treated as a tool-selection and performance
finding rather than as evidence of an RTL problem.

---

# Control Unit Verification

## RTL

The Control Unit is implemented in:

```text
rtl/cu.sv
```

The current decoding scope is:

```text
R-type
LW
SW
```

## Verification Environment

Verification uses:

* UVM agent;
* Driver;
* Monitor;
* Scoreboard;
* Independent decode/reference model.

The reference model reconstructs the expected control signals independently
from the RTL implementation.

This provides protection against reproducing the same incorrect opcode or
control encoding inside the verification environment.

During development, the verification environment detected an opcode
interpretation mismatch involving MIPS-style opcode assumptions versus the
RV32I opcode field.

The issue was corrected so that the RTL and verification environment use
the intended RV32I subset.

---

# Floating-Point Unit Verification

## RTL Structure

The FPU is implemented through dedicated arithmetic blocks:

```text
rtl/fpu.sv
rtl/fpu_add.sv
rtl/fpu_sub.sv
rtl/fpu_mul.sv
rtl/fpu_div.sv
```

The supported operation selector is:

| Operation                     | Opcode   |
| ----------------------------- | -------- |
| Floating-point addition       | `3'b000` |
| Floating-point subtraction    | `3'b001` |
| Floating-point multiplication | `3'b010` |
| Floating-point division       | `3'b011` |

The FPU operates on 32-bit IEEE-754 binary32 operands.

The project does **not** claim complete IEEE-754 compliance.

The exact supported, partial, unsupported, and out-of-scope behavior is
defined in:

```text
docs/fpu_ieee754_verification_matrix.md
```

That document is the authoritative verification contract for the current
FPU subset.

---

## FPU Directed Verification

The directed FPU testbench is:

```text
tests/fpu_tb.sv
```

The test suite exercises arithmetic operations and important boundary
conditions.

Particular attention is given to:

* rounding;
* overflow boundaries;
* exponent transitions;
* sign handling;
* zero-related cases;
* division corner cases;
* floating-point representation boundaries;
* carry/rounding boundaries.

The testbench is self-checking and reports mismatches explicitly.

---

# FPU Independent Reference Model

The project contains an independent Python reference-model infrastructure:

```text
reference/binary32.py
reference/fpu_reference_model.py
reference/scoreboard_bridge.py
```

The purpose of the reference model is to provide an executable expected
behavior model that is independent of the RTL implementation.

The model explicitly works with binary32 representation and provides the
foundation for differential verification.

This is intentionally separated from the SystemVerilog RTL so that the
verification environment does not simply reproduce the same arithmetic
algorithm used by the DUT.

The project also contains Python unit tests for the reference model:

```text
tests/reference/test_binary32.py
tests/reference/test_fpu_reference_model.py
```

Reference-vector generation utilities are provided in:

```text
tests/reference/generate_fpu_vectors.py
tests/reference/generate_fpu_differential_vectors.py
```

---

# FPU Differential Verification

The dedicated differential testbench is:

```text
tests/fpu_differential_tb.sv
```

The conceptual architecture is:

```text
                    Stimulus
                       │
              ┌────────┴────────┐
              │                 │
              ▼                 ▼
       ┌─────────────┐   ┌─────────────┐
       │   FPU RTL   │   │  Reference  │
       │             │   │    Model    │
       └──────┬──────┘   └──────┬──────┘
              │                 │
              └────────┬────────┘
                       ▼
                  Comparator
                       │
                PASS / MISMATCH
```

Differential verification is particularly valuable for floating-point
arithmetic because a finite collection of manually calculated expected
values is insufficient to provide broad confidence.

The reference model and differential infrastructure are implemented.

The FPU itself remains classified as **actively verified**, rather than
fully closed, until the defined supported scenarios satisfy the project's
verification closure criteria.

---

# FPU UVM Environment

The FPU UVM infrastructure includes:

```text
uvm_tb/fpu_agent/fpu_pkg.sv
uvm_tb/fpu_agent/fpu_if.sv
uvm_tb/tb_top_fpu.sv
uvm_tb/tests/fpu_smoke_test.sv
```

The environment provides the foundation for:

* transaction-based stimulus;
* driver/monitor separation;
* scoreboard-based checking;
* regression integration;
* future functional coverage expansion.

The current UVM environment is considered an active verification
environment rather than a fully closed production verification environment.

---

# FPU Coverage

FPU functional and code coverage are being progressively expanded.

Coverage closure is not claimed until:

* the relevant bins are defined;
* required scenarios are exercised;
* coverage reports are reviewed;
* uncovered bins are classified;
* legitimate exclusions are documented;
* remaining verification gaps are addressed.

The project's FPU verification matrix explicitly defines the intended
verification scope before coverage is used as a closure metric.

---

# MMU Verification

## RTL

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

* address behavior;
* boundary conditions;
* valid/invalid input scenarios;
* expected translation/control behavior;
* functional coverage.

MMU verification is currently classified as:

```text
Verification in progress
```

Full virtual-memory/page-table architecture is outside the present project
scope.

---

# Register File Verification

## RTL

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

The verification architecture is:

```text
                    Register File DUT
                           │
             ┌─────────────┼─────────────┐
             │             │             │
             ▼             ▼             ▼
        Scoreboard     Assertions     Coverage
             │
             ▼
       Reference Model
```

The scoreboard compares DUT behavior against an independently implemented
reference model.

Assertions independently check invariant and protocol properties.

Functional coverage is implemented and measured, while full closure remains
an active verification task.

---

# Verification Methodology

The project deliberately combines several complementary verification
techniques.

---

## Directed Testing

Directed tests are used for:

* deterministic corner cases;
* boundary conditions;
* reset behavior;
* illegal inputs;
* arithmetic corner cases;
* IEEE-754 edge cases;
* regression reproduction;
* debugging.

Directed testing provides deterministic and easily reproducible failure
cases.

---

## Pseudo-Random Testing

The selected free simulator environment does not provide the complete
license-gated SystemVerilog constrained-random feature set.

Therefore pseudo-random stimulus is generated using:

```systemverilog
$urandom
$urandom_range
```

Seeds can be controlled from the simulator command line, allowing failed
randomized scenarios to be reproduced.

This is intentionally described as pseudo-random testing and is **not**
presented as equivalent to full SystemVerilog constrained-random
verification using:

```systemverilog
rand
constraint
randomize()
```

The limitation is documented as a simulator licensing constraint.

---

## Scoreboards

Scoreboards independently calculate or obtain expected DUT behavior and
compare it against observed RTL outputs.

This prevents the verification environment from being limited to a small
collection of hard-coded expected values.

Where appropriate, scoreboards are backed by independent reference models.

---

## Reference Models

Reference models provide executable representations of expected behavior.

Current examples include:

```text
tests/register_file_reference_model.sv

reference/binary32.py
reference/fpu_reference_model.py
reference/scoreboard_bridge.py
```

Reference models are intentionally separated from the DUT implementation
where practical.

The objective is to reduce the risk of reproducing an RTL implementation
bug inside the verification environment.

---

## Differential Verification

Differential verification is currently used particularly for the FPU.

The main FPU differential testbench is:

```text
tests/fpu_differential_tb.sv
```

The architecture compares the DUT against an independent reference
implementation.

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

This approach is especially useful for floating-point arithmetic, where
exhaustive hand-written expected-value tests are impractical.

---

# Functional Coverage

Functional coverage is tracked at block level.

Where native SystemVerilog covergroup functionality is unavailable under
the selected free simulator license, explicit/manual bin accounting is
used.

This approach provides:

* explicit bin definitions;
* hit counters;
* coverage percentages;
* missing-bin visibility;
* regression-readable output.

Coverage is treated as a verification closure metric rather than merely as
a percentage for presentation.

A coverage item is considered closed only when:

1. the intended bins are defined;
2. stimulus exists to exercise the bins;
3. required bins are hit;
4. the resulting report is reviewed;
5. missing bins are covered or explicitly justified.

---

# Assertion-Based Verification

The project contains assertion infrastructure for selected blocks.

Current examples include:

```text
tests/register_file_assertions.sv
```

as well as assertion support in the ALU/CU verification environment.

Assertions are used to detect invariant violations independently of
scoreboard checking.

Examples include:

* output consistency;
* illegal operation behavior;
* flag correctness;
* register-file invariants;
* protocol/interface conditions.

Assertion execution and coverage are progressively integrated into the
verification flow.

---

# Formal Verification

Formal verification currently targets the ALU.

The flow uses:

```text
SymbiYosys
    │
    ▼
Boolector
```

The ALU properties are verified using bounded model checking.

Current result:

```text
ALU formal properties: 4/4 PASS
```

The current properties include:

* zero flag correctness;
* overflow behavior;
* ADD/SUB overflow restrictions;
* illegal opcode behavior.

The current proof depth is 2, which is sufficient for the implemented
combinational ALU properties.

Additional formal targets remain future work.

---

# Regression Strategy

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
2. generates multiple simulator seeds;
3. runs the corresponding simulation;
4. captures pass/fail results;
5. produces a regression summary.

Seeds are retained so that failures can be reproduced.

This is an important requirement for pseudo-random verification.

---

# Simulation Scripts

The primary simulation entry point is:

```text
run_sim.sh
```

Examples:

```bash
./run_sim.sh alu
./run_sim.sh cu
```

Additional block-specific flows are incorporated as the verification
environment expands.

The objective is to provide a consistent command-line interface for local
verification and future CI integration.

---

# Toolchain Strategy

The project intentionally uses free/open-source tools or free-licensed
tools wherever practical.

---

## Questa / Siemens EDA

The primary UVM simulation environment uses:

```text
Questa - Altera FPGA Starter Edition
```

It was selected after evaluating Verilator compatibility with the required
SystemVerilog/UVM features.

The simulator provides the UVM infrastructure required for the current
verification environment.

The RTL remains technology-independent.

---

## Verilator

Verilator was evaluated as an open-source simulation alternative.

The investigation identified limitations relevant to the intended
verification environment, including:

* SystemVerilog functional coverage limitations;
* clocking-block/modport limitations;
* virtual-interface clocking-block event handling;
* UVM compatibility issues;
* incomplete compatibility with the evaluated UVM/Verilator environment.

A compiler failure was encountered when class-based UVM code waited on a
clocking-block event through a virtual interface.

Because the project depends on transaction-level UVM infrastructure, these
issues made Verilator unsuitable as the primary UVM simulator for the
current environment.

Verilator may still be useful as a secondary open-source lint/simulation
tool for compatible individual testbenches.

---

## Formal Tools

Formal verification uses:

```text
SymbiYosys
Boolector
```

These provide an open-source formal verification flow.

---

# Free-Tool Verification Adaptations

A deliberate objective of this project is to demonstrate how far a
professional verification methodology can be taken using free/open-source
tools and free-licensed simulator editions.

The selected Questa Starter Edition does not provide the complete
license-gated SystemVerilog Verification feature set required for:

```text
randomize()
rand / constraint solving
native covergroup functionality
```

The project therefore uses the following alternatives:

| Commercial / Licensed Feature | Current Alternative                  |
| ----------------------------- | ------------------------------------ |
| `randomize()` / constraints   | `$urandom` / `$urandom_range`        |
| Native `covergroup`           | Manual bin accounting                |
| Commercial formal tools       | SymbiYosys + Boolector               |
| Commercial verification IP    | Custom UVM/testbench components      |
| Proprietary reference model   | Independent project reference models |

This demonstrates an important engineering principle:

> Verification methodology should adapt to tool constraints without
> compromising the independence of checking.

The limitation is explicitly documented rather than hidden.

---

# Verification Findings

Several real RTL and verification issues were identified during development.

## ALU/CU Control Encoding Mismatch

The original ALU implementation used a 3-bit operation encoding while the
verification environment expected a 4-bit encoding.

The original implementation also used an encoding inconsistent with the
intended RV32I-oriented design.

The issue was corrected by unifying the operation encoding and adding the
required ALU status outputs.

---

## Control Unit Opcode Interpretation

The original Control Unit used MIPS-style opcode assumptions:

```text
instruction[31:26]
```

instead of the RV32I opcode field:

```text
instruction[6:0]
```

The Control Unit was corrected to decode the intended RV32I subset:

```text
R-type
LW
SW
```

The issue was detected through independent scoreboard/reference-model
checking.

---

## UVM Sampling Race

The driver and monitor initially synchronized to the same positive clock
edge.

This caused the monitor to observe values before NBA/combinational settling
in the first transaction.

The issue was corrected by introducing a small post-edge sampling delay in
the monitor.

This finding demonstrates why clocking and sampling semantics must be
explicitly controlled in cycle-based verification environments.

---

# Current Verification Status

The project intentionally maintains explicit status instead of claiming
project-wide closure.

| Verification Area              | Status         | Notes                                       |
| ------------------------------ | -------------- | ------------------------------------------- |
| ALU functional verification    | ✅ Closed       | Scoreboard + directed/pseudo-random testing |
| ALU functional coverage        | ✅ Closed       | 8/8 opcode bins hit                         |
| ALU formal verification        | ✅ Passed       | 4/4 properties                              |
| Control Unit verification      | ✅ Closed       | UVM + independent decode model              |
| FPU directed verification      | 🟢 Active      | Extensive arithmetic/corner-case testing    |
| FPU differential verification  | 🟢 Active      | Independent Python reference comparison     |
| FPU reference model            | 🟢 Implemented | Independent Python binary32 infrastructure  |
| FPU UVM infrastructure         | 🟢 Implemented | Smoke/regression foundation                 |
| FPU coverage closure           | 🟡 In progress | Further closure required                    |
| MMU directed verification      | 🟡 In progress | Dedicated TB exists                         |
| MMU coverage                   | 🟡 In progress | Dedicated coverage infrastructure exists    |
| Register File verification     | 🟢 Active      | Self-checking environment                   |
| Register File reference model  | 🟢 Implemented | Independent model                           |
| Register File scoreboard       | 🟢 Implemented | DUT/model comparison                        |
| Register File assertions       | 🟢 Implemented | Independent invariant checking              |
| Register File coverage         | 🟡 In progress | Coverage infrastructure implemented         |
| Code coverage closure          | 🟡 In progress | Reports require further closure analysis    |
| Formal verification beyond ALU | ⚪ Future       | Additional targets planned                  |
| Unified CI regression          | 🟡 In progress | Local regression exists                     |
| CPU integration verification   | ⚪ Not started  | Future phase                                |
| Full-system verification       | ⚪ Not started  | Outside current scope                       |

---

# Production-Grade Verification Roadmap

The long-term objective is to evolve the project toward a more complete
production-style verification environment.

## Phase 1 — Block-Level Verification

Current and near-term activities:

* ALU UVM environment
* ALU scoreboard
* ALU functional coverage
* ALU formal verification
* Control Unit UVM environment
* Control Unit scoreboard
* FPU directed verification
* FPU reference model
* FPU differential verification
* FPU UVM infrastructure
* Register File scoreboard/reference model
* Register File assertions
* Register File coverage infrastructure
* MMU verification infrastructure

---

## Phase 2 — Coverage and Assertion Closure

Planned activities:

* Complete FPU functional coverage closure
* Complete MMU coverage closure
* Complete Register File coverage closure
* Generate consolidated code-coverage reports
* Expand assertion coverage
* Add assertion results to regression summaries
* Document justified exclusions

---

## Phase 3 — Formal Expansion

Potential future targets:

* Control Unit formal verification
* Register File formal properties
* MMU formal properties
* FPU property verification where practical
* Additional ALU properties

---

## Phase 4 — Regression and CI

Planned capabilities:

* Seed-based local regression
* Unified block-level regression
* Automated coverage collection
* CI regression integration
* Regression artifacts and reports
* Failure reproduction from stored seeds
* Machine-readable regression summaries

---

## Phase 5 — CPU Integration

Future CPU-level verification will include:

* CPU-core integration testbench
* Instruction-level reference model
* End-to-end instruction checking
* Memory model
* Integration scoreboard
* System-level functional coverage
* CPU-level assertions
* CPU-level regression

Conceptually:

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

---

# Production-Grade Gap Analysis

The current project remains intentionally below the level of a complete
production IC verification environment.

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

These gaps are documented intentionally.

The project does not attempt to disguise incomplete areas as completed
verification.

---

# Verification Closure Philosophy

Verification closure is not defined as achieving an arbitrary percentage.

A block is considered closed only when:

1. the functional specification is defined;
2. verification scenarios are identified;
3. expected behavior is independently modeled;
4. self-checking mechanisms are active;
5. required functional coverage is exercised;
6. relevant assertions are evaluated;
7. regression stability is demonstrated;
8. code coverage is reviewed where applicable;
9. remaining exclusions are justified and documented.

This distinction is important because high code coverage does not
necessarily imply high functional confidence.

Similarly, a passing testbench does not constitute verification closure
without independent checking and coverage analysis.

---

# Repository Structure

```text
riscv_cpu_project/
│
├── rtl/
│   ├── alu.sv
│   ├── cu.sv
│   ├── cpu_core.sv
│   ├── fpu.sv
│   ├── fpu_add.sv
│   ├── fpu_sub.sv
│   ├── fpu_mul.sv
│   ├── fpu_div.sv
│   ├── mmu.sv
│   └── register_file.sv
│
├── tests/
│   ├── cpu_tb.sv
│   ├── fpu_tb.sv
│   ├── fpu_differential_tb.sv
│   ├── mmu_tb.sv
│   ├── mmu_coverage.sv
│   ├── register_file_tb.sv
│   ├── register_file_scoreboard.sv
│   ├── register_file_reference_model.sv
│   ├── register_file_assertions.sv
│   ├── register_file_coverage.sv
│   │
│   └── reference/
│       ├── generate_fpu_vectors.py
│       ├── generate_fpu_differential_vectors.py
│       ├── test_binary32.py
│       └── test_fpu_reference_model.py
│
├── reference/
│   ├── __init__.py
│   ├── binary32.py
│   ├── fpu_reference_model.py
│   └── scoreboard_bridge.py
│
├── uvm_tb/
│   ├── fpu_agent/
│   │   ├── fpu_pkg.sv
│   │   └── fpu_if.sv
│   ├── tb_top_fpu.sv
│   └── tests/
│       └── fpu_smoke_test.sv
│
├── formal/
│   └── alu/
│       ├── config.sby
│       └── src/
│           ├── alu_formal_assertions.sv
│           └── alu_formal_top.sv
│
├── docs/
│   └── fpu_ieee754_verification_matrix.md
│
├── run_sim.sh
├── run_regression.sh
├── verification_plan.md
└── README.md
```

---

# FPU Verification Contract

The FPU verification contract is documented separately in:

```text
docs/fpu_ieee754_verification_matrix.md
```

The document defines:

* supported binary32 behavior;
* partially supported behavior;
* unsupported behavior;
* out-of-scope behavior;
* verification scenarios;
* reference-model expectations;
* differential verification requirements;
* coverage expectations;
* closure criteria.

The document is the source of truth for the currently claimed FPU
verification subset.

The project explicitly makes **no full IEEE-754 compliance claim**.

If RTL behavior conflicts with a `SUPPORTED` matrix entry, the behavior is
treated as an implementation defect unless the architectural contract is
explicitly changed first.

---

# Reproducibility

The project is designed to be executable from the command line.

Typical flows include:

```bash
./run_sim.sh alu
./run_sim.sh cu
```

and seed-based regression:

```bash
./run_regression.sh <target> <num_seeds>
```

Python reference-model tests can be executed independently using the
project's Python environment.

The verification scripts are intended to make failures reproducible and to
provide a consistent foundation for future CI integration.

---

# Project Philosophy

This project intentionally prioritizes:

* verification quality;
* independence of checking;
* traceability;
* reproducibility;
* explicit scope;
* measurable coverage;
* documented limitations;
* defensible verification claims.

It does **not** prioritize artificially high coverage numbers or the number
of testbenches in the repository.

A reviewer should be able to determine:

* What was tested
* What was not tested
* How expected behavior was calculated
* Which properties were formally proven
* Which coverage bins were exercised
* Which tool limitations affected the methodology
* Which verification gaps remain
* What would be required for further closure

The objective is to demonstrate the engineering process used to drive a
design toward defensible verification closure.

---

# Summary

The project has evolved from a basic RTL simulation exercise into a
multi-layer Digital Verification Engineering portfolio.

The current methodology combines:

```text
UVM
Scoreboards
Reference Models
Differential Verification
Functional Coverage
Assertions
Formal Verification
Seed-Based Regression
Toolchain Analysis
```

The current focus is block-level verification and closure of the:

* FPU;
* MMU;
* Register File.

The ALU and Control Unit have reached the documented verification closure
level for their defined scope.

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
Measure Functional Coverage
     ↓
Run Assertions / Formal Checks
     ↓
Run Reproducible Regression
     ↓
Analyze Failures
     ↓
Drive Coverage Closure
     ↓
Document Remaining Gaps
```

This repository therefore presents both the verification infrastructure that
has been implemented and the limitations that remain.

