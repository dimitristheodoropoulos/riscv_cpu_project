# RISC-V CPU — IC-Block Verification Portfolio

Scoped RV32I subset (R-type ALU ops, LW, SW) verified block-by-block using
a professional UVM methodology, targeting the skillset for Digital
Verification Engineer roles: constrained-style stimulus generation,
scoreboard-based self-checking, functional coverage, and documented
toolchain engineering decisions.

See [`verification_plan.md`](./verification_plan.md) for full scope,
findings, and toolchain rationale.

## Verified blocks

| Block | RTL | UVM env | Status |
|---|---|---|---|
| ALU | `rtl/alu.sv` | `alu_agent` / `alu_scoreboard` / `alu_coverage` | ✅ 101/101 matches, coverage closed |
| Control Unit | `rtl/cu.sv` | `cu_agent` / `cu_scoreboard` | ✅ 101/101 matches |

## Toolchain

Simulated with **Questa - Altera FPGA Starter Edition** (Siemens EDA
simulation kernel, free-licensed via Altera Self-Service Licensing
Center). Chosen over Verilator after documented compatibility
investigation — see verification plan for details. Note: the RTL itself
targets no specific FPGA or ASIC technology library; the simulator choice
is a licensing/tooling decision independent of the design's target
technology.

## Running the tests

```bash
./run_sim.sh alu    # ALU block
./run_sim.sh cu     # Control Unit block
```

Requires a Questa/Siemens EDA license (`SALT_LICENSE_SERVER` env var set).

## Roadmap

- [ ] MMU / Cache / Register File block-level UVM environments
- [ ] SVA assertion layer (bind-based, per-module)
- [ ] Formal verification (SymbiYosys) on ALU/CU
- [ ] CI regression (GitHub Actions)
- [ ] System-level `cpu_core` integration env (Phase 2)