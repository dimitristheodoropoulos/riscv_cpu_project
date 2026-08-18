# CPU Execution Core Verification Sign‑Off

## Scope
This document covers the verification of the RV32I integer execution core (`cpu_exec_core`) for the following instructions:

- **R‑type**: ADD, SUB, AND, OR, XOR, SLL, SRA, SLT
- **I‑type**: LW (load word)
- **S‑type**: SW (store word)

The following architectural features are also verified:
- x0 invariant (zero register)
- Reset behavior (PC = 0, execution disabled)
- PC progression (increment by 4, except on zero instruction)
- Memory read/write consistency
- Register file initialization (integer and floating‑point via testbench interface)
- Unsupported opcode handling (default ALU operation, no unwanted side‑effects)

The floating‑point register file is accessible only through the testbench initialization interface; no FP instructions are implemented in the CU.

---

## Verification Environment

- **Testbench**: UVM 1.1d with custom agent, driver, monitor, scoreboard, and reference model.
- **Stimulus**: Directed tests covering each instruction, corner cases (overflow, edge operands, memory access, illegal decodes).
- **Checking**: Architectural scoreboard comparing DUT state (registers, memory, PC) against a software reference model.
- **Assertions**: SVA for invariants: x0=0, reset PC=0, no simultaneous memory read/write, execution disabled during reset.
- **Functional Coverage**: Manual coverage model tracking operation types, operand classes, immediate classes, and memory address ranges.
- **Code Coverage**: RTL branch, condition, expression, statement, and toggle coverage collected with Questa.

---

## Coverage Results

| Module             | Branch      | Condition   | Expression   | Statement   |
| ------------------ | ----------- | ----------- | ------------ | ----------- |
| `cu.sv`            | 16/16 100%  | –           | –            | 34/34 100%  |
| `register_file.sv` | 12/12 100%  | 3/3 100%    | –            | 14/14 100%  |
| `alu.sv`           | 11/11 100%  | 1/1 100%    | **5/5 100%** | 14/14 100%  |
| `mmu.sv`           | 5/5 100%    | –           | 2/2 100%     | 9/9 100%    |
| `cpu_exec_core.sv` | 19/19 100%  | 1/1 100%    | **6/7 85.7%** | 9/9 100%    |
| **DUT TOTAL**      | **63/63 100%** | **5/5 100%** | **13/14 92.9%** | **80/80 100%** |

- **Assertions**: 4/4 = 100% (all SVA properties passed)
- **Toggle**: 814/1248 = 65.22% (non‑targeted metric)

> **Note:** Toggle coverage is not a closure criterion for this verification; many data‑dependent toggles are not functionally relevant.

---

## Waiver

**Module:** `cpu_exec_core.sv`  
**Expression:** `(reg_init_enable ? reg_init_is_fp : is_fp)`  
**Uncovered input term:** `reg_init_enable = 0, is_fp = 1`

Questa coverage report shows:

```
Line 136 Item 1
(reg_init_enable ? reg_init_is_fp : is_fp)

Input Term   Covered
reg_init_enable  Y
reg_init_is_fp   Y
is_fp            N
```

**Reasoning:**
- During normal instruction execution (`reg_init_enable = 0`), the value of `is_fp` is taken from the CU.
- The CU (`cu.sv`) always drives `is_fp = 1'b0` for all supported RV32I instructions.
- The only way to set `is_fp = 1` is through the testbench register‑initialization interface (`reg_init_enable = 1, reg_init_is_fp = 1`), which has been covered by the FP register initialization test.
- Therefore, the term `reg_init_enable = 0, is_fp = 1` is **unreachable in the normal instruction‑execution path** of this RV32I core.

**Impact:** No functional gap; the waiver does not affect correctness or completeness of the verification.

---

## Known Limitations

- No branch, jump, or privileged instructions are implemented.
- No exceptions or interrupts are handled.
- Memory is limited to 256 words; no virtual memory or protection.
- Floating‑point instructions are not supported (only register file initialization via testbench).

---

## Conclusion

The CPU execution core has been verified for the specified RV32I integer subset. All **reachable** RTL branch, condition, expression, and statement coverage is 100% (with one justified unreachable term waived). The architectural scoreboard confirms correct behavior for all directed tests (15/15 matches). The verification environment is reusable and includes methodology elements for coverage‑driven verification.

**Verification Status:** **PASSED**
