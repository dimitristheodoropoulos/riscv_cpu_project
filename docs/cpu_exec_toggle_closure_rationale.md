# CPU Execution RTL Toggle Coverage Closure Rationale

## Summary

- Uncovered RTL toggle bins analyzed in this document: **438**
- These bins are a subset of the full RTL toggle coverage space.
- Covered toggle bins are not listed here; they are tracked in the full UCDB coverage report.
- No RTL modifications were made; this is a classification-only closure rationale.

## Uncovered bins by instance

| Instance | Uncovered bins |
|---|---:|
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | 106 |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | 64 |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_alu` | 4 |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | 38 |
| `/tb_top_cpu_exec/dut_wrapper/dut` | 226 |

## Classification

| Category | Meaning | Bins |
|---|---|---:|
| A | Legitimate stimulus-dependent | 234 |
| B | Useful / potentially easy to close | 136 |
| C | Low-value / not worth pursuing | 68 |

## Detailed uncovered bins

| Instance | Node | Direction | Category | Rationale |
|---|---|---|---|---|
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `funct7[0]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `funct7[0]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `funct7[1]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `funct7[1]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `funct7[2]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `funct7[2]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `funct7[3]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `funct7[3]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `funct7[4]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `funct7[4]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `funct7[6]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `funct7[6]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[0]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[0]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[1]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[1]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[2]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[2]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[3]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[3]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[4]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[4]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[5]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[5]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[6]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[6]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[7]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[7]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[8]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[8]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[9]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[9]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[10]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[10]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[11]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[11]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[12]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[12]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[13]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[13]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[14]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[14]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[15]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[15]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[16]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[16]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[17]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[17]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[18]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[18]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[19]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[19]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[20]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[20]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[21]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[21]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[22]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[22]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[23]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[23]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[24]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[24]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[25]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[25]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[26]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[26]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[27]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[27]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[28]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[28]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[29]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[29]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[30]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[30]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[31]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `imm_ext[31]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `is_fp` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `is_fp` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `opcode[2]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `opcode[2]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `opcode[3]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `opcode[3]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `opcode[6]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `opcode[6]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rd[2]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rd[2]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rd[3]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rd[3]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rd[4]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rd[4]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs1[1]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs1[1]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs1[2]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs1[2]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs1[3]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs1[3]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs1[4]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs1[4]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs2[0]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs2[0]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs2[2]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs2[2]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs2[3]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs2[3]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs2[4]` | `1H->0L` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_cu` | `rs2[4]` | `0L->1H` | **A** | Legitimate stimulus-dependent instruction encoding |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[0]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[0]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[1]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[1]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[2]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[2]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[3]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[3]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[4]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[4]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[5]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[5]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[6]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[6]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[7]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[7]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[8]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[8]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[9]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[9]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[10]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[10]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[11]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[11]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[12]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[12]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[13]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[13]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[14]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[14]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[15]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[15]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[16]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[16]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[17]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[17]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[18]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[18]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[19]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[19]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[20]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[20]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[21]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[21]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[22]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[22]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[23]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[23]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[24]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[24]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[25]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[25]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[26]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[26]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[27]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[27]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[28]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[28]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[29]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[29]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[30]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[30]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[31]` | `1H->0L` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_rf` | `i[31]` | `0L->1H` | **C** | Low-value implementation loop-index toggle |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_alu` | `overflow` | `1H->0L` | **B** | Useful functional stimulus: signed ADD/SUB overflow |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_alu` | `overflow` | `0L->1H` | **B** | Useful functional stimulus: signed ADD/SUB overflow |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_alu` | `overflow_int` | `1H->0L` | **B** | Useful functional stimulus: signed ADD/SUB overflow |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_alu` | `overflow_int` | `0L->1H` | **B** | Useful functional stimulus: signed ADD/SUB overflow |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[0]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[0]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[1]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[1]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[2]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[2]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[7]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[7]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[8]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[8]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[11]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[11]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[13]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[13]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[15]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[15]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[16]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[16]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[17]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[17]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[19]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[19]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[22]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[22]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[23]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[23]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[24]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[24]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[26]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[26]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[27]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[27]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[29]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[29]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[30]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[30]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[31]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut/u_mmu` | `data_out[31]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[0]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[0]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[1]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[1]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[2]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[2]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[3]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[3]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[4]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[4]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[5]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[5]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[6]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[6]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[7]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[7]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[8]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[8]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[9]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[9]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[10]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[10]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[11]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[11]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[12]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[12]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[13]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[13]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[14]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[14]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[15]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[15]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[16]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[16]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[17]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[17]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[18]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[18]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[19]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[19]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[20]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[20]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[21]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[21]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[22]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[22]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[23]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[23]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[24]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[24]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[25]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[25]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[26]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[26]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[27]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[27]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[28]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[28]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[29]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[29]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[30]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[30]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[31]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `imm_ext[31]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[2]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[2]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[3]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[3]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[6]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[6]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[9]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[9]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[10]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[10]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[11]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[11]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[16]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[16]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[17]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[17]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[18]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[18]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[19]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[19]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[20]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[20]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[22]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[22]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[23]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[23]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[24]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[24]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[25]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[25]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[26]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[26]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[27]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[27]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[28]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[28]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[29]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[29]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[31]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `instruction[31]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `is_fp` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `is_fp` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[0]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[0]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[1]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[1]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[2]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[2]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[7]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[7]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[8]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[8]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[11]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[11]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[13]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[13]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[15]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[15]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[16]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[16]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[17]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[17]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[19]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[19]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[22]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[22]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[23]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[23]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[24]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[24]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[26]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[26]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[27]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[27]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[29]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[29]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[30]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[30]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[31]` | `1H->0L` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `mmu_data_out[31]` | `0L->1H` | **B** | Useful/easy data-pattern stimulus through SW/LW |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[0]` | `1H->0L` | **C** | Architecturally fixed by word alignment |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[0]` | `0L->1H` | **C** | Architecturally fixed by word alignment |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[1]` | `1H->0L` | **C** | Architecturally fixed by word alignment |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[1]` | `0L->1H` | **C** | Architecturally fixed by word alignment |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[4]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[4]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[5]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[5]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[6]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[6]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[7]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[7]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[8]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[8]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[9]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[9]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[10]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[10]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[11]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[11]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[12]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[12]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[13]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[13]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[14]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[14]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[15]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[15]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[16]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[16]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[17]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[17]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[18]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[18]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[19]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[19]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[20]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[20]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[21]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[21]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[22]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[22]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[23]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[23]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[24]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[24]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[25]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[25]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[26]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[26]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[27]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[27]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[28]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[28]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[29]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[29]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[30]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[30]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[31]` | `1H->0L` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `pc[31]` | `0L->1H` | **B** | Potentially useful instruction-stream/address stimulus |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rd[2]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rd[2]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rd[3]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rd[3]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rd[4]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rd[4]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs1[1]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs1[1]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs1[2]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs1[2]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs1[3]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs1[3]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs1[4]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs1[4]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs2[0]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs2[0]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs2[2]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs2[2]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs2[3]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs2[3]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs2[4]` | `1H->0L` | **A** | Legitimate stimulus-dependent encoding/path |
| `/tb_top_cpu_exec/dut_wrapper/dut` | `rs2[4]` | `0L->1H` | **A** | Legitimate stimulus-dependent encoding/path |