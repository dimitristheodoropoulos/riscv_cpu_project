// File: uvm_tb/cpu_agent/cpu_functional_coverage.sv
`ifndef CPU_FUNCTIONAL_COVERAGE_SV
`define CPU_FUNCTIONAL_COVERAGE_SV

`include "uvm_macros.svh"

package cpu_coverage_pkg;

    import uvm_pkg::*;
    import cpu_pkg::*;

    // ------------------------------------------------------------
    // Enumerations for coverage categories
    // ------------------------------------------------------------
    typedef enum {
        ADD, SUB, AND, OR, XOR, SLL, SRA, SLT,
        LW, SW,
        UNSUPPORTED,
        ILLEGAL_OPCODE
    } operation_e;

    typedef enum {
        ZERO, POS, NEG, MAX, MIN, OTHER
    } operand_class_e;

    typedef enum {
        IMM_ZERO, IMM_POS, IMM_NEG, IMM_MAX, IMM_MIN, IMM_OTHER
    } imm_class_e;

    typedef enum {
        ADDR_LOW, ADDR_MID, ADDR_HIGH, ADDR_OUT
    } addr_class_e;

    // ------------------------------------------------------------
    // CPU Functional Coverage Component (manual counters)
    // ------------------------------------------------------------
    class cpu_functional_coverage extends uvm_component;

        `uvm_component_utils(cpu_functional_coverage)

        // Analysis import – receives cpu_transaction from driver
        uvm_analysis_imp #(cpu_transaction, cpu_functional_coverage) analysis_export;

        // ---- Internal architectural state ----
        logic signed [31:0] regs[0:31];
        logic [31:0] data_mem[0:255];
        logic [31:0] pc;

        // ---- Manual coverage counters ----
        int op_count[operation_e];
        int rs1_count[2];  // 0: zero, 1: non-zero
        int rs2_count[2];
        int rd_count[2];
        int rs1_val_count[operand_class_e];
        int rs2_val_count[operand_class_e];
        int imm_count[imm_class_e];
        int mem_addr_count[addr_class_e];
        int cross_op_rs1_rs2[operation_e][operand_class_e][operand_class_e];
        int cross_op_imm[operation_e][imm_class_e];
        int cross_op_mem_addr[operation_e][addr_class_e];
        int cross_op_rd[operation_e][2];

        // ---- Helper functions for string names ----
        function string operation_name(operation_e op);
            case (op)
                ADD:            return "ADD";
                SUB:            return "SUB";
                AND:            return "AND";
                OR:             return "OR";
                XOR:            return "XOR";
                SLL:            return "SLL";
                SRA:            return "SRA";
                SLT:            return "SLT";
                LW:             return "LW";
                SW:             return "SW";
                UNSUPPORTED:    return "UNSUPPORTED";
                ILLEGAL_OPCODE: return "ILLEGAL_OPCODE";
                default:        return "UNKNOWN";
            endcase
        endfunction

        function string operand_class_name(operand_class_e c);
            case (c)
                ZERO:  return "ZERO";
                POS:   return "POS";
                NEG:   return "NEG";
                MAX:   return "MAX";
                MIN:   return "MIN";
                OTHER: return "OTHER";
                default: return "UNKNOWN";
            endcase
        endfunction

        function string imm_class_name(imm_class_e c);
            case (c)
                IMM_ZERO:  return "IMM_ZERO";
                IMM_POS:   return "IMM_POS";
                IMM_NEG:   return "IMM_NEG";
                IMM_MAX:   return "IMM_MAX";
                IMM_MIN:   return "IMM_MIN";
                IMM_OTHER: return "IMM_OTHER";
                default:   return "UNKNOWN";
            endcase
        endfunction

        function string addr_class_name(addr_class_e c);
            case (c)
                ADDR_LOW:  return "ADDR_LOW";
                ADDR_MID:  return "ADDR_MID";
                ADDR_HIGH: return "ADDR_HIGH";
                ADDR_OUT:  return "ADDR_OUT";
                default:   return "UNKNOWN";
            endcase
        endfunction

        // ---- Constructor ----
        function new(string name, uvm_component parent);
            super.new(name, parent);
            analysis_export = new("analysis_export", this);
            reset_counters();
        endfunction

        // ---- Reset counters (only once, in constructor) ----
        function void reset_counters();
            int i, j, k;

            for (i = 0; i < 12; i++)
                op_count[operation_e'(i)] = 0;

            rs1_count[0] = 0;
            rs1_count[1] = 0;
            rs2_count[0] = 0;
            rs2_count[1] = 0;
            rd_count[0]  = 0;
            rd_count[1]  = 0;

            for (i = 0; i < 6; i++) begin
                rs1_val_count[operand_class_e'(i)] = 0;
                rs2_val_count[operand_class_e'(i)] = 0;
            end

            for (i = 0; i < 6; i++)
                imm_count[imm_class_e'(i)] = 0;

            for (i = 0; i < 4; i++)
                mem_addr_count[addr_class_e'(i)] = 0;

            for (i = 0; i < 12; i++) begin
                for (j = 0; j < 6; j++) begin
                    for (k = 0; k < 6; k++) begin
                        cross_op_rs1_rs2[
                            operation_e'(i)
                        ][
                            operand_class_e'(j)
                        ][
                            operand_class_e'(k)
                        ] = 0;
                    end
                end
            end

            for (i = 0; i < 12; i++) begin
                for (j = 0; j < 6; j++) begin
                    cross_op_imm[
                        operation_e'(i)
                    ][
                        imm_class_e'(j)
                    ] = 0;
                end
            end

            for (i = 0; i < 12; i++) begin
                for (j = 0; j < 4; j++) begin
                    cross_op_mem_addr[
                        operation_e'(i)
                    ][
                        addr_class_e'(j)
                    ] = 0;
                end
            end

            for (i = 0; i < 12; i++) begin
                cross_op_rd[operation_e'(i)][0] = 0;
                cross_op_rd[operation_e'(i)][1] = 0;
            end
        endfunction

        // ---- Helper classification functions ----
        function operand_class_e classify_operand(logic signed [31:0] val);
            if (val == 0) return ZERO;
            if (val == 32'h7FFFFFFF) return MAX;
            if (val == 32'h80000000) return MIN;
            if (val > 0) return POS;
            if (val < 0) return NEG;
            return OTHER;
        endfunction

        function imm_class_e classify_imm(logic signed [31:0] imm);
            if (imm == 0) return IMM_ZERO;
            if (imm == 2047) return IMM_MAX;
            if (imm == -2048) return IMM_MIN;
            if (imm > 0) return IMM_POS;
            if (imm < 0) return IMM_NEG;
            return IMM_OTHER;
        endfunction

        function addr_class_e classify_addr(logic signed [31:0] addr);
            if (addr >= 0 && addr <= 63) return ADDR_LOW;
            if (addr >= 64 && addr <= 127) return ADDR_MID;
            if (addr >= 128 && addr <= 255) return ADDR_HIGH;
            return ADDR_OUT;
        endfunction

        // ---- Reset architectural state (per transaction) ----
        function void reset_state(cpu_transaction tr);
            for (int i=0; i<32; i++) regs[i] = tr.init_int_regs[i];
            for (int i=0; i<256; i++) data_mem[i] = 0;
            pc = 0;
            // Counters are NOT reset here – they accumulate across all transactions
        endfunction

        // ---- Decode and sample (all declarations first) ----
        function void decode_and_sample(bit [31:0] instr);
            bit [6:0] opcode;
            bit [2:0] funct3;
            bit [6:0] funct7;
            bit [4:0] rs1, rs2, rd;
            logic signed [31:0] imm;
            operation_e op;
            logic signed [31:0] rs1_val, rs2_val, mem_addr;
            operand_class_e rs1c, rs2c;
            imm_class_e immc;
            addr_class_e memc;

            opcode = instr[6:0];
            funct3 = instr[14:12];
            funct7 = instr[31:25];
            rs1    = instr[19:15];
            rs2    = instr[24:20];
            rd     = instr[11:7];

            if (opcode == 7'b0000011) imm = $signed(instr[31:20]);
            else if (opcode == 7'b0100011) imm = $signed({instr[31:25], instr[11:7]});
            else imm = 0;

            if (opcode == 7'b0110011) begin
                case ({funct7[5], funct3})
                    6'b0_000: op = ADD;
                    6'b1_000: op = SUB;
                    6'b0_111: op = AND;
                    6'b0_110: op = OR;
                    6'b0_100: op = XOR;
                    6'b0_001: op = SLL;
                    6'b1_101: op = SRA;
                    6'b0_010: op = SLT;
                    default:  op = UNSUPPORTED;
                endcase
            end else if (opcode == 7'b0000011 && funct3 == 3'b010) begin
                op = LW;
            end else if (opcode == 7'b0100011 && funct3 == 3'b010) begin
                op = SW;
            end else begin
                op = ILLEGAL_OPCODE;
            end

            rs1_val = regs[rs1];
            rs2_val = regs[rs2];
            mem_addr = (op inside {LW, SW}) ? rs1_val + imm : 0;

            rs1c = classify_operand(rs1_val);
            rs2c = classify_operand(rs2_val);
            immc = classify_imm(imm);
            memc = classify_addr(mem_addr);

            op_count[op]++;
            rs1_count[rs1 == 0 ? 0 : 1]++;
            rs2_count[rs2 == 0 ? 0 : 1]++;
            rd_count[rd == 0 ? 0 : 1]++;
            rs1_val_count[rs1c]++;
            rs2_val_count[rs2c]++;
            imm_count[immc]++;
            mem_addr_count[memc]++;
            cross_op_rs1_rs2[op][rs1c][rs2c]++;
            cross_op_imm[op][immc]++;
            cross_op_mem_addr[op][memc]++;
            cross_op_rd[op][rd == 0 ? 0 : 1]++;
        endfunction

        // ---- Execute: update architectural state exactly as RTL ----
        function void execute(bit [31:0] instr);
            bit [6:0] opcode;
            bit [2:0] funct3;
            bit [6:0] funct7;
            bit [4:0] rs1, rs2, rd;
            logic signed [31:0] imm;
            logic [3:0] alu_op;
            logic signed [31:0] a, b, result;
            logic reg_write, mem_read, mem_write;
            logic [31:0] addr;

            opcode = instr[6:0];
            funct3 = instr[14:12];
            funct7 = instr[31:25];
            rs1    = instr[19:15];
            rs2    = instr[24:20];
            rd     = instr[11:7];

            if (opcode == 7'b0000011) imm = $signed(instr[31:20]);
            else if (opcode == 7'b0100011) imm = $signed({instr[31:25], instr[11:7]});
            else imm = 0;

            a = regs[rs1];
            reg_write = 1'b0;
            mem_read  = 1'b0;
            mem_write = 1'b0;

            case (opcode)
                7'b0110011: begin
                    reg_write = 1'b1;
                    b = regs[rs2];
                    case (funct3)
                        3'b000: alu_op = funct7[5] ? 4'b0110 : 4'b0010;
                        3'b111: alu_op = 4'b0000;
                        3'b110: alu_op = 4'b0001;
                        3'b100: alu_op = 4'b0011;
                        3'b001: alu_op = 4'b0100;
                        3'b101: alu_op = funct7[5] ? 4'b0101 : 4'b1111;
                        3'b010: alu_op = 4'b0111;
                        default: alu_op = 4'b1111;
                    endcase
                end
                7'b0000011: begin
                    if (funct3 == 3'b010) begin  // LW
                        mem_read  = 1'b1;
                        reg_write = 1'b1;
                        b = imm;
                        alu_op = 4'b0010;
                    end else begin
                        alu_op = 4'b1111;
                        reg_write = 1'b0;
                    end
                end
                7'b0100011: begin
                    if (funct3 == 3'b010) begin  // SW
                        mem_write = 1'b1;
                        b = imm;
                        alu_op = 4'b0010;
                    end else begin
                        alu_op = 4'b1111;
                    end
                end
                default: begin
                    alu_op = 4'b1111;
                    reg_write = 1'b0;
                end
            endcase

            case (alu_op)
                4'b0010: result = a + b;
                4'b0110: result = a - b;
                4'b0000: result = a & b;
                4'b0001: result = a | b;
                4'b0011: result = a ^ b;
                4'b0100: result = a << b[4:0];
                4'b0101: result = a >>> b[4:0];
                4'b0111: result = (a < b) ? 32'd1 : 32'd0;
                default: result = 0;
            endcase

            addr = a + imm;
            if (mem_write) data_mem[addr[7:0]] = regs[rs2];
            if (mem_read) result = data_mem[addr[7:0]];

            if (reg_write && rd != 0) regs[rd] = result;

            if (instr != 32'h00000000) pc += 4;
        endfunction

        // ---- write() – called by driver analysis port ----
        function void write(cpu_transaction tr);
            bit [31:0] instr;
            reset_state(tr);
            for (int i=0; i<tr.instr_count; i++) begin
                instr = tr.instr_mem[i];
                decode_and_sample(instr);
                execute(instr);
            end
        endfunction

        // ---- Report phase – print coverage summary (no .name(), no foreach) ----
        function void report_phase(uvm_phase phase);
            super.report_phase(phase);

            `uvm_info("CPU_COV", "========================================", UVM_NONE)
            `uvm_info("CPU_COV", "    FUNCTIONAL COVERAGE SUMMARY", UVM_NONE)
            `uvm_info("CPU_COV", "========================================", UVM_NONE)

            // Operation coverage
            $display("\n[Operation coverage]");
            for (int i = 0; i < 12; i++) begin
                $display("  %-12s : %4d",
                         operation_name(operation_e'(i)),
                         op_count[operation_e'(i)]);
            end

            // Register classes
            $display("\n[Register classes]");
            $display("  rs1 zero     : %4d", rs1_count[0]);
            $display("  rs1 non-zero : %4d", rs1_count[1]);
            $display("  rs2 zero     : %4d", rs2_count[0]);
            $display("  rs2 non-zero : %4d", rs2_count[1]);
            $display("  rd zero      : %4d", rd_count[0]);
            $display("  rd non-zero  : %4d", rd_count[1]);

            // Operand value classes
            $display("\n[Operand value classes]");
            $display("  rs1:");
            for (int i = 0; i < 6; i++)
                $display("    %-6s : %4d",
                         operand_class_name(operand_class_e'(i)),
                         rs1_val_count[operand_class_e'(i)]);
            $display("  rs2:");
            for (int i = 0; i < 6; i++)
                $display("    %-6s : %4d",
                         operand_class_name(operand_class_e'(i)),
                         rs2_val_count[operand_class_e'(i)]);

            // Immediate classes
            $display("\n[Immediate classes]");
            for (int i = 0; i < 6; i++)
                $display("  %-10s : %4d",
                         imm_class_name(imm_class_e'(i)),
                         imm_count[imm_class_e'(i)]);

            // Memory address classes
            $display("\n[Memory address classes]");
            for (int i = 0; i < 4; i++)
                $display("  %-8s : %4d",
                         addr_class_name(addr_class_e'(i)),
                         mem_addr_count[addr_class_e'(i)]);

            // Cross: op x rs1_val x rs2_val
            $display("\n[Cross: op x rs1_val x rs2_val]");
            for (int i = 0; i < 12; i++) begin
                for (int j = 0; j < 6; j++) begin
                    for (int k = 0; k < 6; k++) begin
                        if (cross_op_rs1_rs2[operation_e'(i)][operand_class_e'(j)][operand_class_e'(k)] > 0) begin
                            $display("  %-12s x %-6s x %-6s : %4d",
                                operation_name(operation_e'(i)),
                                operand_class_name(operand_class_e'(j)),
                                operand_class_name(operand_class_e'(k)),
                                cross_op_rs1_rs2[operation_e'(i)][operand_class_e'(j)][operand_class_e'(k)]);
                        end
                    end
                end
            end

            // Cross: op x immediate class
            $display("\n[Cross: op x immediate class]");
            for (int i = 0; i < 12; i++) begin
                for (int j = 0; j < 6; j++) begin
                    if (cross_op_imm[operation_e'(i)][imm_class_e'(j)] > 0) begin
                        $display("  %-12s x %-10s : %4d",
                            operation_name(operation_e'(i)),
                            imm_class_name(imm_class_e'(j)),
                            cross_op_imm[operation_e'(i)][imm_class_e'(j)]);
                    end
                end
            end

            // Cross: op x memory address class
            $display("\n[Cross: op x memory address class]");
            for (int i = 0; i < 12; i++) begin
                for (int j = 0; j < 4; j++) begin
                    if (cross_op_mem_addr[operation_e'(i)][addr_class_e'(j)] > 0) begin
                        $display("  %-12s x %-8s : %4d",
                            operation_name(operation_e'(i)),
                            addr_class_name(addr_class_e'(j)),
                            cross_op_mem_addr[operation_e'(i)][addr_class_e'(j)]);
                    end
                end
            end

            // Cross: op x rd class
            $display("\n[Cross: op x rd class]");
            for (int i = 0; i < 12; i++) begin
                for (int j = 0; j < 2; j++) begin
                    if (cross_op_rd[operation_e'(i)][j] > 0) begin
                        if (j == 0)
                            $display("  %-12s x %-8s : %4d",
                                operation_name(operation_e'(i)), "zero", cross_op_rd[operation_e'(i)][j]);
                        else
                            $display("  %-12s x %-8s : %4d",
                                operation_name(operation_e'(i)), "non-zero", cross_op_rd[operation_e'(i)][j]);
                    end
                end
            end

            `uvm_info("CPU_COV", "========================================", UVM_NONE)
        endfunction

    endclass

endpackage

`endif