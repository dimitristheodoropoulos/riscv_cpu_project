# Verification Tool Capability Matrix

**Status:** Evidence document
**Last evidence refresh:** 2026-10-04
**Owner:** Project verification documentation

---

## 1. Purpose and Scope

This document records **what was experimentally observed** while building
and running the CPU UVM testbench under multiple simulators, and
distinguishes that from **what was inferred, assumed, or not freshly
verified**.

It exists for three reasons:

1. To prevent over-claiming about commercial EDA tool behaviour that was
   never exercised in this project.
2. To give reviewers a single place to see *which tool produced which
   evidence*, so that any coverage number or functional claim can be
   traced to a concrete artifact under `sim/output/`.
3. To document the boundary between open-source-capable verification and
   commercial-EDA-capable verification, as observed, not as marketed.

**Out of scope:** VCS, Xcelium, JasperGold, VC Formal, and any
vendor-internal tooling. None of these were run in this project. See §10.

---

## 2. Tested Tool Baseline

| Tool | Version | How it was exercised | Evidence |
|---|---|---|---|
| Questa / vcover | 2025.2 (Altera Starter FPGA Edition, vcover 2025.05) | Full UVM compile, simulation, coverage collection and reporting | `sim/output/cpu_exec_coverage_report.txt`, `sim/output/cpu_exec.ucdb`, `sim/output/cpu_exec_rtl_coverage_summary.txt` |
| Verilator | 5.020 (as stated) | Lint / smoke / RTL-only simulation paths | see §5, §6 — evidence is partial and marked per-row |
| Icarus Verilog | 12.0 (as stated) | Basic RTL simulation, non-UVM | see §4 — limited to RTL smoke |

> **Note:** Verilator and Icarus rows carry an explicit evidence tag
> wherever the observation does not come from a fresh run of the same
> artifact set used for Questa.

---

## 3. Capability Matrix

Legend for the **Status** column:

- **Verified** — observed directly in this project, with a named artifact
- **Partial** — observed, but only on a subset of the testbench or with caveats
- **Limitation** — observed to fail or be unsupported, with a specific reproducer
- **Not freshly verified** — asserted from external knowledge, not reproduced here

### 3.1 Simulation

| Capability | Questa | Verilator | Icarus |
|---|---|---|---|
| RTL compile + run | Verified | Verified (RTL subset) | Verified (RTL subset) |
| Full UVM testbench compile + run | Verified | Limitation (see §5.3) | Limitation |
| SVA in simulation | Verified | Partial | Limitation |
| Delayed / nonblocking array assignment semantics | Verified | Limitation (see §5.1) | Not freshly verified |

### 3.2 SystemVerilog

| Capability | Questa | Verilator | Icarus |
|---|---|---|---|
| Classes, packages, inheritance | Verified | Partial | Limitation |
| `randomize() with { … }` constraints | Verified | Limitation (see §5.4) | Limitation |
| Covergroups / `coverpoint` / `cross` | Verified | Limitation (see §5.2) | Limitation |
| `ref` arguments in tasks/functions | Verified | Partial | Not freshly verified |

### 3.3 UVM

| Capability | Questa | Verilator | Icarus |
|---|---|---|---|
| UVM 1.2 base library | Verified | Limitation (see §5.3) | Not freshly verified |
| Sequences, drivers, monitors, scoreboard | Verified | Limitation | Not freshly verified |
| `uvm_config_db` across hierarchy | Verified | Not freshly verified | Not freshly verified |
| Coverage-driven closure via UVM | Verified | Not freshly verified | Not freshly verified |

### 3.4 Code Coverage

| Metric | Questa | Verilator | Icarus |
|---|---|---|---|
| Branch | Verified (100% rtl-only, see §6) | Partial | Limitation |
| Condition | Verified (100% rtl-only) | Partial | Limitation |
| Statement | Verified (100% rtl-only) | Partial | Limitation |
| Toggle (full netlist) | Verified | Limitation | Not freshly verified |
| Expression | Verified | Not freshly verified | Not freshly verified |
| FSM | Not freshly verified | Limitation | Not freshly verified |

### 3.5 Functional Coverage

| Capability | Questa | Verilator | Icarus |
|---|---|---|---|
| Native `covergroup` in SV | Verified | Limitation (see §5.2) | Limitation |
| Coverage merge across runs | Verified | Not freshly verified | Not applicable |
| UCDB / coverage database | Verified (`cpu_exec.ucdb`) | Not freshly verified | Not applicable |

### 3.6 Coverage Database / Closure

| Capability | Questa | Verilator | Icarus |
|---|---|---|---|
| Persistent coverage DB | Verified | Not freshly verified | Not applicable |
| Cross-run merge | Verified | Not freshly verified | Not applicable |
| Exclusion / waiver files | Verified | Not freshly verified | Not applicable |
| Per-instance filtered view | Verified (85.83%) | Not freshly verified | Not applicable |

### 3.7 Debug

| Capability | Questa | Verilator | Icarus |
|---|---|---|---|
| Waveform dump (VCD/FST) | Verified | Verified | Verified |
| Source-level debug into UVM | Verified | Partial | Limitation |
| Transaction-level debug | Verified | Not freshly verified | Not freshly verified |

### 3.8 Formal

| Capability | Questa | Verilator | Icarus |
|---|---|---|---|
| Property checking | Not exercised here | Not applicable | Not applicable |
| Formal coverage | Not exercised here | Not applicable | Not applicable |

> The FPU formal model under `formal/fpu/` is a **separate** effort and is
> not part of the CPU UVM verification flow documented here.

### 3.9 Regression / Automation

| Capability | Questa | Verilator | Icarus |
|---|---|---|---|
| Scripted multi-test regression | Verified | Partial | Partial |
| Coverage aggregation across tests | Verified | Not freshly verified | Not applicable |
| Deterministic seed replay | Verified | Not freshly verified | Not freshly verified |

---

## 4. Cross-Tool Evidence

### 4.1 CPU branch smoke

**Questa:** `sim/output/cpu_exec_rtl_coverage_summary.txt` shows
`cpu_exec_core` branch coverage 19/19 = 100.00%. The branch-directed
sequence `test_branch_execution()` in `cpu_exec_sequence.sv` is the
stimulus that closed it.

**Verilator / Icarus:** the same RTL was compiled and executed for
RTL-only smoke, but the UVM branch-directed sequence was not run under
these tools in this project. RTL branch toggling observed under Questa
does **not** transfer as evidence for Verilator branch coverage.

### 4.2 DUT ↔ reference-model differential smoke

**Questa:** `cpu_model_pkg` and `cpu_scoreboard_pkg` participate in the
UVM env and compare DUT register/memory state against a reference model
on every transaction. This ran to completion in the run that produced
`sim/output/cpu_exec_coverage_report.txt`.

**Verilator / Icarus:** no equivalent UVM differential harness was run.

---

## 5. Verilator Verified Limitations

These are specific, reproducible limitations observed in this project
(or explicitly documented by Verilator itself), **not** general claims
about Verilator.

### 5.1 MMU delayed array assignment

The MMU contains delayed (non-blocking) assignments to array elements
used in a subsequent cycle. Verilator's scheduling of these is not
cycle-equivalent to Questa's for this pattern in the RTL as written.

**Reproducer:** `rtl/mmu.sv` (memory array update path).
**Consequence:** MMU-level coverage and behavior must be verified under
an event-driven simulator (Questa in this project).

### 5.2 Native covergroup

Verilator does not implement SystemVerilog `covergroup` /
`coverpoint` / `cross` as a first-class construct suitable for the
coverage closure used here. Functional coverage closure in this project
was performed under Questa.

### 5.3 Full UVM 1.2

Verilator does not compile the full UVM 1.2 base library in a way that
supports this testbench's sequence/driver/monitor/scoreboard structure.
The UVM flow in this project is Questa-only.

### 5.4 `randomize() with` constraints

Verilator's constraint solver coverage for `randomize() with { … }` is
limited relative to Questa's. Directed sequences in
`cpu_exec_sequence.sv` avoid relying on the solver for closure.

---

## 6. Coverage Model Differences

The same RTL produces **different coverage universes** depending on
which instances are in scope. This is the single most important fact to
keep straight when quoting numbers from this project.

| Universe | Source artifact | Metric | Value |
|---|---|---|---|
| RTL-only, in-scope CPU instances | `cpu_exec_rtl_coverage_summary.txt` | Branch | 63/63 = 100.00% |
| RTL-only | same | Condition | 5/5 = 100.00% |
| RTL-only | same | Statement | 80/80 = 100.00% |
| RTL-only | same | Toggle (weighted) | 810/1248 = 64.90% |
| `cpu_exec_core` only | same | Toggle | 470/696 = 67.52% |
| Full UVM run toggle (different universe) | `cpu_exec_coverage_report.txt` | Toggle | 664/776 = 85.56% |
| Per-instance filtered view | same | Total | 85.83% |

**Do not compare 85.56% to 64.90% directly.** They are different
denominators over different instance sets. The 203 denominator that has
occasionally been quoted in earlier drafts is **not present in any
artifact under `sim/output/`** and must not be used.

---

## 7. What Open Source Can Already Cover

For this project, open-source tools (Verilator, Icarus) were sufficient
for:

- RTL elaboration and compile-clean status
- Basic directed RTL smoke
- Waveform capture for debug of individual RTL blocks
- Lint-style checks on synthesizable RTL

They were **not** sufficient for:

- UVM testbench execution
- Constrained-random stimulus
- Coverage closure with a persistent coverage database
- Cross-run coverage merging

---

## 8. Where Commercial EDA Has a Clear Advantage

Observed in this project (Questa vs. open source):

1. **Full UVM execution** with sequence/driver/monitor/scoreboard, plus
   functional coverage collection, in one flow.
2. **A persistent coverage database** (`cpu_exec.ucdb`) that supports
   merge across runs and per-instance filtered views.
3. **Simulation semantics** (delayed assignment, scheduling) that
   correctly handle the MMU array-update pattern used here.
4. **SVA** in the same environment as the UVM TB.
5. **Coverage closure tooling** — exclusion files, waivers, and
   per-instance reporting used to reach 100% branch/condition/statement.

These are observed, not asserted as universal. §10 bounds what may be
concluded about tools not tested.

---

## 9. Interpretation

The comparison demonstrates two distinct categories of verification
capability.

### Tool-independent verification methodology

- reference modeling;
- scoreboard-based checking;
- architectural checking;
- differential verification;
- assertions;
- coverage analysis;
- regression automation;
- Python infrastructure;
- test planning and coverage-closure reasoning.

### Tool-dependent infrastructure

- complete SystemVerilog language support;
- UVM implementation;
- constrained-random stimulus;
- native functional coverage;
- coverage database management;
- integrated debug and coverage workflows.

The main lesson from the comparison is not:

> "Open source replaces commercial EDA."

It is:

> **Open-source tools can cover a substantial portion of RTL
> verification, while commercial simulators provide broader language and
> methodology support and a more integrated environment for UVM,
> functional coverage, debug and coverage closure.**

This also shows why verification methodology should remain as independent
as practical from the simulation backend.

---

## 10. Evidence Boundaries / Non-Claims

- **Questa was experimentally evaluated in this project.**
- **VCS and Xcelium were not run in this project.**
- Therefore, this document does **not** claim direct VCS/Xcelium
  equivalence.
- Any statement about VCS/Xcelium in this document is marked
  **Not freshly verified** in §3 and must be treated as external
  knowledge, not project evidence.
- Any number in §6 is bound to the artifact named in the same row. If
  the artifact is regenerated, the number must be re-derived from the
  new artifact.
- The 203-denominator figure that appeared in earlier working notes is
  **not supported by any file under `sim/output/`** and is excluded
  from this document.

---

## Appendix A — Artifact Index

Selected artifacts under `sim/output/` referenced by this document:

- `cpu_exec_coverage_report.txt` (2026-10-03) — current full-run toggle report
- `cpu_exec.ucdb` (2026-10-03) — coverage database for the current run
- `cpu_exec_rtl_coverage_summary.txt` (2026-08-18) — per-instance RTL coverage, RTL-only scope
- `cpu_exec_rtl_only_coverage_summary.txt` (2026-08-18) — weighted RTL-only aggregate
- `cpu_exec_coverage_report_v2.txt` (2026-08-18) — earlier baseline
- `cpu_exec_coverage_details_new.txt` (2026-08-18) — detailed coverage dump

Coverage numbers cited in §6 must be traceable to the corresponding
coverage artifacts listed above.
Other quantitative observations are tied to the specific probe, source,
or command output described in the relevant section.

---
