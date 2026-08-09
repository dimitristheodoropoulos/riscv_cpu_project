# Verification Plan — RISC-V CPU Portfolio Project

## Scope

This document defines the verification scope for the RISC-V CPU project, an
IC-block-level verification portfolio piece targeting a scoped RV32I subset:
R-type ALU operations, LW, and SW. It does **not** cover branches, jumps,
I-type ALU immediates, LUI/AUIPC, or full instruction fetch — this is a
deliberate scoping decision to keep each verified block small, well-defined,
and fully closed rather than attempting broad, shallow coverage of a full
CPU.

## Verified blocks

### ALU (`rtl/alu.sv`)
- Combinational integer ALU: ADD, SUB, AND, OR, XOR, SLL, SRA, SLT
- Zero and signed-overflow (ADD/SUB) detection
- UVM environment: `alu_agent` / `alu_scoreboard` / `alu_coverage`
- Golden-model scoreboard cross-checks every transaction
- Functional coverage: opcode bins, zero/overflow crosses

### Control Unit (`rtl/cu.sv`)
- Combinational RV32I decode: R-type, Load (LW), Store (SW)
- UVM environment: `cu_agent` / `cu_scoreboard`
- Golden-model scoreboard independently re-implements the decode logic
  to catch encoding mismatches between RTL and testbench assumptions

## Stimulus generation

Stimulus is generated via `$urandom` / `$urandom_range` rather than
class-based `randomize()` with `rand`/`constraint` blocks. This is a
deliberate toolchain trade-off: Questa Starter Edition's free license
does not include the SystemVerilog Verification ("svverification") feature
required for the constraint solver. `$urandom` is a core IEEE Verilog
system function available in every edition, so pseudo-random stimulus
generation remains possible without a paid license. In an environment with
a full Questa/Xcelium license, this would be replaced with proper
`rand`/`constraint` sequences for genuine constrained-random testing.

## Toolchain decision: Verilator vs. Questa Starter Edition

Verilator 5.020 was evaluated first (open-source, no license required).
Investigation found:
- No support for `covergroup`/`coverpoint` (functional coverage)
- No support for `modport` with embedded `clocking` blocks
- An internal compiler crash when a class waits on a clocking-block event
  accessed through a virtual interface handle (`@(vif.clocking_block)`)
- Incomplete Verilator-compatibility patches in the upstream
  `chipsalliance/uvm-verilator` library (multiple `type_id::create()`
  call sites across the UVM library were never patched for Verilator's
  static-method-resolution limitations)

Given these compounding, upstream-level incompatibilities, the toolchain
was switched to Questa-Altera FPGA Starter Edition (free, registered via
Altera's Self-Service Licensing Center), which provides full native
`covergroup` and UVM-1.1d support out of the box, at the cost of no
`randomize()`/constraint-solver support in the free tier (see Stimulus
generation above).
Correction: initial investigation assumed covergroup would work natively on Questa Starter Edition (unlike Verilator). Testing showed covergroup is also gated behind the same svverification license feature as randomize(). Functional coverage was reimplemented as manual associative-array bin counting (alu_coverage.sv), avoiding the license-gated feature entirely while still producing a closure report.

## Known verification findings (fixed during development)

1. **ALU/CU control-signal encoding mismatch**: the original `alu.sv` used
   a 3-bit `Op` port with MIPS-style encoding, while the scoreboard assumed
   a 4-bit encoding. Fixed by unifying both to a 4-bit encoding and adding
   the missing `zero`/`overflow` output ports to the ALU.
2. **cu.sv used MIPS-style opcode fields** (`instruction[31:26]`) instead
   of RV32I opcode fields (`instruction[6:0]`). Rewritten to decode R-type
   /Load/Store per the RV32I base ISA encoding.
3. **Monitor/driver sampling race**: both driver and monitor waited on the
   same `@(posedge vif.clk)` event, causing a non-deterministic X-value
   read on the first cycle. Fixed with a `#1` delay in the monitor after
   the clock edge to sample after NBA/combinational settling.

## Coverage closure

ALU functional coverage covers all 8 opcodes, zero/non-zero, overflow/
no-overflow, and their crosses. Coverage reports are generated per run via
Questa's native `covergroup` support (`coverage report -detail` after
`vsim` run, output written to `sim/output/`).