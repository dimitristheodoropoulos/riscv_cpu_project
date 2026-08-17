# FPU RTL Coverage Waiver Report

## 1. Summary

This report documents the FPU RTL coverage closure.

The result is **not claimed as unconditional 100% coverage**.  
Coverage is reported separately for observed RTL coverage and for reachable  
RTL behavior after formally or mathematically justified waivers.

The correct statements are:

> **100% reachable RTL branch coverage**,  
> with **6 mathematically/formally justified unreachable branch outcomes**  
> that are waived.

> **100% reachable RTL condition coverage**,  
> with **13 structurally/mathematically unreachable condition coverage  
> misses** that are waived.

> **100% reachable RTL statement coverage**,  
> with **17 structurally/mathematically/formally justified unreachable  
> statements** that are waived.

Of the six branch waivers:

- the three MUL invariants are additionally supported by a successful  
  SymbiYosys/Boolector formal proof;
- the three DIV waivers are supported by RTL-derived mathematical range  
  proofs; the corresponding full-DUT formal proof is currently blocked by  
  a Yosys limitation on the variable-bound loop at `fpu_div.sv:387`.

The waived branch outcomes, condition coverage misses, and statements are  
justified as unreachable by RTL datapath range proofs, control-flow/data  
dependency analysis, and, for the MUL invariants, formal verification.

---

## 2. Branch Coverage Summary

| RTL instance                    | Branch bins | Covered | Misses | Coverage |
| ------------------------------- | ----------: | ------: | -----: | -------: |
| `/tb_top_fpu/dut/add_op`        |          52 |      52 |      0 | 100.00%  |
| `/tb_top_fpu/dut/sub_op/add_op` |          52 |      52 |      0 | 100.00%  |
| `/tb_top_fpu/dut/mul_op`        |          41 |      38 |      3 |  92.68%  |
| `/tb_top_fpu/dut/div_op`        |          31 |      28 |      3 |  90.32%  |
| `/tb_top_fpu/dut`               |           7 |       7 |      0 | 100.00%  |
| **Total RTL DUT**               |     **183** | **177**  | **6**   | **96.72%** |

After excluding the 6 justified unreachable outcomes:

```text
177 / 177 = 100% reachable RTL branch coverage
```

### Critical SUB branch evidence

```text
fpu_add.sv:419/432 : 2/2 branches = 100.00%
fpu_add.sv:426     : 2/2 branches = 100.00%
```

---

## 3. Branch Waiver Summary

| RTL line          | Condition                       | Missing outcome | Proof summary                                      |
| ----------------- | ------------------------------- | --------------- | -------------------------------------------------- |
| `fpu_mul.sv:525`  | `subnormal_shift > 0`           | false           | `subnormal_shift >= 25` (formal PASS)              |
| `fpu_mul.sv:539`  | `subnormal_shift >= 2`          | false           | `subnormal_shift >= 25` (formal PASS)              |
| `fpu_mul.sv:551`  | `subnormal_shift >= 3`          | false           | `subnormal_shift >= 25` (formal PASS)              |
| `fpu_div.sv:305`  | `sig_rounded[24] == 1`          | true            | `Qmax < 0x1FFFFFF00`                               |
| `fpu_div.sv:402`  | `shift_cnt == 1`                | true            | `shift_cnt >= 10` (math proof only; formal blocked) |
| `fpu_div.sv:424`  | final `else`                    | unreachable path (`shift_cnt <= 0`) | `shift_cnt >= 10`; all reachable subnormal cases satisfy `shift_cnt >= 10` |

---

## 4. Mathematical Proofs

### 4.1 MUL — false branches of the `subnormal_shift` checks

In the subnormal-result path:

```text
exp_product < -126
exp_product <= -127

subnormal_shift = -exp_product - 102
                >= 127 - 102
                = 25
```

Therefore:

```text
subnormal_shift > 0   -> always true
subnormal_shift >= 2  -> always true
subnormal_shift >= 3  -> always true
```

The false outcomes of:

- `fpu_mul.sv:525`
- `fpu_mul.sv:539`
- `fpu_mul.sv:551`

are **unreachable**.

---

### 4.2 DIV — `sig_rounded[24] == 1`

In the normal-result path:

```text
quotient = floor(sig_a * 2^32 / sig_b)
```

For normalized binary32 significands:

```text
2^23 <= sig_a <= 2^24 - 1
2^23 <= sig_b <= 2^24 - 1
```

Therefore the maximum possible quotient is obtained for:

```text
sig_a = 0xFFFFFF
sig_b = 0x800000
```

giving:

```text
Qmax
  = floor(0xFFFFFF * 2^32 / 0x800000)
  = 0xFFFFFF * 2^9
  = 0x1FFFFFE00
```

For `sig_rounded[24]` to become `1`, the pre-rounded significand must be:

```text
sig_raw = 0xFFFFFF
```

and the rounding increment must be asserted.

Since:

```text
sig_raw = quotient[32:9]
guard   = quotient[8]
```

a carry-producing rounding case requires:

```text
quotient >= (0xFFFFFF << 9) + 0x100
         = 0x1FFFFFF00
```

But:

```text
Qmax = 0x1FFFFFE00
     < 0x1FFFFFF00
```

Therefore the required carry-producing quotient is outside the reachable
quotient range.

Hence:

```text
sig_rounded[24] == 1
```

is unreachable.

---

### 4.3 DIV — `shift_cnt == 1` and final `else`

Within the subnormal-result path (`exp_unbiased < -126`):

```text
exp_unbiased <= -127

shift_cnt = 32 - 149 - exp_unbiased
          = -117 - exp_unbiased

shift_cnt >= -117 + 127 = 10
```

Therefore, within this path:

```text
shift_cnt == 1  -> unreachable
shift_cnt <= 0  -> unreachable
```

Thus:

- `fpu_div.sv:402` — `else if (shift_cnt == 1)`
- `fpu_div.sv:424` — final `else`

are **unreachable**.

---

### 4.4 Formal Verification Evidence

| Waiver target                | Method                              | Result                                                                          |
| ---------------------------- | ----------------------------------- | ------------------------------------------------------------------------------- |
| MUL `subnormal_shift >= 25`  | SymbiYosys / Boolector `mode prove` | **PASS** — invariant proven by k-induction                                      |
| DIV `shift_cnt >= 10`        | Mathematical range proof            | **Mathematically proven**                                                       |
| DIV full-DUT formal proof    | SymbiYosys / Boolector `mode prove` | **BLOCKED** — `fpu_div.sv:387` non-constant loop bound                          |

---

## 5. Condition Coverage Status

### 5.1 Coverage summary

| RTL instance                    | Conditions | Covered | Misses | Coverage |
| ------------------------------- | ---------: | ------: | -----: | -------: |
| `/tb_top_fpu/dut/add_op`        |         39 |      35 |      4 |  89.74%  |
| `/tb_top_fpu/dut/sub_op/add_op` |         39 |      35 |      4 |  89.74%  |
| `/tb_top_fpu/dut/mul_op`        |         21 |      18 |      3 |  85.71%  |
| `/tb_top_fpu/dut/div_op`        |         14 |      12 |      2 |  85.71%  |
| **Total RTL DUT**               |    **113** | **100** | **13**   | **88.50%** |

After excluding the 13 structurally/mathematically unreachable condition
coverage misses:

```text
100 / 100 = 100% reachable RTL condition coverage
```

### 5.2 Condition waiver details

| Instance | RTL line | Condition | Missing condition coverage | Reason |
|---|---|---|---|---|
| `add_op` | 196 | `(((exp_a == 255) && (frac_a == 0)) && (exp_b == 255)) && (frac_b == 0)` | `(frac_a == 0)_0`, `(frac_b == 0)_0` | If `exp_a == 255` and `frac_a != 0`, the preceding NaN branch exits; likewise for operand B. Therefore the false terms are unreachable here. |
| `add_op` | 214 | `(exp_a == 255) && (frac_a == 0)` | `(frac_a == 0)_0` | If `exp_a == 255` and `frac_a != 0`, the preceding NaN branch exits. Therefore the false term is unreachable here. |
| `add_op` | 220 | `(exp_b == 255) && (frac_b == 0)` | `(frac_b == 0)_0` | If `exp_b == 255` and `frac_b != 0`, the preceding NaN branch exits. Therefore the false term is unreachable here. |
| `sub_op/add_op` | 196 | same as above | `(frac_a == 0)_0`, `(frac_b == 0)_0` | same |
| `sub_op/add_op` | 214 | same | `(frac_a == 0)_0` | same |
| `sub_op/add_op` | 220 | same | `(frac_b == 0)_0` | same |
| `mul_op` | 525 | `subnormal_shift > 0` | `(subnormal_shift > 0)_0` | `subnormal_shift >= 25` |
| `mul_op` | 539 | `subnormal_shift >= 2` | `(subnormal_shift >= 2)_0` | `subnormal_shift >= 25` |
| `mul_op` | 551 | `subnormal_shift >= 3` | `(subnormal_shift >= 3)_0` | `subnormal_shift >= 25` |
| `div_op` | 370 | `shift_cnt >= 2` | `(shift_cnt >= 2)_0` | `shift_cnt >= 10` |
| `div_op` | 402 | `shift_cnt == 1` | one missed condition coverage bin; both FEC rows unhit because condition never executes | `shift_cnt >= 10` |

> **Note for `fpu_div.sv:402`:** Questa reports both true and false FEC rows
> as unhit because the condition is never executed. The condition metric
> counts this as **one missed condition coverage bin** (`0 of 1`).

All reachable RTL condition coverage bins have been covered by directed  
witness vectors. The remaining 13 missed condition coverage bins are  
structurally/mathematically unreachable and are waived.

---

## 6. Statement Coverage Status

| RTL instance                    | Statements | Hits | Misses | Coverage |
| ------------------------------- | ---------: | ---: | -----: | -------: |
| `/tb_top_fpu/dut/add_op`        |         83 |   83 |      0 | 100.00%  |
| `/tb_top_fpu/dut/sub_op/add_op` |         83 |   83 |      0 | 100.00%  |
| `/tb_top_fpu/dut/mul_op`        |         96 |   90 |      6 |  93.75%  |
| `/tb_top_fpu/dut/div_op`        |         96 |   85 |     11 |  88.54%  |
| `/tb_top_fpu/dut`               |          9 |    9 |      0 | 100.00%  |
| **Total RTL DUT**               |    **367** | **350** | **17**   | **95.37%** |

After excluding the 17 justified unreachable statements:

```text
350 / 350 = 100% reachable RTL statement coverage
```

### 6.1 Statement waiver details

#### MUL — 6 uncovered statements

The following statements are uncovered:

```text
fpu_mul.sv:547
fpu_mul.sv:576
fpu_mul.sv:583
fpu_mul.sv:585
fpu_mul.sv:586
fpu_mul.sv:587
```

All six statements belong to false branches of conditions that require:

```text
subnormal_shift <= 0
subnormal_shift <  2
subnormal_shift <  3
```

However, in the subnormal-result path:

```text
subnormal_shift >= 25
```

has been formally proven using SymbiYosys/Boolector.

Therefore the corresponding false branches are **unreachable**, and these
six statements are waived.

#### DIV — 11 uncovered statements

The following two control-flow regions contain the 11 uncovered statements:

```text
fpu_div.sv:402-416
fpu_div.sv:424-433
```

These regions correspond to:

```text
shift_cnt == 1
shift_cnt <= 0
```

For any subnormal-result path:

```text
exp_unbiased <= -127

shift_cnt = 32 - 149 - exp_unbiased
          = -117 - exp_unbiased

shift_cnt >= 10
```

Therefore `shift_cnt == 1` and `shift_cnt <= 0` are **unreachable** for
valid binary32 operands, and the associated statements are waived.

---

## 7. Final Conclusion

The FPU RTL verification closure status is as follows:

- **Branch coverage:** **CLOSED** for reachable RTL branches.  
- **Condition coverage:** **CLOSED** for reachable RTL conditions.  
- **Statement coverage:** **CLOSED** for reachable RTL statements.  

All remaining raw coverage misses are justified as unreachable by RTL  
datapath range proofs, control-flow/data-dependency analysis, and, for the  
MUL invariants, formal verification.

Overall:

```text
100% reachable RTL branch coverage,
with 6 mathematically/formally justified unreachable branch outcomes waived.

100% reachable RTL condition coverage,
with 13 structurally/mathematically unreachable condition coverage misses waived.

100% reachable RTL statement coverage,
with 17 structurally/mathematically/formally justified unreachable statements waived.
```

The waivers are not based on a mere absence of coverage hits.  
They are based on range proofs derived from the RTL datapath and, for the
MUL invariants, on successful formal verification.

---

## 8. Closure Status

| Coverage type      | Status                                                                                                      |
| ------------------ | ----------------------------------------------------------------------------------------------------------- |
| Branch coverage    | **CLOSED** for reachable RTL branches                                                                       |
| Condition coverage | **CLOSED** for reachable RTL conditions; remaining 13 unreachable condition coverage misses waived           |
| Statement coverage | **CLOSED** for reachable RTL statements; remaining 17 unreachable statements waived                          |
| Formal evidence    | MUL invariant proven by Boolector; DIV shift invariant mathematically proven; DIV full-DUT formal blocked   |
