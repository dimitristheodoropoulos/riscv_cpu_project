# CPU Execution Core Formal Verification

## Scope

This document summarizes the formal verification activities related to
the CPU execution core and their relationship with simulation-based
verification.

It intentionally separates:

- block-level formal verification, which has been performed
- full CPU execution-core formal proof, which has **not** been performed

This distinction is important for verification closure reporting.

---

## Completed Formal Verification

### ALU Formal Proof

| Item | Value |
|---|---|
| Tool | SymbiYosys |
| Target | `alu` |
| Objective | Verify supported ALU operations against expected behavioral properties |
| Result | **PASS** — no counterexamples found |
| Notes | The proof is limited to supported ALU operations within the project scope |

The ALU formal proof provides block-level evidence for the correct
implementation of the supported arithmetic/logical operations.

### FPU Formal/SVA Verification

| Item | Value |
|---|---|
| Scope | FPU verification environment |
| Mechanism | SVA / formal verification |
| Status | Implemented and documented separately |

FPU formal/SVA evidence is outside the CPU execution core DUT hierarchy,
but demonstrates project-level formal verification experience.

---

## CPU Execution Core Formal Status

The following items have **not** been fully formally verified:

- Full CPU execution core (`cpu_exec_core`) formal proof
- End-to-end instruction-path formal verification
- x0 architectural invariant as a standalone formal property
- Cache/MMU interaction formal proof
- Full RV32I instruction-set formal coverage

The x0 invariant is currently enforced by the UVM monitor and stimulated
with directed sequences. It has not been duplicated as a standalone
formal assertion for the CPU execution core.

This is not a coverage gap for the current DUT scope; it is a documented
methodology boundary.

---

## Relationship to Simulation/UVM

The CPU execution core is verified using:

- UVM environment
- Directed stimulus
- Reference model
- Scoreboard
- Architectural checking
- RTL code coverage

Formal verification at the ALU level complements, but does not replace,
simulation-based verification.

The current verification strategy is therefore:

| Layer | Evidence |
|---|---|
| Block-level formal | ALU SymbiYosys proof |
| Block-level simulation | UVM + reference model + scoreboard |
| CPU execution simulation | Directed UVM tests + architectural checks |
| CPU execution RTL code coverage | Questa branch/condition/statement coverage |
| CPU execution full formal proof | Not currently claimed |

---

## Conclusion

The project currently provides:

- **Block-level formal verification** for the ALU
- **Simulation-based verification** for the CPU execution core
- **RTL code coverage closure** for the analyzed CPU execution DUT hierarchy

Full CPU execution-core formal verification is not claimed.

The verification evidence is scoped accordingly in the CPU execution
verification plan.