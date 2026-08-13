# FPU IEEE-754 Verification Matrix

**Project:** RISC-V CPU Verification Project
**Component:** Floating-Point Unit (FPU)
**ISA Context:** RV32I + project-specific FPU subset
**Precision:** IEEE-754 binary32 (single precision)
**Verification Strategy:** Reference-model-driven, directed corner cases, differential/random testing, assertions, regression and coverage

---

## 1. Purpose

This document defines the **verification contract** for the project's floating-point unit.

The purpose of this matrix is to establish, before implementation of the reference model and corner-case tests:

* which IEEE-754 binary32 behaviors are **SUPPORTED**;
* which behaviors are **UNSUPPORTED**;
* which behaviors are **PARTIALLY SUPPORTED**;
* which behaviors are intentionally **OUT OF SCOPE**;
* which scenarios must be verified;
* which scenarios require explicit RTL limitations to be documented.

This document is the **source of truth** for the FPU reference model and verification environment.

The verification environment must not silently assume IEEE-754 compliance for functionality that the RTL does not implement.

---

# 2. FPU Scope

The current FPU provides the following operations:

| Operation                     |   Opcode | RTL Module |
| ----------------------------- | -------: | ---------- |
| Floating-point addition       | `3'b000` | `fp_add`   |
| Floating-point subtraction    | `3'b001` | `fp_sub`   |
| Floating-point multiplication | `3'b010` | `fp_mul`   |
| Floating-point division       | `3'b011` | `fp_div`   |

The top-level FPU provides:

* operands `a` and `b`: 32-bit binary32 values;
* operation selector `op`;
* synchronous result update;
* `ready` indication.

The current project does **not** claim complete IEEE-754 implementation.

---

# 3. Status Definitions

| Status         | Meaning                                                                                |
| -------------- | -------------------------------------------------------------------------------------- |
| `SUPPORTED`    | Behavior is intentionally implemented and must be fully verified.                      |
| `PARTIAL`      | Some behavior is implemented, but the complete IEEE-754 requirement is not guaranteed. |
| `UNSUPPORTED`  | Behavior is outside the current RTL contract.                                          |
| `OUT_OF_SCOPE` | Not relevant to the current FPU architecture.                                          |
| `TBD`          | Requires an explicit architectural decision before verification.                       |

A test must not be marked PASS merely because the RTL produces a numerically plausible result.

For `SUPPORTED` behavior, the expected result must be derived independently from the RTL.

---

# 4. Supported Floating-Point Specification

## 4.1 Supported data format

The FPU operates on:

**IEEE-754 binary32**

Format:

```text
31          30      23 22                    0
+-------------+---------+----------------------+
| Sign        | Exponent| Fraction             |
| 1 bit       | 8 bits  | 23 bits              |
+-------------+---------+----------------------+
```

Bias:

```text
127
```

---

# 5. Architectural Support Classification

## 5.1 Binary32 categories

| IEEE-754 Category          | Status        | Notes                                                     |
| -------------------------- | ------------- | --------------------------------------------------------- |
| Positive zero              | `SUPPORTED`   | Required                                                  |
| Negative zero              | `PARTIAL`     | Bit-level handling requires explicit verification         |
| Positive normal numbers    | `SUPPORTED`   | Required                                                  |
| Negative normal numbers    | `SUPPORTED`   | Required                                                  |
| Positive subnormal numbers | `PARTIAL`     | Basic handling exists; full IEEE semantics not guaranteed |
| Negative subnormal numbers | `PARTIAL`     | Basic handling exists; full IEEE semantics not guaranteed |
| Positive infinity          | `PARTIAL`     | Division by zero produces infinity                        |
| Negative infinity          | `PARTIAL`     | Sign propagation exists for division                      |
| NaN                        | `UNSUPPORTED` | No complete NaN semantics                                 |
| Signaling NaN              | `UNSUPPORTED` | Not implemented                                           |
| Quiet NaN                  | `UNSUPPORTED` | Not implemented                                           |

---

# 6. IEEE-754 Features

| Feature                | Status        | Verification Requirement                     |
| ---------------------- | ------------- | -------------------------------------------- |
| Binary32 encoding      | `SUPPORTED`   | Verify sign/exponent/fraction interpretation |
| Normalized numbers     | `SUPPORTED`   | Full operation matrix                        |
| Zero                   | `SUPPORTED`   | ADD/SUB/MUL/DIV                              |
| Subnormal numbers      | `PARTIAL`     | Directed tests                               |
| Infinity               | `PARTIAL`     | Explicitly test supported cases              |
| NaN propagation        | `UNSUPPORTED` | Must not be claimed                          |
| Signaling NaN          | `UNSUPPORTED` | No verification required                     |
| Quiet NaN              | `UNSUPPORTED` | No verification required                     |
| Guard bits             | `UNSUPPORTED` | Not architecturally implemented              |
| Round-to-nearest-even  | `UNSUPPORTED` | No complete rounding unit                    |
| Toward zero            | `UNSUPPORTED` | Not implemented                              |
| Toward +infinity       | `UNSUPPORTED` | Not implemented                              |
| Toward -infinity       | `UNSUPPORTED` | Not implemented                              |
| Exception flags        | `UNSUPPORTED` | No exception-status interface                |
| Invalid operation flag | `UNSUPPORTED` | Not implemented                              |
| Divide-by-zero flag    | `UNSUPPORTED` | Not implemented                              |
| Overflow flag          | `UNSUPPORTED` | Not implemented                              |
| Underflow flag         | `UNSUPPORTED` | Not implemented                              |
| Inexact flag           | `UNSUPPORTED` | Not implemented                              |
| Fused multiply-add     | `UNSUPPORTED` | No FMA operation                             |
| Comparison operations  | `UNSUPPORTED` | No comparison opcode                         |
| Conversion operations  | `UNSUPPORTED` | No conversion opcode                         |

---

# 7. Operation Verification Matrix

---

# 7.1 ADD

## Normal Numbers

| ID        | Scenario             | Expected Behavior         | Status      |
| --------- | -------------------- | ------------------------- | ----------- |
| ADD-N-001 | positive + positive  | Correct binary32 result   | `SUPPORTED` |
| ADD-N-002 | negative + negative  | Correct binary32 result   | `SUPPORTED` |
| ADD-N-003 | positive + negative  | Magnitude subtraction     | `SUPPORTED` |
| ADD-N-004 | negative + positive  | Magnitude subtraction     | `SUPPORTED` |
| ADD-N-005 | equal exponents      | Correct mantissa addition | `SUPPORTED` |
| ADD-N-006 | `exp_a < exp_b`      | Correct alignment         | `SUPPORTED` |
| ADD-N-007 | `exp_a > exp_b`      | Correct alignment         | `SUPPORTED` |
| ADD-N-008 | mantissa carry       | Exponent increment        | `SUPPORTED` |
| ADD-N-009 | no mantissa carry    | Normal result             | `SUPPORTED` |
| ADD-N-010 | exact cancellation   | Zero result               | `SUPPORTED` |
| ADD-N-011 | different magnitudes | Correct dominant operand  | `SUPPORTED` |
| ADD-N-012 | opposite signs       | Correct sign selection    | `SUPPORTED` |

## Zero

| ID        | Scenario        | Expected Behavior            | Status      |
| --------- | --------------- | ---------------------------- | ----------- |
| ADD-Z-001 | `+0 + +0`       | `+0`                         | `SUPPORTED` |
| ADD-Z-002 | `+0 + positive` | positive operand             | `SUPPORTED` |
| ADD-Z-003 | positive + `+0` | positive operand             | `SUPPORTED` |
| ADD-Z-004 | `+0 + negative` | negative operand             | `SUPPORTED` |
| ADD-Z-005 | negative + `+0` | negative operand             | `SUPPORTED` |
| ADD-Z-006 | `-0 + +0`       | IEEE sign semantics          | `PARTIAL`   |
| ADD-Z-007 | `+0 + -0`       | IEEE sign semantics          | `PARTIAL`   |
| ADD-Z-008 | `-0 + -0`       | `-0` according to IEEE rules | `PARTIAL`   |

## Subnormal

| ID        | Scenario                                | Status    |
| --------- | --------------------------------------- | --------- |
| ADD-S-001 | subnormal + subnormal                   | `PARTIAL` |
| ADD-S-002 | smallest subnormal + smallest subnormal | `PARTIAL` |
| ADD-S-003 | largest subnormal + smallest subnormal  | `PARTIAL` |
| ADD-S-004 | normal + subnormal                      | `PARTIAL` |
| ADD-S-005 | subnormal + normal                      | `PARTIAL` |
| ADD-S-006 | opposite-sign subnormal cancellation    | `PARTIAL` |
| ADD-S-007 | subnormal → normal transition           | `PARTIAL` |

## Overflow / Underflow

| ID        | Scenario                        | Status    |
| --------- | ------------------------------- | --------- |
| ADD-O-001 | maximum finite + maximum finite | `PARTIAL` |
| ADD-O-002 | positive overflow               | `PARTIAL` |
| ADD-O-003 | negative overflow               | `PARTIAL` |
| ADD-O-004 | result becomes subnormal        | `PARTIAL` |
| ADD-O-005 | result underflows               | `PARTIAL` |

## Infinity / NaN

| ID        | Scenario        | Status        |
| --------- | --------------- | ------------- |
| ADD-I-001 | `+inf + finite` | `PARTIAL`     |
| ADD-I-002 | `-inf + finite` | `PARTIAL`     |
| ADD-I-003 | `+inf + +inf`   | `PARTIAL`     |
| ADD-I-004 | `+inf + -inf`   | `UNSUPPORTED` |
| ADD-I-005 | finite + NaN    | `UNSUPPORTED` |
| ADD-I-006 | NaN + finite    | `UNSUPPORTED` |
| ADD-I-007 | NaN + NaN       | `UNSUPPORTED` |

---

# 7.2 SUB

`SUB` is implemented architecturally as:

```text
A - B = A + (-B)
```

Therefore the majority of arithmetic behavior is delegated to `fp_add`.

## Normal Numbers

| ID        | Scenario              | Status      |
| --------- | --------------------- | ----------- |
| SUB-N-001 | positive - positive   | `SUPPORTED` |
| SUB-N-002 | negative - negative   | `SUPPORTED` |
| SUB-N-003 | positive - negative   | `SUPPORTED` |
| SUB-N-004 | negative - positive   | `SUPPORTED` |
| SUB-N-005 | equal operands        | `SUPPORTED` |
| SUB-N-006 | exponent alignment    | `SUPPORTED` |
| SUB-N-007 | mantissa cancellation | `SUPPORTED` |
| SUB-N-008 | magnitude `A > B`     | `SUPPORTED` |
| SUB-N-009 | magnitude `A < B`     | `SUPPORTED` |

## Zero

| ID        | Scenario      | Status      |
| --------- | ------------- | ----------- |
| SUB-Z-001 | `3.0 - 0.0`   | `SUPPORTED` |
| SUB-Z-002 | `0.0 - 3.0`   | `SUPPORTED` |
| SUB-Z-003 | `0.0 - 0.0`   | `SUPPORTED` |
| SUB-Z-004 | `-0.0 - 0.0`  | `PARTIAL`   |
| SUB-Z-005 | `0.0 - -0.0`  | `PARTIAL`   |
| SUB-Z-006 | `-0.0 - -0.0` | `PARTIAL`   |

## Subnormal

| ID        | Scenario                      | Status    |
| --------- | ----------------------------- | --------- |
| SUB-S-001 | subnormal - subnormal         | `PARTIAL` |
| SUB-S-002 | normal - subnormal            | `PARTIAL` |
| SUB-S-003 | subnormal - normal            | `PARTIAL` |
| SUB-S-004 | exact subnormal cancellation  | `PARTIAL` |
| SUB-S-005 | subnormal → normal transition | `PARTIAL` |

## Infinity / NaN

| ID        | Scenario        | Status        |
| --------- | --------------- | ------------- |
| SUB-I-001 | finite - `+inf` | `PARTIAL`     |
| SUB-I-002 | finite - `-inf` | `PARTIAL`     |
| SUB-I-003 | `+inf - +inf`   | `UNSUPPORTED` |
| SUB-I-004 | `+inf - -inf`   | `UNSUPPORTED` |
| SUB-I-005 | NaN operand     | `UNSUPPORTED` |

---

# 7.3 MUL

## Normal Numbers

| ID        | Scenario                 | Status      |
| --------- | ------------------------ | ----------- |
| MUL-N-001 | positive × positive      | `SUPPORTED` |
| MUL-N-002 | positive × negative      | `SUPPORTED` |
| MUL-N-003 | negative × positive      | `SUPPORTED` |
| MUL-N-004 | negative × negative      | `SUPPORTED` |
| MUL-N-005 | mantissa product MSB = 0 | `SUPPORTED` |
| MUL-N-006 | mantissa product MSB = 1 | `SUPPORTED` |
| MUL-N-007 | exponent increment       | `SUPPORTED` |
| MUL-N-008 | exponent decrement       | `SUPPORTED` |

## Zero

| ID        | Scenario        | Status      |
| --------- | --------------- | ----------- |
| MUL-Z-001 | positive × zero | `SUPPORTED` |
| MUL-Z-002 | zero × positive | `SUPPORTED` |
| MUL-Z-003 | negative × zero | `SUPPORTED` |
| MUL-Z-004 | zero × negative | `SUPPORTED` |
| MUL-Z-005 | zero × zero     | `SUPPORTED` |
| MUL-Z-006 | `-0 × -0`       | `PARTIAL`   |

## Subnormal

| ID        | Scenario              | Status    |
| --------- | --------------------- | --------- |
| MUL-S-001 | subnormal × normal    | `PARTIAL` |
| MUL-S-002 | normal × subnormal    | `PARTIAL` |
| MUL-S-003 | subnormal × subnormal | `PARTIAL` |
| MUL-S-004 | underflow to zero     | `PARTIAL` |
| MUL-S-005 | subnormal result      | `PARTIAL` |

## Overflow / Underflow

| ID        | Scenario                        | Status    |
| --------- | ------------------------------- | --------- |
| MUL-O-001 | maximum finite × maximum finite | `PARTIAL` |
| MUL-O-002 | positive overflow               | `PARTIAL` |
| MUL-O-003 | negative overflow               | `PARTIAL` |
| MUL-O-004 | very small operands             | `PARTIAL` |
| MUL-O-005 | underflow                       | `PARTIAL` |

## Infinity / NaN

| ID        | Scenario            | Status        |
| --------- | ------------------- | ------------- |
| MUL-I-001 | infinity × finite   | `PARTIAL`     |
| MUL-I-002 | infinity × zero     | `UNSUPPORTED` |
| MUL-I-003 | infinity × infinity | `PARTIAL`     |
| MUL-I-004 | NaN × finite        | `UNSUPPORTED` |
| MUL-I-005 | NaN × NaN           | `UNSUPPORTED` |

---

# 7.4 DIV

## Normal Numbers

| ID        | Scenario               | Status      |
| --------- | ---------------------- | ----------- |
| DIV-N-001 | positive / positive    | `SUPPORTED` |
| DIV-N-002 | positive / negative    | `SUPPORTED` |
| DIV-N-003 | negative / positive    | `SUPPORTED` |
| DIV-N-004 | negative / negative    | `SUPPORTED` |
| DIV-N-005 | equal operands         | `SUPPORTED` |
| DIV-N-006 | quotient ≥ 1           | `SUPPORTED` |
| DIV-N-007 | quotient < 1           | `SUPPORTED` |
| DIV-N-008 | exponent adjustment    | `SUPPORTED` |
| DIV-N-009 | mantissa normalization | `SUPPORTED` |

## Zero

| ID        | Scenario        | Status        |
| --------- | --------------- | ------------- |
| DIV-Z-001 | zero / positive | `SUPPORTED`   |
| DIV-Z-002 | zero / negative | `SUPPORTED`   |
| DIV-Z-003 | positive / zero | `SUPPORTED`   |
| DIV-Z-004 | negative / zero | `SUPPORTED`   |
| DIV-Z-005 | zero / zero     | `UNSUPPORTED` |

Current RTL behavior for non-zero numerator divided by zero:

```text
sign = sign_a XOR sign_b
exponent = 0xFF
fraction = 0
```

This represents infinity.

However, the IEEE-754 exception semantics are not implemented.

## Subnormal

| ID        | Scenario                 | Status    |
| --------- | ------------------------ | --------- |
| DIV-S-001 | subnormal / normal       | `PARTIAL` |
| DIV-S-002 | normal / subnormal       | `PARTIAL` |
| DIV-S-003 | subnormal / subnormal    | `PARTIAL` |
| DIV-S-004 | result becomes subnormal | `PARTIAL` |
| DIV-S-005 | result underflows        | `PARTIAL` |

## Infinity / NaN

| ID        | Scenario            | Status        |
| --------- | ------------------- | ------------- |
| DIV-I-001 | finite / infinity   | `UNSUPPORTED` |
| DIV-I-002 | infinity / finite   | `UNSUPPORTED` |
| DIV-I-003 | infinity / infinity | `UNSUPPORTED` |
| DIV-I-004 | zero / zero         | `UNSUPPORTED` |
| DIV-I-005 | NaN / finite        | `UNSUPPORTED` |
| DIV-I-006 | finite / NaN        | `UNSUPPORTED` |
| DIV-I-007 | NaN / NaN           | `UNSUPPORTED` |

---

# 8. Rounding

The current FPU does not expose an IEEE-754 rounding-mode interface.

Therefore:

| Feature                        | Status        |
| ------------------------------ | ------------- |
| Round-to-nearest-even          | `UNSUPPORTED` |
| Round-toward-zero              | `UNSUPPORTED` |
| Round-toward-positive-infinity | `UNSUPPORTED` |
| Round-toward-negative-infinity | `UNSUPPORTED` |

The verification environment must therefore **not claim IEEE-754 rounding compliance**.

Tests involving discarded low-order bits should be classified as:

```text
PARTIAL
```

until the architectural rounding policy is explicitly defined.

---

# 9. Exception Handling

No IEEE-754 exception flags are currently exposed.

| Exception         | Status                  |
| ----------------- | ----------------------- |
| Invalid Operation | `UNSUPPORTED`           |
| Divide by Zero    | `UNSUPPORTED` as a flag |
| Overflow          | `UNSUPPORTED` as a flag |
| Underflow         | `UNSUPPORTED` as a flag |
| Inexact           | `UNSUPPORTED`           |

The absence of an exception flag does not necessarily prevent the RTL from producing a mathematically useful result.

It means that **IEEE-754 exception reporting is outside the current contract**.

---

# 10. NaN Policy

NaN handling is explicitly outside the current supported subset.

The following are not required to pass:

```text
NaN + X
NaN - X
NaN * X
NaN / X

X + NaN
X - NaN
X * NaN
X / NaN
```

Likewise:

```text
NaN + NaN
NaN - NaN
NaN * NaN
NaN / NaN
```

are unsupported.

The reference model must classify these cases as:

```text
UNSUPPORTED
```

rather than generating a false PASS/FAIL result.

---

# 11. Infinity Policy

Infinity handling is only partially supported.

The current RTL explicitly implements infinity generation for division by zero:

```text
finite / ±0 → ±Infinity
```

Other infinity operations are not part of the supported contract unless verified and explicitly promoted to `SUPPORTED`.

Therefore:

```text
finite / zero
```

is a supported verification scenario.

The broader IEEE-754 infinity algebra remains:

```text
PARTIAL
```

or

```text
UNSUPPORTED
```

depending on the operation.

---

# 12. Negative Zero Policy

Negative zero is a special architectural corner case.

The current RTL contains explicit zero handling such as:

```systemverilog
if (a == 32'h00000000)
```

which treats `+0` and `-0` according to Verilog equality semantics.

Therefore complete IEEE-754 signed-zero semantics are **not currently guaranteed**.

Classification:

```text
PARTIAL
```

The verification environment must explicitly test negative zero and record actual RTL behavior.

---

# 13. Subnormal Policy

Subnormal support is considered:

```text
PARTIAL
```

The RTL contains explicit logic for:

* zero exponent;
* missing implicit leading `1`;
* effective exponent handling;
* subnormal result generation;
* normalization toward the smallest normal representation.

However, complete IEEE-754 subnormal behavior also depends on:

* correct rounding;
* underflow semantics;
* exact sticky/guard behavior;
* exception reporting.

Those mechanisms are not implemented.

Therefore the project must not claim full subnormal IEEE-754 compliance.

---

# 14. Reference Model Requirements

The reference model must be independent from the implementation structure of the RTL.

It must **not** reproduce the same algorithm as:

```text
fp_add
fp_sub
fp_mul
fp_div
```

because doing so would risk reproducing the same RTL bug.

The reference model should instead:

1. Decode binary32 operands.
2. Classify each operand.
3. Check whether the test case is within the supported contract.
4. Compute the expected mathematical result independently.
5. Encode the result into binary32.
6. Compare against RTL output.
7. Report:

   * PASS;
   * FAIL;
   * UNSUPPORTED;
   * PARTIAL.

---

# 15. Test Classification

Every reference-model transaction should have one of the following statuses:

```text
SUPPORTED
PARTIAL
UNSUPPORTED
```

Example:

```text
ADD-N-001
A = 2.0
B = 3.0
Expected = 5.0
Status = SUPPORTED
```

Example:

```text
ADD-I-005
A = NaN
B = 1.0
Status = UNSUPPORTED
```

Example:

```text
ADD-S-003
A = largest subnormal
B = smallest subnormal
Status = PARTIAL
```

---

# 16. Directed Corner-Case Test Requirements

The directed test suite must contain at minimum:

## ADD

* positive + positive;
* negative + negative;
* positive + negative;
* negative + positive;
* zero operands;
* exponent mismatch;
* equal exponents;
* mantissa carry;
* exact cancellation;
* subnormal operands;
* subnormal result;
* maximum finite operands;
* overflow boundary.

## SUB

* positive - positive;
* negative - negative;
* positive - negative;
* negative - positive;
* zero operands;
* equal operands;
* cancellation;
* exponent mismatch;
* subnormal operands;
* underflow boundary.

## MUL

* positive × positive;
* positive × negative;
* negative × positive;
* negative × negative;
* zero;
* smallest normal;
* largest normal;
* subnormal operands;
* overflow;
* underflow;
* mantissa normalization.

## DIV

* positive / positive;
* positive / negative;
* negative / positive;
* negative / negative;
* zero numerator;
* zero denominator;
* zero / zero;
* equal operands;
* quotient < 1;
* quotient ≥ 1;
* subnormal operands;
* overflow;
* underflow;
* infinity generation.

---

# 17. Differential Testing

After the directed suite is established, differential/random testing should generate binary32 operands from the following classes:

```text
ZERO
NEG_ZERO
NORMAL_SMALL
NORMAL_MEDIUM
NORMAL_LARGE
MIN_NORMAL
MAX_NORMAL
SUBNORMAL_SMALL
SUBNORMAL_LARGE
POS_INFINITY
NEG_INFINITY
QNaN
SNaN
```

However, unsupported classes must not be used to claim compliance.

For the first supported-subset regression, random testing should focus on:

```text
ZERO
NORMAL_SMALL
NORMAL_MEDIUM
NORMAL_LARGE
MIN_NORMAL
MAX_NORMAL
SUBNORMAL
```

with unsupported categories separately tracked.

---

# 18. Coverage Goals

Coverage must be interpreted against the **verification contract**, not against an arbitrary percentage.

The target is:

```text
100% coverage of SUPPORTED verification scenarios
```

rather than:

```text
100% coverage of every possible IEEE-754 behavior
```

Functional coverage should eventually include:

* operation;
* sign combination;
* zero/non-zero;
* exponent relationship;
* mantissa relationship;
* normal/subnormal classification;
* overflow boundary;
* underflow boundary;
* division-by-zero;
* normalization path;
* cancellation path.

Code coverage remains useful as a secondary metric.

---

# 19. Current Coverage Interpretation

The current FPU RTL has demonstrated strong structural branch coverage in the exercised modules.

Current observations include:

```text
fp_add   : 100% branch coverage
fp_mul   : 100% branch coverage
fp_div   : 100% branch coverage
fpu      : 100% branch coverage
```

This does **not** imply IEEE-754 compliance.

Structural coverage answers:

> "Did the simulation execute the RTL branches?"

The verification matrix answers:

> "Did we verify the required architectural behaviors?"

The latter is the primary goal.

---

# 20. Verification Completion Criteria

The FPU verification effort will be considered complete for the current project scope when:

### Functional

* [ ] All `SUPPORTED` matrix entries have directed tests.
* [ ] All `SUPPORTED` entries pass the independent reference model.
* [ ] All supported operation/sign combinations are exercised.
* [ ] Zero behavior is verified.
* [ ] Normal-number arithmetic is verified.
* [ ] Supported subnormal behavior is verified.
* [ ] Supported division-by-zero behavior is verified.

### Reference Model

* [ ] Independent binary32 reference model implemented.
* [ ] Reference model does not replicate RTL algorithms.
* [ ] Unsupported cases are explicitly classified.
* [ ] Partial cases are explicitly classified.

### Random / Differential

* [ ] Random binary32 generation implemented.
* [ ] Supported cases compared against reference model.
* [ ] Mismatch diagnostics implemented.
* [ ] Seed reproducibility implemented.

### Assertions

* [ ] FPU protocol assertions.
* [ ] `ready` behavior assertions.
* [ ] Result stability assertions where applicable.
* [ ] Illegal opcode behavior assertion.
* [ ] Basic arithmetic invariants where practical.

### Regression

* [ ] FPU directed tests integrated into regression.
* [ ] Random/differential tests integrated.
* [ ] Regression is reproducible by seed.
* [ ] Failure artifacts are preserved.

### Coverage

* [ ] Supported functional coverage reaches target.
* [ ] Code coverage analyzed.
* [ ] Uncovered supported scenarios identified.
* [ ] Unsupported behavior excluded from compliance metrics.

### Documentation

* [ ] Supported IEEE-754 subset documented.
* [ ] Unsupported features documented.
* [ ] Known limitations documented.
* [ ] Verification results documented.

---

# 21. Known Architectural Limitations

The current FPU should **not** be described as a complete IEEE-754 implementation.

Known limitations include:

1. No complete NaN handling.
2. No complete infinity arithmetic.
3. No IEEE-754 exception flags.
4. No configurable rounding modes.
5. No explicit guard/round/sticky implementation.
6. Subnormal handling is only partial.
7. Negative-zero semantics are only partially defined.
8. No fused multiply-add.
9. No floating-point comparison operations.
10. No floating-point conversion operations.
11. No complete IEEE-754 exception semantics.
12. No formal claim of IEEE-754 compliance.

These limitations are intentional for the current project scope.

---

# 22. Project-Level Compliance Statement

The project currently targets:

> **A verified RV32I-oriented binary32 floating-point subset, not a complete IEEE-754 implementation.**

The verification objective is therefore:

```text
High confidence in the explicitly supported binary32 arithmetic subset
```

rather than:

```text
Claim of complete IEEE-754 compliance
```

This distinction is intentional and should remain visible in project documentation.

---

# 23. Verification Roadmap

The verification workflow derived from this matrix is:

```text
1. IEEE-754 verification matrix
             ↓
2. Independent reference model
             ↓
3. Directed corner-case tests
             ↓
4. Differential / random testing
             ↓
5. Assertions
             ↓
6. Regression integration
             ↓
7. Coverage analysis
             ↓
8. Identify actual RTL failures
             ↓
9. Fix RTL
             ↓
10. Re-run regression
             ↓
11. Re-measure coverage
             ↓
12. Document supported IEEE-754 subset
```

Coverage is intentionally placed **after functional verification**, because coverage must measure the quality of verification rather than determine what the tests should be.

---

# 24. Source-of-Truth Rule

This document is the authoritative verification specification for the current FPU.

The following artifacts must derive their expected behavior from this matrix:

```text
reference model
      ↓
directed tests
      ↓
random constraints
      ↓
functional coverage
      ↓
assertions
      ↓
regression classification
      ↓
verification report
```

The implementation must **not** redefine the verification requirements.

If the RTL behavior conflicts with a `SUPPORTED` matrix entry:

```text
RTL behavior = implementation defect
```

and not:

```text
verification expectation = wrong
```

unless the architecture is explicitly changed and this document is updated first.

---

# 25. Next Step

The independent Python reference-model infrastructure has now been
implemented in:

```text
reference/binary32.py
reference/fpu_reference_model.py
reference/scoreboard_bridge.py
```

The FPU differential verification environment is implemented in:

```text
tests/fpu_differential_tb.sv
```

The next verification step is therefore verification closure of the
SUPPORTED FPU subset through:

1. Reference-model unit testing
2. Directed RTL/reference differential testing
3. Randomized differential testing
4. IEEE-754 corner-case expansion
5. Functional coverage measurement
6. Investigation and correction of RTL/reference mismatches
7. Multi-seed regression
8. Coverage-driven closure

The FPU remains classified as actively verified until the defined SUPPORTED
scenarios satisfy the project's verification closure criteria.

---

**Document status:** Verification contract — implemented reference-model flow
**Scope:** RV32I project-specific binary32 FPU subset
**Compliance claim:** No full IEEE-754 compliance claim
