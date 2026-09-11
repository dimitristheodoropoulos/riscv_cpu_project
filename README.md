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
- Code coverage
- Assertion-based verification
- Formal verification
- Seed-based regression
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
- `docs/fpu_branch_waivers.md`
- `docs/cpu_exec_verification_plan.md`
- `docs/cpu_exec_verification_summary.md`
- `docs/cpu_exec_formal_verification.md`
- `docs/CPU_VERIFICATION_SIGNOFF.md` (CPU execution core sign‑off)

---

# Verification Scope

The RTL contains several CPU-related blocks.

The current primary verification scope covers:

- ALU
- Control Unit
- Floating-Point Unit
- MMU
- Register File
- CPU Execution Core (`cpu_exec_core`)
- AXI4 single-beat slave interface
- AXI4 Master v1
- AXI4 Interconnect v1
- Cache V2

The AXI4 slave verification scope covers a deliberately constrained
single-beat AXI4 slave interface, including functional checking,
protocol assertions, backpressure, handshake stress, and functional
coverage closure.

The AXI4 Interconnect v1 verification scope covers a deliberately
constrained interconnect with:

- one master → two slaves
- static address decoding
- request routing and response routing
- ID preservation
- backpressure propagation
- unmapped-address DECERR handling
- single-beat transactions

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
| FPU | `rtl/fpu.sv`, `rtl/fpu_add.sv`, `rtl/fpu_sub.sv`, `rtl/fpu_mul.sv`, `rtl/fpu_div.sv` | Directed TB + Python reference/differential flow + UVM environment + coverage closure + formal | ✅ Branch/condition/statement reachable closure |
| MMU | `rtl/mmu.sv` | Directed TB + CPU exec integration + coverage | ✅ Verified for current CPU execution scope |
| Register File | `rtl/register_file.sv` | Self-checking TB + scoreboard + reference model + coverage | ✅ Verified for defined register-file behavior |
| CPU Execution Core | `rtl/cpu_exec_core.sv` | UVM agent + reference model + scoreboard + architectural checking + RTL coverage | ✅ Closed for defined RV32I execution subset |
| AXI4 Slave | `rtl/axi4/axi4_slave.sv` | UVM + scoreboard + protocol SVA + directed stress + functional coverage | ✅ Closed within declared single-beat scope |
| AXI4 Master v1 | `rtl/axi4/axi4_master.sv` | Directed self-checking verification + end-to-end Master → Interconnect → real AXI4 slaves | Verified within declared single-beat scope |
| AXI4 Interconnect v1 | `rtl/interconnect/axi4_interconnect.sv` | Integration smoke + bound SVA + real AXI4 slave targets | ✅ Verified within declared v1 scope |
| Cache V2 | `rtl/cache_v2.sv` | Directed self-checking verification + memory backpressure + WSTRB + response-stability + alignment checks | ✅ Passed within declared directed scope |

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

```

Different blocks use different combinations of these components according
to their verification requirements.

For CPU architectural checking, the project uses both an internal
SystemVerilog reference model and an external ISA-level differential
reference through Spike. The two layers serve different purposes:
the internal reference model supports transaction-level scoreboard
checking, while Spike provides an independent architectural execution
reference.

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

## Formal Verification

The ALU has been formally verified using:

```text
SymbiYosys
Boolector
Bounded Model Checking

```

Current result:

```text
4/4 implemented ALU formal properties PASS

```

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

The Control Unit is considered closed for the currently defined RV32I
instruction subset.

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

The FPU operates on 32-bit IEEE-754 binary32 operands.

The exact supported, partial, unsupported, and out-of-scope behavior is
defined in:

```text
docs/fpu_ieee754_verification_matrix.md

```

---

# FPU Directed Verification

The directed FPU testbench is:

```text
tests/fpu_tb.sv

```

The test suite exercises arithmetic operations and important boundary
conditions including rounding, overflow, underflow, subnormal behavior,
NaN, Infinity, signed zero, and carry/rounding boundaries.

---

# FPU Independent Reference Model

The project contains an independent Python reference-model infrastructure:

```text
reference/binary32.py
reference/fpu_reference_model.py
reference/scoreboard_bridge.py

```

The reference model is intentionally separated from the SystemVerilog RTL.

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

The current FPU differential regression has completed with:

```text
4154 generated differential vectors
0 mismatches
0 errors

```

---

# FPU UVM Environment

The FPU UVM infrastructure includes:

```text
uvm_tb/fpu_agent/fpu_pkg.sv
uvm_tb/fpu_agent/fpu_if.sv
uvm_tb/tb_top_fpu.sv
uvm_tb/tests/fpu_smoke_test.sv

```

The FPU package contains multiple sequence types for constrained-style
pseudo-random testing, corner-case testing, and coverage-closure testing.

---

# FPU Coverage Closure

The FPU coverage closure flow uses Questa coverage collection.

The latest FPU closure analysis reports:

| Coverage Metric | Raw Coverage | Reachable Coverage | Waivers |
| --- | --- | --- | --- |
| Branch Branch | 96.72% | 100.00% | 6 |
| Condition Coverage | 88.50% | 100.00% | 13 |
| Statement Coverage | 95.37% | 100.00% | 17 |
| Toggle Coverage | 79.95% | - | - |

The waivers are **not** based on merely missing coverage hits.

They are based on:

* RTL datapath range proofs;
* control-flow/data-dependency analysis;
* formal verification for MUL invariants;
* mathematical quotient-bound proofs for DIV.

Detailed evidence is documented in:

```text
docs/fpu_branch_waivers.md

```

The closure statement is:

> **100% reachable RTL branch coverage**,
> **100% reachable RTL condition coverage**,
> **100% reachable RTL statement coverage**,
> with justified unreachable outcomes waived.

---

# CPU Execution Core Verification

## RTL

The CPU Execution Core is implemented in:

```text
rtl/cpu_exec_core.sv

```

This is a minimal single-cycle RV32I execution datapath.

It supports:

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

It has:

* PC logic
* Instruction memory
* Control Unit integration
* Register File with writeback
* ALU with immediate/register operand selection
* MMU for load/store data path
* Testbench-only register initialization interface
* Testbench-only execution control

## Verification Environment

The CPU Execution Core verification environment includes:

* `uvm_tb/cpu_agent/cpu_exec_if.sv`
* `uvm_tb/cpu_agent/cpu_exec_uvm_wrapper.sv`
* `uvm_tb/cpu_agent/cpu_transaction.sv`
* `uvm_tb/cpu_agent/cpu_driver.sv`
* `uvm_tb/cpu_agent/cpu_monitor.sv`
* `uvm_tb/cpu_agent/cpu_scoreboard.sv`
* `uvm_tb/cpu_agent/cpu_functional_coverage.sv`   ← **functional coverage component**
* `uvm_tb/cpu_model/cpu_reference_model.sv`
* `uvm_tb/sequences/cpu_exec_sequence.sv`
* `uvm_tb/tests/cpu_exec_test.sv`
* `tests/cpu_exec_reg_init_smoke_tb.sv`
* `tests/cpu_exec_gls_smoke_tb.sv`

## Reference Model

The CPU reference model independently models the architectural effects of
the supported instruction subset:

```text
R-type: ADD, SUB, AND, OR, XOR, SLL, SRA, SLT
I-type: LW
S-type: SW

```

## Scoreboard

The scoreboard compares the architectural state predicted by the reference
model with the observed DUT state.

## DUT ↔ Spike Differential Verification

An additional architectural differential-verification layer compares the
CPU execution core against the Spike RISC-V ISA simulator.

The current smoke scope covers the following RV32I R-type instructions:

```text
ADD
SUB
AND
OR
XOR
SLL
SLT

```

The DUT records architectural commit information as:

```text
PC + instruction + destination register + architectural result

```

The Python differential flow compares the DUT commit trace against the
corresponding Spike execution trace.

The current differential smoke regression reports:

```text
7 RV32I instruction commits
DUT/Spike commit traces: matched
Architectural mismatches: 0
Python differential tests: 27 passed

```

The differential flow is intentionally scoped to the currently supported
instruction subset. It is not a claim of full RV32I or full CPU-system
verification.

## Directed Test Suite

The current directed CPU execution suite includes:

| Instruction / Case | Status |
| --- | --- |
| ADD | ✅ Pass |
| SUB | ✅ Pass |
| AND | ✅ Pass |
| OR | ✅ Pass |
| XOR | ✅ Pass |
| SLL | ✅ Pass |
| SRA | ✅ Pass |
| SLT | ✅ Pass |
| SW + LW | ✅ Pass |
| x0 write suppression | ✅ Pass |
| Unsupported R-type funct3 | ✅ Pass |
| Zero-instruction PC behavior | ✅ Pass |
| FP register initialization | ✅ Pass |
| ADD signed overflow | ✅ Pass |
| SUB signed overflow | ✅ Pass |

Scoreboard summary:

```text
Architectural verification PASSED

Expected transactions : 15
Observed transactions : 15
Matches               : 15
Mismatches            : 0

UVM_ERROR = 0
UVM_FATAL = 0

```

## CPU Execution RTL Coverage Closure

RTL coverage was collected using Questa Coverage (UCDB).

Verified RTL blocks:

| Block | Branch | Condition | Expression | Statement |
| --- | --- | --- | --- | --- |
| `cu` | 16/16 100% | – | – | 34/34 100% |
| `register_file` | 12/12 100% | 3/3 100% | – | 14/14 100% |
| `alu` | 11/11 100% | 1/1 100% | **5/5 100%** | 14/14 100% |
| `mmu` | 5/5 100% | – | 2/2 100% | 9/9 100% |
| `cpu_exec_core` | 19/19 100% | 1/1 100% | **6/7 85.71%** | 9/9 100% |
| **DUT total** | **63/63 100%** | **5/5 100%** | **13/14 92.86%** | **80/80 100%** |

The achieved reachable coverage (after justified waiver) is:

* **Branch**: 63/63 = 100%
* **Condition**: 5/5 = 100%
* **Expression**: 13/14 = 92.86% raw, with one justified waiver
* **Statement**: 80/80 = 100%

**Waiver detail:**
In `cpu_exec_core.sv`, the expression `(reg_init_enable ? reg_init_is_fp : is_fp)` has one uncovered input term:
`reg_init_enable = 0, is_fp = 1`.

During normal instruction execution, `is_fp` is driven by the Control Unit and is always `0` for the supported RV32I instruction subset. The only way to set `is_fp=1` is through the testbench register‑initialization interface (`reg_init_enable=1, reg_init_is_fp=1`), which has been covered. Therefore the term is unreachable on the normal instruction path. This is a justified waiver; it does not affect functional correctness.

**Toggle coverage**: 814/1248 = 65.22% – treated as a non‑targeted metric rather than a closure criterion.

## Gate-Level Simulation (GLS)

The CPU Execution Core was synthesized with Yosys and simulated at the
generic gate level using the generated netlist and Yosys simulation cells.

The GLS flow is intentionally separated from the RTL verification environment
and validates the synthesized implementation against architectural smoke
vectors.

The flow consists of:

```text
RTL
 ↓
Yosys synthesis
 ↓
Generic technology mapping
 ↓
Gate-level netlist
 ↓
Icarus Verilog + Yosys simcells
 ↓
Architectural GLS smoke test

```

The dedicated GLS testbench is:

```text
tests/cpu_exec_gls_smoke_tb.sv

```

The current GLS smoke scope covers:

* ADD
* SUB
* AND
* OR
* XOR
* SLL
* SLT
* SW effective-address generation
* LW effective-address generation
* PC progression

Observed GLS results from the executed checkpoint:

```text
Yosys synthesis               PASS
Generic-cell netlist          GENERATED
Icarus GLS compilation        PASS
Architectural GLS smoke      PASS
Architectural mismatches      0
Final PC                      0x00000024
VVP return code               0

```

The GLS test validates architectural outputs exposed by the synthesized
execution core, primarily `result` and `PC`. Register-file and MMU internal
state are not treated as portable gate-level hierarchical observability
points; those behaviors remain covered by the RTL integration environment.

This is an architectural gate-level smoke verification result. It is not a
claim of post-layout timing/SDF sign-off, full-chip GLS, or complete
GLS-to-Spike equivalence.

## Functional Coverage

Manual functional coverage is implemented in:

```text
uvm_tb/cpu_agent/cpu_functional_coverage.sv

```

The component receives original stimulus from the CPU driver and tracks
operation types, operand classes, immediate classes, memory address
classes, and relevant cross coverage. It is not used as a closure
criterion but demonstrates a comprehensive coverage‑driven methodology.

---

# AXI4 Verification

The project includes a dedicated AXI4 verification environment for the
RTL AXI4 slave:

```text
rtl/axi4/axi4_slave.sv
uvm_tb/axi4/axi4_if.sv
uvm_tb/axi4/axi4_transaction.sv
uvm_tb/axi4/axi4_sequence.sv
uvm_tb/axi4/axi4_driver.sv
uvm_tb/axi4/axi4_monitor.sv
uvm_tb/axi4/axi4_scoreboard.sv
uvm_tb/axi4/axi4_coverage.sv
uvm_tb/axi4/axi4_protocol_sva.sv
uvm_tb/axi4/axi4_agent.sv
uvm_tb/axi4/axi4_env.sv
uvm_tb/axi4/axi4_test.sv

```

## Verification Scope

The AXI4 environment verifies the declared single-beat slave behavior.

The current scope includes:

* write address/data/response handshakes;
* read address/data handshakes;
* transaction ID checking;
* write strobe behavior;
* response checking;
* read data checking;
* `RLAST` checking;
* response-channel backpressure;
* VALID stability while READY is deasserted;
* address-channel backpressure;
* handshake ordering;
* protocol assertions;
* scoreboard-based memory checking;
* functional coverage.

The current DUT and verification environment deliberately constrain
transactions to single-beat transfers:

```text
AWLEN = 0
ARLEN = 0
WLAST = 1
RLAST = 1

```

The environment does not claim complete AXI4 verification for arbitrary
bursts, unrestricted outstanding transactions, or full channel
concurrency.

## UVM Verification

The AXI4 UVM environment contains:

* transaction object;
* sequencer and directed stimulus;
* driver;
* monitor;
* scoreboard;
* functional coverage component;
* protocol SVA;
* environment and test.

The scoreboard models a simple in-order 1 KiB memory and checks:

* write data and `WSTRB`;
* read data;
* transaction IDs;
* `BRESP`;
* `RRESP`;
* `RLAST`.

## Protocol and Stress Verification

Dedicated standalone testbenches provide checks independent of the main
UVM regression:

```text
uvm_tb/axi4/axi4_directed_tb.sv
uvm_tb/axi4/axi4_backpressure_tb.sv
uvm_tb/axi4/axi4_handshake_stress_tb.sv

```

The directed smoke test verifies reset behavior, response IDs, response
codes, read data, and `RLAST`.

The backpressure test verifies that response payloads remain stable while
the corresponding READY signal is low.

The handshake stress test verifies:

* W-channel VALID stability before handshake;
* AW/W sequencing;
* AW backpressure while a B response is pending;
* stability of stalled AW payload;
* AR backpressure while an R response is pending;
* stability of stalled AR payload.

All standalone AXI4 stress tests completed with zero simulation errors
and zero warnings.

## Functional Coverage Closure

Because the available Questa Starter license does not provide executable
SystemVerilog covergroup support, the AXI4 environment uses explicit
executable counters and cross-coverage matrices.

The functional coverage model contains:

| Coverage Item | Bins |
| --- | --- |
| Operation | 2 |
| Read ID | 16 |
| Write ID | 16 |
| WSTRB class | 4 |
| BRESP class | 2 |
| RRESP class | 2 |
| Read address region | 3 |
| Write address region | 3 |
| Write address × WSTRB | 12 |
| Write ID × WSTRB | 64 |
| Read ID × address | 48 |
| Write ID × address | 48 |
| **Total** | **220** |

Final closure:

```text
Theoretical functional coverage: 218/220 = 99.09%
Reachable functional coverage:   218/218 = 100.00%
Unreachable bins:                2

```

The two unreachable bins are the non-OKAY response classes:

```text
BRESP_OTHER
RRESP_OTHER

```

The current AXI4 slave DUT always produces `OKAY` responses, so these bins
are unreachable within the declared DUT behavior. They are therefore
reported explicitly rather than artificially removed or forced.

## AXI4 Verification Sign-Off

The AXI4 verification milestone is considered closed for the declared
scope:

> **AXI4 single-beat slave verification closed within declared scope.**

This closure does not claim full AXI4 compliance verification. In
particular, unrestricted burst behavior, multiple outstanding
transactions, arbitrary channel concurrency, and physical/interconnect
integration remain outside the current scope.

---

# AXI4 Master Verification

The project includes a deliberately constrained AXI4 Master v1:

- `rtl/axi4/axi4_master.sv`
- `tests/axi4_master_tb.sv`
- `tests/axi4_master_interconnect_tb.sv`

The AXI4 Master v1 supports single-beat read and write transactions with one command outstanding at a time.

### Declared scope

- single-beat reads and writes
- transaction ID propagation
- AW/W write-channel sequencing
- B-channel response handling
- AR/R read-channel sequencing
- WSTRB propagation
- AXI AW backpressure and payload stability
- AXI AR backpressure and payload stability
- local response backpressure and response stability
- single-outstanding command behavior
- integration with AXI4 Interconnect v1

### Out of scope

- burst transactions
- multiple outstanding transactions
- QoS
- cache coherency
- ACE / CHI
- full AXI4 feature-space verification

### Verification evidence

Standalone directed verification:

- reset / idle command readiness
- write command acceptance
- AW backpressure and payload stability
- WDATA / WSTRB / WLAST checking
- B-channel response handling
- read command acceptance
- AR backpressure and payload stability
- R-channel response handling

Observed:

`AXI4 MASTER V1: PASS`

End-to-end integration verification:

- Master → Interconnect → real AXI4 Slave path
- S0 write/read
- S1 write/read
- S1 address translation
- WSTRB propagation
- unmapped write/read → DECERR
- local response backpressure and stability
- single-outstanding command behavior
- response ID and response-code checking

Observed:

`AXI4 MASTER -> INTERCONNECT -> SLAVES: PASS`

This checkpoint verifies the AXI4 Master within the declared directed single-beat v1 scope. It does not claim complete AXI4 compliance verification.

---

# AXI4 Interconnect Verification

The project includes a dedicated AXI4 Interconnect v1 verification
milestone:

```text
rtl/interconnect/axi4_interconnect.sv
tests/axi4_interconnect_smoke_tb.sv
uvm_tb/bus/axi4_interconnect_sva.sv

```

## Verification Scope

The AXI4 Interconnect v1 verification scope is deliberately constrained:

* one master → two slaves
* static address decoding
* request routing and response routing
* request/response ID association within the single-outstanding scope
* protocol stability under READY backpressure
* unmapped-address DECERR handling
* single-beat transactions

The following are explicitly outside the current v1 scope:

* arbitration and fairness across multiple masters
* multi-master topologies
* arbitrary outstanding-transaction support
* burst transactions across the interconnect
* advanced channel concurrency scenarios
* cache-coherent interconnect behavior
* NoC-style topologies

## Integration Smoke Verification

The integration smoke testbench connects the AXI4 Interconnect v1 to two
real AXI4 slave instances and exercises the following scenarios:

* S0 write followed by S0 read
* S1 write followed by S1 read
* S1 address translation
* Target isolation between S0 and S1
* Unmapped write → DECERR
* Unmapped read → DECERR
* Partial write with `WSTRB` routing to S0
* S0 lower and upper address-map boundaries
* S1 lower and upper address-map boundaries

Observed integration smoke result:

```text
AXI4 INTERCONNECT SMOKE: PASS

```

## Protocol Assertions

A dedicated bound SVA file provides interconnect-level protocol checks:

```text
uvm_tb/bus/axi4_interconnect_sva.sv

```

The bound assertions verify:

* single-beat write-address and read-address constraints
(`AWLEN = 0`, `ARLEN = 0`)
* `WLAST = 1` on accepted write-data transfers
* exclusive S0/S1 write targeting
* exclusive S0/S1 read targeting
* AW, W, and AR stability while VALID is asserted and READY is low
* B and R response stability while VALID is asserted and READY is low

These assertions are bound to the interconnect DUT instance and are
intended to catch protocol violations during the integration smoke
verification.

## Verification Sign-Off

The AXI4 Interconnect v1 verification checkpoint is considered closed
within the declared scope:

> **AXI4 Interconnect v1 integration and bound SVA smoke verification:
> PASS.**

This closure does not claim full interconnect verification. In particular,
arbitration, fairness, multi-master support, burst transactions, and
advanced channel concurrency remain outside the current v1 scope and are
tracked as future extensions in the verification roadmap.

---

# Cache V2 Verification

The project includes a deliberately scoped Cache V2 RTL block and a
directed self-checking verification environment:

```text
rtl/cache_v2.sv
tests/cache_v2_tb.sv
docs/cache_verification_requirements.md
docs/cache_verification_plan.md

```

The Cache V2 organization uses:

* 16 cache lines
* 1 word (32-bit) per line
* 32-bit addresses
* TAG [31:6]
* INDEX [5:2]
* OFFSET [1:0]

The implemented control flow is:

`IDLE → LOOKUP → REFILL / MEM_WRITE → RESP`

The directed verification covers:

* read hits
* read misses and refill
* replacement behavior
* write hits
* write misses without allocation
* WSTRB byte-lane behavior
* response stability while `RSP_VALID=1 && RSP_READY=0`
* memory-side `VALID`/`READY` backpressure
* one outstanding request
* accepted-request word-alignment checks

Observed directed verification result:

* 48 PASS records
* 0 FAIL records
* 34 check() assertions
* 14 CACHE-REQ-013 alignment checks
* `CACHE_V2 DIRECTED TEST: PASS`

The alignment evidence demonstrates that the accepted requests exercised
by the current directed scenarios are word-aligned. It does not claim that
the DUT rejects arbitrary unaligned requests.

This checkpoint does not claim constrained-random cache verification,
an independent cache reference model/scoreboard, SVA closure, functional
coverage closure, or synthesis/GLS verification for Cache V2.

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

The MMU has been integrated into the CPU execution core load/store path
and has a reset mechanism.

MMU verification is currently classified as:

```text
Verified for current CPU execution scope

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

The Register File has been covered at standalone level with:

```text
12/12 branch coverage

```

---

# Verification Methodology

## Directed Testing

Directed tests are used for:

* deterministic corner cases;
* boundary conditions;
* reset behavior;
* arithmetic corner cases;
* IEEE-754 edge cases;
* regression reproduction;
* targeted coverage closure.

## Seeded Pseudo-Random Testing

The selected free simulator environment does not provide the complete
license-gated SystemVerilog constrained-random feature set.

Therefore pseudo-random stimulus is generated using:

```systemverilog
$urandom
$urandom_range

```

## Scoreboards

Scoreboards independently calculate or obtain expected DUT behavior and
compare it against observed RTL outputs.

## Reference Models

Reference models provide executable representations of expected behavior.

Current examples include:

```text
tests/register_file_reference_model.sv
reference/binary32.py
reference/fpu_reference_model.py
reference/scoreboard_bridge.py
uvm_tb/cpu_model/cpu_reference_model.sv

```

## Differential Verification

Differential verification is used at multiple verification layers.

For the FPU, an independent Python reference-model flow compares RTL
arithmetic behavior across generated IEEE-754 binary32 vectors.

For the CPU Execution Core, an external Spike ISA simulator is used as an
architectural reference. The DUT produces an architectural commit trace
containing PC, instruction, destination register, and result information.
The Python differential flow compares the DUT trace against the Spike
execution trace.

The current CPU differential smoke scope covers seven RV32I R-type
instructions and reports 27/27 Python tests passing with zero architectural
mismatches.

The main FPU differential testbench is:

```text
tests/fpu_differential_tb.sv

```

The CPU differential infrastructure is:

```text
scripts/riscv_iss/
tests/riscv_iss/
tests/cpu_exec_spike_diff_smoke_tb.sv

```

---

# Functional Coverage

Functional coverage is tracked at block level.

Where native SystemVerilog covergroup functionality is unavailable under
the selected free simulator license, explicit/manual bin accounting is
used.

For the CPU execution core, a dedicated manual coverage component
(`cpu_functional_coverage.sv`) tracks operation types, operand classes,
immediate classes, and memory address classes.

---

# Code Coverage

The project supports simulator-based code coverage collection using the
Questa verification environment.

Coverage categories used during FPU closure analysis include:

```text
Branch
Condition
Statement
Toggle

```

The latest FPU coverage reachability analysis shows:

| Metric | Raw Coverage | Reachable Coverage | Waived |
| --- | --- | --- | --- |
| Branch | 96.72% | 100.00% | 6 |
| Condition | 88.50% | 100.00% | 13 |
| Statement | 95.37% | 100.00% | 17 |

CPU execution RTL coverage is documented in:

```text
docs/cpu_exec_verification_plan.md

```

---

# Assertion-Based Verification

The project contains assertion infrastructure for selected blocks.

Current examples include:

```text
tests/register_file_assertions.sv
uvm_tb/bus/axi4_interconnect_sva.sv

```

as well as assertion support in the ALU/CU verification environment and
the AXI4 protocol SVA.

---

# Formal Verification

Formal verification currently targets the ALU and FPU unreachable-branch
invariants.

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

# Regression Strategy

The project provides a seed-based regression framework:

```text
run_regression.sh

```

Usage:

```bash
./run_regression.sh <target> <num_seeds>

```

The FPU also has a dedicated coverage-closure target.

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
./run_sim.sh fpu_closure
./run_sim.sh cpu_exec

```

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

The simulator provides the UVM infrastructure required for the current
verification environment.

---

## Verilator

Verilator was evaluated as an open-source simulation alternative.

The investigation identified limitations relevant to the intended
verification environment.

---

## Formal Tools

Formal verification uses:

```text
SymbiYosys
Boolector

```

---

# Free-Tool Verification Adaptations

A deliberate objective of this project is to demonstrate how far a
professional verification methodology can be taken using free/open-source
tools and free-licensed simulator editions.

---

# Verification Findings

Several real RTL and verification issues were identified during development.

---

## ALU/CU Control Encoding Mismatch

The original ALU implementation used a 3-bit operation encoding while the
verification environment expected a 4-bit encoding.

---

## Control Unit Opcode Interpretation

The original Control Unit used MIPS-style opcode assumptions.

The Control Unit was corrected to decode the intended RV32I subset.

---

## UVM Sampling Race

The driver and monitor initially synchronized to the same positive clock
edge.

The issue was corrected by introducing a small post-edge sampling delay.

---

## FPU Coverage Closure Findings

During FPU coverage analysis, uncovered branches were inspected at RTL
level rather than simply being ignored.

Branches that are determined to be unreachable or architecturally
irrelevant are not artificially stimulated merely to increase a coverage
percentage.

---

## CPU Register Initialization Ordering

During CPU execution core verification, register initialization was
initially performed before reset release.

This caused the reset logic in the register file to clear the initialized
values.

The issue was corrected by releasing reset before performing register
initialization through the testbench interface.

---

## CPU Memory Reset Isolation

The MMU initially had no reset mechanism.

This caused store data from a previous test to persist across multiple
CPU execution transactions.

The issue was corrected by adding a reset mechanism to the MMU and
connecting it to the CPU execution core reset.

---

# Current Verification Status

The project intentionally maintains explicit status instead of claiming
project-wide closure.

| Verification Area | Status | Notes |
| --- | --- | --- |
| ALU functional verification | ✅ Closed | Scoreboard + directed/pseudo-random testing |
| ALU functional coverage | ✅ Closed | 8/8 opcode bins hit |
| ALU formal verification | ✅ Passed | 4/4 properties |
| Control Unit verification | ✅ Closed | UVM + independent decode model |
| FPU directed verification | ✅ Passed | Extensive arithmetic/corner-case testing |
| FPU differential verification | ✅ Passed | 4154 vectors, 0 mismatches |
| FPU UVM infrastructure | ✅ Implemented | Transaction and regression foundation |
| FPU coverage reachable closure | ✅ Closed | Branch/condition/statement reachable 100% |
| MMU directed verification | ✅ Verified | Integrated into CPU exec load/store path |
| MMU coverage | ✅ Closed | 100% branch coverage in CPU exec |
| Register File verification | ✅ Closed | 12/12 branch coverage standalone |
| Register File assertions | ✅ Implemented | Independent invariant checking |
| CPU Execution Core verification | ✅ Closed | Closed for defined RV32I execution subset |
| CPU Execution directed suite | ✅ Passed | 15 tests, 15/15 matches |
| CPU Execution RTL branch analysis | ✅ Closed for analyzed DUT hierarchy | 63/63 analyzed branches covered |
| CPU DUT ↔ Spike differential | 🟡 Scoped integration PASS; suite not fully green | Real DUT↔Spike integration passes; latest Python suite: 25 passed / 2 test-harness failures |
| CPU Execution Core GLS | ✅ Passed | Yosys synthesis + generic gate-level architectural smoke |
| AXI4 single-beat slave verification | ✅ Closed | UVM + scoreboard + SVA + directed/backpressure/handshake stress |
| AXI4 Master v1 verification | ✅ Passed | Directed standalone + end-to-end Master → Interconnect → real AXI4 slaves within declared single-beat scope |
| AXI4 reachable functional coverage | ✅ Closed | 218/218 reachable bins; 2 unreachable response bins |
| AXI4 Interconnect v1 verification | ✅ Passed | 1 master → 2 slaves, routing, ID/request association, boundary and unmapped-address checks, protocol-stability SVA |
| Cache V2 directed verification | ✅ Passed | 48 PASS records, 0 FAIL records, WSTRB, response stability, memory backpressure, alignment checks |
| Project-wide code coverage consolidation | 🟡 In progress | Individual block/core closure achieved; consolidated project-wide analysis remains |
| Formal verification | ✅ Partial | ALU 4/4, FPU MUL/DIV invariants PASS |
| Unified CI regression | 🟡 In progress | Local regression exists |
| CPU integration verification | 🟢 Initial | CPU exec core verified; full integration remains |
| Full-system verification | ⚪ Not started | Outside current scope |

---

# Industry-Style Verification Roadmap

## Phase 1 — Block-Level Verification

Completed and near-term activities:

* ALU UVM environment + scoreboard + coverage + formal ✅
* Control Unit UVM environment ✅
* FPU directed verification ✅
* FPU reference model ✅
* FPU differential verification ✅
* FPU UVM infrastructure ✅
* FPU reachable coverage closure ✅
* Register File verification ✅
* MMU reset + CPU exec integration ✅
* CPU Execution Core verification closure ✅
* CPU DUT ↔ Spike differential verification ✅
* CPU Execution Core synthesis + GLS architectural smoke ✅
* AXI4 UVM verification environment + scoreboard ✅
* AXI4 protocol SVA + backpressure verification ✅
* AXI4 handshake stress verification ✅
* AXI4 reachable functional coverage closure ✅
* Cache V2 directed verification checkpoint ✅

## Phase 2 — Bus and Interconnect Verification

AXI4 Interconnect v1 checkpoint completed.

* AXI4 Master v1 single-beat verification ✅

* End-to-end Master → Interconnect → AXI4 Slave integration ✅

Completed within the declared v1 scope:

* Bus/interconnect architecture definition
* Request routing and response routing
* Address decoding and target selection
* Protocol stability under READY backpressure
* ID/request association within the single-outstanding scope
* Error response propagation
* Protocol assertions
* Directed integration stress
* Integration smoke checking

Future extensions:

* Arbitration and fairness
* Multi-master support
* Broader constrained-random interconnect stress
* Expanded bus functional coverage
* More complex outstanding-transaction/concurrency scenarios

## Phase 3 — Coverage and Assertion Closure

Planned activities:

* Expand assertion coverage
* Consolidated code-coverage reports
* Complete CPU integration coverage closure

## Phase 4 — Formal Expansion

Potential future targets:

* Control Unit formal verification
* Register File formal properties
* MMU formal properties
* CPU exec core formal properties

## Phase 5 — Regression and CI

Planned capabilities:

* Seed-based local regression
* Unified block-level regression
* Automated coverage collection
* CI regression integration

## Phase 6 — CPU Integration

Future CPU-level verification will extend the current DUT ↔ Spike
architectural differential layer with:

* broader instruction coverage
* CPU-core integration testbench
* end-to-end instruction checking
* memory model
* integration scoreboard
* system-level functional coverage
* broader architectural-state checking

---

# Repository Structure

```text
riscv_cpu_project/
│
├── rtl/
│   ├── alu.sv
│   ├── cu.sv
│   ├── cpu_core.sv
│   ├── cpu_exec_core.sv
│   ├── fpu.sv
│   ├── fpu_add.sv
│   ├── fpu_sub.sv
│   ├── fpu_mul.sv
│   ├── fpu_div.sv
│   ├── mmu.sv
│   ├── register_file.sv
│   ├── cache_v2.sv
│   ├── axi4/
│   │   ├── axi4_slave.sv
│   │   └── axi4_master.sv
│   └── interconnect/
│       └── axi4_interconnect.sv
│
├── tests/
│   ├── cpu_tb.sv
│   ├── cpu_exec_tb.sv
│   ├── cpu_exec_reg_init_smoke_tb.sv
│   ├── cpu_exec_gls_smoke_tb.sv
│   ├── fpu_tb.sv
│   ├── fpu_differential_tb.sv
│   ├── mmu_tb.sv
│   ├── mmu_coverage.sv
│   ├── register_file_tb.sv
│   ├── register_file_scoreboard.sv
│   ├── register_file_reference_model.sv
│   ├── register_file_assertions.sv
│   ├── register_file_coverage.sv
│   ├── cpu_exec_spike_diff_smoke_tb.sv
│   ├── axi4_interconnect_smoke_tb.sv
│   ├── axi4_master_tb.sv
│   ├── axi4_master_interconnect_tb.sv
│   ├── cache_v2_tb.sv
│   ├── reference/
│   │   ├── generate_fpu_vectors.py
│   │   ├── generate_fpu_differential_vectors.py
│   │   ├── test_binary32.py
│   │   └── test_fpu_reference_model.py
│   └── riscv_iss/
│       ├── rv32i_alu_smoke.S
│       ├── rv32i_alu_smoke.ld
│       ├── rv32i_alu_smoke.expected
│       ├── test_differential_compare.py
│       ├── test_differential_fault_injection.py
│       ├── test_dut_commit_parser.py
│       ├── test_dut_spike_integration.py
│       ├── test_iss_contract.py
│       └── test_spike_backend.py
│
├── scripts/
│   └── riscv_iss/
│       ├── differential_compare.py
│       ├── dut_commit_parser.py
│       ├── iss_contract.py
│       ├── spike_backend.py
│       ├── spike_commit_parser.py
│       └── spike_runner.py
│
├── reference/
│   ├── binary32.py
│   ├── fpu_reference_model.py
│   └── scoreboard_bridge.py
│
├── uvm_tb/
│   ├── fpu_agent/
│   │   ├── fpu_pkg.sv
│   │   └── fpu_if.sv
│   ├── cpu_agent/
│   │   ├── cpu_exec_if.sv
│   │   ├── cpu_exec_uvm_wrapper.sv
│   │   ├── cpu_transaction.sv
│   │   ├── cpu_driver.sv
│   │   ├── cpu_monitor.sv
│   │   ├── cpu_scoreboard.sv
│   │   ├── cpu_functional_coverage.sv
│   │   └── cpu_agent.sv
│   ├── cpu_model/
│   │   └── cpu_reference_model.sv
│   ├── cpu_env/
│   ├── sequences/
│   │   └── cpu_exec_sequence.sv
│   ├── tb_top_cpu_exec.sv
│   ├── bus/
│   │   └── axi4_interconnect_sva.sv
│   └── tests/
│       └── cpu_exec_test.sv
│
├── formal/
│   ├── alu/
│   │   ├── config.sby
│   │   └── src/
│   └── fpu/
│       ├── fpu_mul_waiver.sby
│       ├── fpu_div_waiver.sby
│       └── fpu_div_shift_waiver.sby
│
├── docs/
│   ├── fpu_ieee754_verification_matrix.md
│   ├── fpu_branch_waivers.md
│   ├── cpu_exec_verification_plan.md
│   ├── cpu_exec_verification_summary.md
│   ├── cpu_exec_formal_verification.md
│   ├── CPU_VERIFICATION_SIGNOFF.md
│   ├── cache_verification_requirements.md
│   └── cache_verification_plan.md
│
├── run_sim.sh
├── run_regression.sh
├── run_formal.sh
├── verification_plan.md
└── README.md

```

---

# FPU Verification Contract

The FPU verification contract is documented separately in:

```text
docs/fpu_ieee754_verification_matrix.md

```

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
Code Coverage
Assertions
Formal Verification
Seed-Based Regression
Toolchain Analysis

```

The current focus includes:

* FPU reachable coverage closure ✅
* MMU reset + integration ✅
* Register File verification ✅
* CPU Execution Core RTL coverage closure ✅
* CPU DUT ↔ Spike differential verification ✅
* CPU Execution Core synthesis + GLS architectural smoke ✅
* AXI4 single-beat slave verification closure ✅
* AXI4 reachable functional coverage closure ✅
* AXI4 Master v1 verification checkpoint ✅

* AXI4 Interconnect v1 verification checkpoint ✅
* Cache V2 directed verification checkpoint ✅

The AXI4 Interconnect v1 verification checkpoint is complete.

The immediate project focus is now interview preparation and consolidation
of the verification evidence. Broader project-wide coverage reporting,
CI regression, and future system-level integration remain outside the
current closure scope.

The repository demonstrates the engineering discipline required to
drive verification toward defensible closure while explicitly
documenting limitations and remaining gaps.
