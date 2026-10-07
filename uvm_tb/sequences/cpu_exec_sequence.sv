`ifndef CPU_EXEC_SEQUENCE_SV
`define CPU_EXEC_SEQUENCE_SV

`include "uvm_macros.svh"

package cpu_exec_sequence_pkg;

    import uvm_pkg::*;
    import cpu_pkg::*;


    // ================================================================
    // CPU Execution Directed Sequence
    //
    // Directed end-to-end RV32I execution tests.
    //
    // Covered instructions:
    //
    //   ADD
    //   SUB
    //   AND
    //   OR
    //   XOR
    //   SLL
    //   SRA
    //   SLT
    //   SW
    //   LW
    //   ADD writing to x0
    //   Unsupported R-type funct3 (CU/ALU default)
    //   Unsupported SRL (funct3=101, funct7[5]=0 -> CU default)
    //   Zero instruction PC behavior
    //   FP register initialization via testbench interface
    //
    // Each test is a separate transaction.
    //
    // The driver resets the CPU before every transaction, therefore
    // every test starts from a clean architectural state.
    // ================================================================

    class cpu_exec_sequence extends uvm_sequence #(cpu_transaction);

        `uvm_object_utils(cpu_exec_sequence)


        // ------------------------------------------------------------
        // Constructor
        // ------------------------------------------------------------

        function new(
            string name = "cpu_exec_sequence"
        );

            super.new(name);

        endfunction


        // ============================================================
        // Helper: initialize instruction memory with NOPs
        // ============================================================

        task automatic init_instruction_memory(
            ref cpu_transaction tr
        );

            for (int i = 0; i < 64; i++) begin

                tr.instr_mem[i] =
                    32'h00000013;   // ADDI x0,x0,0 (NOP)

            end

        endtask


        // ============================================================
        // Helper: initialize integer register state to zero
        // ============================================================

        task automatic init_integer_registers(
            ref cpu_transaction tr
        );

            for (int i = 0; i < 32; i++) begin

                tr.init_int_regs[i] =
                    32'h00000000;

            end

        endtask


        // ============================================================
        // Helper: initialize expected integer register state
        // ============================================================

        task automatic init_expected_integer_registers(
            ref cpu_transaction tr
        );

            for (int i = 0; i < 32; i++) begin

                tr.exp_int_regs[i] =
                    32'h00000000;

            end

        endtask


        // ============================================================
        // Helper: initialize expected memory
        // ============================================================

        task automatic init_expected_memory(
            ref cpu_transaction tr
        );

            for (int i = 0; i < 256; i++) begin

                tr.exp_mem[i] =
                    32'h00000000;

            end

        endtask


        // ============================================================
        // Helper: encode an RV32I B-type branch instruction
        //
        // Branch immediate layout:
        //   imm[12] | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm[11] | opcode
        //
        // Supported here: BEQ, BNE, BLT, BGE.
        // ============================================================

        function automatic [31:0] encode_branch(
            input logic [2:0] funct3,
            input logic [4:0] rs1,
            input logic [4:0] rs2,
            input integer     imm
        );

            logic [12:0] bimm;

            begin
                bimm = imm[12:0];

                encode_branch = {
                    bimm[12],
                    bimm[10:5],
                    rs2,
                    rs1,
                    funct3,
                    bimm[4:1],
                    bimm[11],
                    7'b1100011
                };
            end

        endfunction


        // ============================================================
        // Test 1: ADD
        //
        //   ADD x3, x1, x2
        //
        //   x1 = 5
        //   x2 = 7
        //   x3 = 12
        //
        // Encoding:
        //   0x002081B3
        // ============================================================

        task automatic test_add();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_add");

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            tr.instr_mem[0] =
                32'h002081B3;

            tr.init_int_regs[1] =
                32'd5;

            tr.init_int_regs[2] =
                32'd7;

            tr.expected_pc =
                32'd4;

            tr.exp_int_regs[1] =
                32'd5;

            tr.exp_int_regs[2] =
                32'd7;

            tr.exp_int_regs[3] =
                32'd12;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST ADD: ADD x3,x1,x2 | x1=5 x2=7 -> x3=12",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 2: SUB
        //
        //   SUB x3, x1, x2
        //
        //   x1 = 20
        //   x2 = 7
        //   x3 = 13
        //
        // Encoding:
        //   0x402081B3
        //
        // Exercises CU funct7[5] = 1.
        // ============================================================

        task automatic test_sub();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_sub");

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            tr.instr_mem[0] =
                32'h402081B3;

            tr.init_int_regs[1] =
                32'd20;

            tr.init_int_regs[2] =
                32'd7;

            tr.expected_pc =
                32'd4;

            tr.exp_int_regs[1] =
                32'd20;

            tr.exp_int_regs[2] =
                32'd7;

            tr.exp_int_regs[3] =
                32'd13;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST SUB: SUB x3,x1,x2 | x1=20 x2=7 -> x3=13",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 3: AND
        //
        //   AND x3, x1, x2
        //
        // Encoding:
        //   0x0020F1B3
        // ============================================================

        task automatic test_and();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_and");

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            tr.instr_mem[0] =
                32'h0020F1B3;

            tr.init_int_regs[1] =
                32'hF0F0F0F0;

            tr.init_int_regs[2] =
                32'h0FF00FF0;

            tr.expected_pc =
                32'd4;

            tr.exp_int_regs[1] =
                32'hF0F0F0F0;

            tr.exp_int_regs[2] =
                32'h0FF00FF0;

            tr.exp_int_regs[3] =
                32'h00F000F0;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST AND: AND x3,x1,x2",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 4: OR
        //
        //   OR x3, x1, x2
        //
        // Encoding:
        //   0x0020E1B3
        // ============================================================

        task automatic test_or();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_or");

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            tr.instr_mem[0] =
                32'h0020E1B3;

            tr.init_int_regs[1] =
                32'hF0F0F0F0;

            tr.init_int_regs[2] =
                32'h0FF00FF0;

            tr.expected_pc =
                32'd4;

            tr.exp_int_regs[1] =
                32'hF0F0F0F0;

            tr.exp_int_regs[2] =
                32'h0FF00FF0;

            tr.exp_int_regs[3] =
                32'hFFF0FFF0;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST OR: OR x3,x1,x2",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 5: XOR
        //
        //   XOR x3, x1, x2
        //
        //   x1 = 0xAAAAAAAA
        //   x2 = 0x55555555
        //
        // Expected:
        //   x3 = 0xFFFFFFFF
        //
        // Encoding:
        //   0x0020C1B3
        // ============================================================

        task automatic test_xor();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_xor");

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            tr.instr_mem[0] =
                32'h0020C1B3;

            tr.init_int_regs[1] =
                32'hAAAAAAAA;

            tr.init_int_regs[2] =
                32'h55555555;

            tr.expected_pc =
                32'd4;

            tr.exp_int_regs[1] =
                32'hAAAAAAAA;

            tr.exp_int_regs[2] =
                32'h55555555;

            tr.exp_int_regs[3] =
                32'hFFFFFFFF;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST XOR: XOR x3,x1,x2",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 6: SLL
        //
        //   SLL x3, x1, x2
        //
        //   x1 = 1
        //   x2 = 4
        //
        // Expected:
        //   x3 = 16
        //
        // Encoding:
        //   0x002091B3
        // ============================================================

        task automatic test_sll();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_sll");

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            tr.instr_mem[0] =
                32'h002091B3;

            tr.init_int_regs[1] =
                32'd1;

            tr.init_int_regs[2] =
                32'd4;

            tr.expected_pc =
                32'd4;

            tr.exp_int_regs[1] =
                32'd1;

            tr.exp_int_regs[2] =
                32'd4;

            tr.exp_int_regs[3] =
                32'd16;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST SLL: SLL x3,x1,x2",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 7: SRA
        //
        //   SRA x3, x1, x2
        //
        //   x1 = 0x80000000
        //   x2 = 4
        //
        // Expected:
        //   x3 = 0xF8000000
        //
        // Encoding:
        //   0x4020D1B3
        // ============================================================

        task automatic test_sra();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_sra");

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            tr.instr_mem[0] =
                32'h4020D1B3;

            tr.init_int_regs[1] =
                32'h80000000;

            tr.init_int_regs[2] =
                32'd4;

            tr.expected_pc =
                32'd4;

            tr.exp_int_regs[1] =
                32'h80000000;

            tr.exp_int_regs[2] =
                32'd4;

            tr.exp_int_regs[3] =
                32'hF8000000;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST SRA: SRA x3,x1,x2",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 7b: Unsupported SRL
        //
        //   SRL x3, x1, x2
        //
        //   funct3  = 101
        //   funct7  = 0000000
        //
        // This specifically exercises the funct7[5] == 0 branch
        // in cu.sv:
        //
        //   ALU_op = funct7[5] ? 4'b0101 : 4'b1111;
        //
        // SRL is intentionally unsupported by this CPU, so the
        // control unit selects ALU_op = 4'b1111.
        // ============================================================

        task automatic test_srl_unsupported();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_srl_unsupported");

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            // SRL x3, x1, x2
            // funct7=0000000, rs2=2, rs1=1,
            // funct3=101, rd=3, opcode=0110011
            tr.instr_mem[0] =
                32'h0020D1B3;

            tr.init_int_regs[1] =
                32'h80000000;

            tr.init_int_regs[2] =
                32'd4;

            tr.expected_pc =
                32'd4;

            tr.exp_int_regs[1] =
                32'h80000000;

            tr.exp_int_regs[2] =
                32'd4;

            // Unsupported ALU operation -> default result
            tr.exp_int_regs[3] =
                32'd0;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST SRL UNSUPPORTED: funct7[5]=0 -> ALU_op=1111",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 8: SLT
        //
        //   SLT x3, x1, x2
        //
        //   x1 = -5
        //   x2 = 7
        //
        // Expected:
        //   x3 = 1
        //
        // Encoding:
        //   0x0020A1B3
        //
        // This specifically exercises the signed comparison in ALU.
        // ============================================================

        task automatic test_slt();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_slt");

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            tr.instr_mem[0] =
                32'h0020A1B3;

            tr.init_int_regs[1] =
                32'hFFFFFFFB;   // -5

            tr.init_int_regs[2] =
                32'd7;

            tr.expected_pc =
                32'd4;

            tr.exp_int_regs[1] =
                32'hFFFFFFFB;

            tr.exp_int_regs[2] =
                32'd7;

            tr.exp_int_regs[3] =
                32'd1;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST SLT: SLT x3,x1,x2 | x1=-5 x2=7 -> x3=1",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 9: SW + LW
        //
        //   SW x2, 0(x1)
        //   LW x3, 0(x1)
        //
        //   x1 = 16
        //   x2 = 0x12345678
        //
        // Expected:
        //   memory[16] = 0x12345678
        //   x3          = 0x12345678
        //
        // SW encoding:
        //   0x0020A023
        //
        // LW encoding:
        //   0x0000A183
        //
        // This exercises:
        //
        //   CU load path
        //   CU store path
        //   immediate generation
        //   mem_read
        //   mem_write
        //   is_mem
        //   ALU effective ADD
        //   immediate as ALU B input
        //   MMU write
        //   MMU read
        //   load writeback
        // ============================================================

        task automatic test_sw_lw();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_sw_lw");

            start_item(tr);

            tr.instr_count = 2;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            // SW x2, 0(x1)
            tr.instr_mem[0] =
                32'h0020A023;

            // LW x3, 0(x1)
            tr.instr_mem[1] =
                32'h0000A183;

            tr.init_int_regs[1] =
                32'd16;

            tr.init_int_regs[2] =
                32'h12345678;

            tr.expected_pc =
                32'd8;

            tr.exp_int_regs[1] =
                32'd16;

            tr.exp_int_regs[2] =
                32'h12345678;

            tr.exp_int_regs[3] =
                32'h12345678;

            // Expected architectural memory update after SW
            //
            // SW x2,0(x1)
            // x1 = 16
            // therefore:
            // memory[16] = 0x12345678

            tr.exp_mem[16] =
                32'h12345678;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST SW/LW: SW x2,0(x1) followed by LW x3,0(x1)",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 10: SW/LW complementary all-ones data pattern
        //
        //   SW x2, 0(x1)
        //   LW x3, 0(x1)
        //
        // This complements TEST 9's 0x12345678 data pattern and
        // exercises the remaining MMU data_out bit transitions.
        //
        // x1 = 16
        // x2 = 0xFFFFFFFF
        //
        // Expected:
        //   x3       = 0xFFFFFFFF
        //   memory[16] = 0xFFFFFFFF
        //
        // This is a functional data-pattern test, not coverage-only
        // stimulus: the scoreboard checks the complete architectural
        // register and memory state.
        // ============================================================

        task automatic test_sw_lw_all_ones();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_sw_lw_all_ones");

            start_item(tr);

            tr.instr_count = 2;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            // SW x2, 0(x1)
            tr.instr_mem[0] =
                32'h0020A023;

            // LW x3, 0(x1)
            tr.instr_mem[1] =
                32'h0000A183;

            tr.init_int_regs[1] =
                32'd16;

            tr.init_int_regs[2] =
                32'hFFFFFFFF;

            tr.expected_pc =
                32'd8;

            tr.exp_int_regs[1] =
                32'd16;

            tr.exp_int_regs[2] =
                32'hFFFFFFFF;

            tr.exp_int_regs[3] =
                32'hFFFFFFFF;

            // Expected architectural memory update after SW
            //
            // SW x2,0(x1)
            // x1 = 16
            // therefore:
            // memory[16] = 0xFFFFFFFF

            tr.exp_mem[16] =
                32'hFFFFFFFF;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST SW/LW ALL-ONES: SW x2,0(x1) followed by LW x3,0(x1) | data=0xFFFFFFFF",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 11: SW/LW odd immediate offset
        //
        //   SW x2, 1(x1)
        //   LW x3, 1(x1)
        //
        // x1 = 16, therefore the effective memory address is 17.
        // This exercises imm_ext[0] = 1 through both S-type and I-type
        // immediate generation while verifying the complete memory path.
        //
        // Expected:
        //   x3        = 0x12345678
        //   memory[17] = 0x12345678
        // ============================================================

        task automatic test_sw_lw_odd_offset();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_sw_lw_odd_offset");

            start_item(tr);

            tr.instr_count = 2;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            // SW x2, 1(x1)
            tr.instr_mem[0] =
                32'h0020A0A3;

            // LW x3, 1(x1)
            tr.instr_mem[1] =
                32'h0010A183;

            tr.init_int_regs[1] =
                32'd16;

            tr.init_int_regs[2] =
                32'h12345678;

            tr.expected_pc =
                32'd8;

            tr.exp_int_regs[1] =
                32'd16;

            tr.exp_int_regs[2] =
                32'h12345678;

            tr.exp_int_regs[3] =
                32'h12345678;

            // Expected architectural memory update after SW
            //
            // SW x2,1(x1)
            // x1 = 16
            // therefore:
            // memory[17] = 0x12345678

            tr.exp_mem[17] =
                32'h12345678;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST SW/LW ODD-OFFSET: SW x2,1(x1) followed by LW x3,1(x1)",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 11: x0 write suppression
        //
        //   ADD x0, x1, x2
        //
        // x0 must remain zero even though reg_write = 1.
        //
        // Encoding:
        //   0x00208033
        //
        // This directly exercises:
        //
        //   register_file:
        //       write_enable = 1
        //       is_fp       = 0
        //       write_addr  = 0
        //       write_addr != 0  -> FALSE
        //
        // and therefore verifies the architectural x0 rule.
        // ============================================================

        // ============================================================
        // Test 12: SW/LW signed immediate coverage
        //
        //   SW x2, -1(x1)       -> address 64
        //   LW x3, -1(x1)       -> address 64
        //
        //   x1 = 65
        //
        //   SW x2, -2048(x5)    -> address 0
        //   LW x3, -2048(x5)    -> address 0
        //
        // Covers:
        //   IMM_NEG
        //   IMM_MIN
        //   ADDR_MID
        // ============================================================

        task automatic test_sw_lw_signed_immediates();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_sw_lw_signed_immediates");

            start_item(tr);

            tr.instr_count = 4;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            // SW x2, -1(x1)
            tr.instr_mem[0] =
                32'hFE20AFA3;

            // LW x3, -1(x1)
            tr.instr_mem[1] =
                32'hFFF0A183;

            // SW x2, -2048(x5)
            tr.instr_mem[2] =
                32'h8020A023;

            // LW x3, -2048(x5)
            tr.instr_mem[3] =
                32'h8000A183;

            tr.init_int_regs[1] =
                32'd65;

            tr.init_int_regs[2] =
                32'h13579BDF;

            tr.init_int_regs[5] =
                32'd2048;

            tr.expected_pc =
                32'd16;

            tr.exp_int_regs[1] =
                32'd65;

            tr.exp_int_regs[2] =
                32'h13579BDF;

            tr.exp_int_regs[3] =
                32'h13579BDF;

            tr.exp_int_regs[5] =
                32'd2048;

            // 65 - 1 = 64
            tr.exp_mem[64] =
                32'h13579BDF;

            // 2048 - 2048 = 0
            tr.exp_mem[0] =
                32'h13579BDF;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST SW/LW SIGNED IMM: -1(x1)->64, -2048(x5)->0",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 13: SW/LW maximum positive immediate
        //
        //   SW x2, 2047(x1)
        //   LW x3, 2047(x1)
        //
        //   x1 = -1792
        //
        //   -1792 + 2047 = 255
        //
        // Covers:
        //   IMM_MAX
        //   ADDR_HIGH
        // ============================================================

        task automatic test_sw_lw_max_immediate();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_sw_lw_max_immediate");

            start_item(tr);

            tr.instr_count = 2;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            // SW x2, 2047(x1)
            tr.instr_mem[0] =
                32'h7E20AFA3;

            // LW x3, 2047(x1)
            tr.instr_mem[1] =
                32'h7FF0A183;

            // -1792 = 0xFFFFF900
            tr.init_int_regs[1] =
                32'hFFFFF900;

            tr.init_int_regs[2] =
                32'h2468ACE0;

            tr.expected_pc =
                32'd8;

            tr.exp_int_regs[1] =
                32'hFFFFF900;

            tr.exp_int_regs[2] =
                32'h2468ACE0;

            tr.exp_int_regs[3] =
                32'h2468ACE0;

            // -1792 + 2047 = 255
            tr.exp_mem[255] =
                32'h2468ACE0;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST SW/LW MAX IMM: -1792(x1)+2047 -> address 255",
                UVM_MEDIUM
            )

        endtask


        task automatic test_x0_write();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_x0_write");

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            // ADD x0, x1, x2
            tr.instr_mem[0] =
                32'h00208033;

            tr.init_int_regs[1] =
                32'd5;

            tr.init_int_regs[2] =
                32'd7;

            tr.expected_pc =
                32'd4;

            tr.exp_int_regs[0] =
                32'h00000000;

            tr.exp_int_regs[1] =
                32'd5;

            tr.exp_int_regs[2] =
                32'd7;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST x0: ADD x0,x1,x2 | x0 must remain zero",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 11: SLT false condition
        //
        //   SLT x3, x1, x2
        //
        //   x1 = 7
        //   x2 = -5
        //
        // Expected:
        //   x3 = 0
        //
        // Complements TEST 8 and explicitly exercises the false
        // side of the ALU signed comparison.
        // ============================================================

        task automatic test_slt_false();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_slt_false");

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            tr.instr_mem[0] =
                32'h0020A1B3;

            tr.init_int_regs[1] =
                32'd7;

            tr.init_int_regs[2] =
                32'hFFFFFFFB;   // -5

            tr.expected_pc =
                32'd4;

            tr.exp_int_regs[1] =
                32'd7;

            tr.exp_int_regs[2] =
                32'hFFFFFFFB;

            tr.exp_int_regs[3] =
                32'd0;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST SLT FALSE: SLT x3,x1,x2 | 7 < -5 is false",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test 12: Unsupported R-type funct3
        //
        // Instruction:
        //   funct3 = 3'b011
        //
        // Not supported by current CU decode.
        //
        // Expected:
        //   ALU_op = 4'b1111
        //   ALU default path
        //   Result = 0
        //
        // This covers:
        //   cu.sv:
        //       case(funct3) default
        //
        //   alu.sv:
        //       case(Op) default
        // ============================================================

        task automatic test_illegal_funct3();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_illegal_funct3");

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);


            // R-type encoding:
            //
            // funct7 = 0000000
            // rs2    = x2
            // rs1    = x1
            // funct3 = 011  <-- unsupported
            // rd     = x3
            // opcode = 0110011
            //
            // 0000000_00010_00001_011_00011_0110011

            tr.instr_mem[0] =
                32'b0000000_00010_00001_011_00011_0110011;


            tr.init_int_regs[1] =
                32'd10;

            tr.init_int_regs[2] =
                32'd20;


            tr.expected_pc =
                32'd4;


            // Unsupported operation should not write meaningful data

            tr.exp_int_regs[1] =
                32'd10;

            tr.exp_int_regs[2] =
                32'd20;

            tr.exp_int_regs[3] =
                32'd0;


            finish_item(tr);


            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST ILLEGAL FUNCT3: unsupported R-type decode -> ALU default",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test: Zero instruction
        //
        // Execute an all-zero instruction word.
        //
        // This intentionally exercises the FALSE outcome of:
        //
        //   if (instruction != 32'h00000000)
        //
        // Therefore the PC must remain at zero.
        // ============================================================

        task automatic test_zero_instruction();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create(
                    "tr_zero_instruction"
                );

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            // Intentionally zero instruction.
            tr.instr_mem[0] =
                32'h00000000;

            // PC must remain at zero because instruction == 0.
            tr.expected_pc =
                32'd0;

            tr.exp_int_regs[0] =
                32'h00000000;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST ZERO INSTRUCTION: instruction=0 -> PC remains 0",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test: FP register initialization
        //
        // Exercises the register_file FP write path through the
        // testbench register initialization interface.
        //
        // init_fp_regs[1] is driven by cpu_driver with:
        //   reg_init_enable = 1
        //   reg_init_is_fp  = 1
        //
        // This reaches:
        //   register_file.sv:
        //       if (is_fp)
        //           fp_regs[write_addr] <= write_data;
        // ============================================================

        task automatic test_fp_reg_init();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create("tr_fp_reg_init");

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            // Keep CPU execution harmless.
            tr.instr_mem[0] =
                32'h00000013;   // ADDI x0,x0,0 (NOP)

            // Initialize floating-point register f1/x? storage
            // with a non-zero value so the driver performs the
            // FP register initialization transaction.
            tr.init_fp_regs[1] =
                32'h3F800000;   // +1.0f

            tr.expected_pc =
                32'd4;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST FP REG INIT: fp_regs[1] initialized to 0x3F800000",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Main sequence body
        // ============================================================

        // ============================================================
        // ALU signed overflow coverage
        // ============================================================

        // ------------------------------------------------------------
        // Test: ADD signed overflow
        //   ADD x3, x1, x2
        //   0x7FFFFFFF + 1 = 0x80000000
        // ------------------------------------------------------------

        task automatic test_add_overflow();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create(
                    "tr_add_overflow"
                );

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            tr.instr_mem[0] =
                32'h002081B3;   // ADD x3,x1,x2

            tr.init_int_regs[1] =
                32'h7FFFFFFF;

            tr.init_int_regs[2] =
                32'h00000001;

            tr.expected_pc =
                32'd4;

            tr.exp_int_regs[1] =
                32'h7FFFFFFF;

            tr.exp_int_regs[2] =
                32'h00000001;

            tr.exp_int_regs[3] =
                32'h80000000;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST ADD OVERFLOW: x1=0x7FFFFFFF + x2=1 -> x3=0x80000000",
                UVM_MEDIUM
            )

        endtask


        // ------------------------------------------------------------
        // Test: SUB signed overflow
        //   SUB x3, x1, x2
        //   0x80000000 - 1 = 0x7FFFFFFF
        // ------------------------------------------------------------

        task automatic test_sub_overflow();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create(
                    "tr_sub_overflow"
                );

            start_item(tr);

            tr.instr_count = 1;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            tr.instr_mem[0] =
                32'h402081B3;   // SUB x3,x1,x2

            tr.init_int_regs[1] =
                32'h80000000;

            tr.init_int_regs[2] =
                32'h00000001;

            tr.expected_pc =
                32'd4;

            tr.exp_int_regs[1] =
                32'h80000000;

            tr.exp_int_regs[2] =
                32'h00000001;

            tr.exp_int_regs[3] =
                32'h7FFFFFFF;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST SUB OVERFLOW: x1=0x80000000 - x2=1 -> x3=0x7FFFFFFF",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test: sequential PC progression across a 16-byte boundary
        //
        // Execute five validated ADD instructions sequentially:
        //
        //   PC  0 : ADD x3,x1,x2
        //   PC  4 : ADD x3,x1,x2
        //   PC  8 : ADD x3,x1,x2
        //   PC 12 : ADD x3,x1,x2
        //   PC 16 : ADD x3,x1,x2
        //
        // This is a functional instruction-stream test. It verifies
        // sequential execution beyond the first 16-byte block and
        // therefore exercises higher PC / next-PC bits.
        //
        // Encoding:
        //   0x002081B3 = ADD x3,x1,x2
        // ============================================================

        task automatic test_sequential_pc_progression();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create(
                    "tr_sequential_pc_progression"
                );

            start_item(tr);

            tr.instr_count = 5;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            tr.instr_mem[0] = 32'h002081B3;
            tr.instr_mem[1] = 32'h002081B3;
            tr.instr_mem[2] = 32'h002081B3;
            tr.instr_mem[3] = 32'h002081B3;
            tr.instr_mem[4] = 32'h002081B3;

            tr.init_int_regs[1] = 32'd5;
            tr.init_int_regs[2] = 32'd7;

            tr.expected_pc = 32'd20;

            tr.exp_int_regs[1] = 32'd5;
            tr.exp_int_regs[2] = 32'd7;
            tr.exp_int_regs[3] = 32'd12;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST SEQUENTIAL PC: 5 sequential ADD instructions | final PC=20 | x3=12",
                UVM_MEDIUM
            )

        endtask



        // ============================================================
        // Test: extended sequential PC progression through 0x80
        //
        // Execute 33 validated ADD instructions sequentially.
        //
        //   PC 0x00 ... 0x7C : 32 instructions
        //   PC 0x80          : 33rd instruction
        //   final PC         : 0x84 (132)
        //
        // This intentionally exercises PC[5], PC[6] and PC[7]
        // through normal sequential instruction-stream execution.
        //
        // Encoding:
        //   0x002081B3 = ADD x3,x1,x2
        // ============================================================

        task automatic test_extended_sequential_pc_progression();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create(
                    "tr_extended_sequential_pc_progression"
                );

            start_item(tr);

            tr.instr_count = 33;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            for (int i = 0; i < 33; i++) begin
                tr.instr_mem[i] = 32'h002081B3;
            end

            tr.init_int_regs[1] = 32'd5;
            tr.init_int_regs[2] = 32'd7;

            tr.expected_pc = 32'd132;

            tr.exp_int_regs[1] = 32'd5;
            tr.exp_int_regs[2] = 32'd7;
            tr.exp_int_regs[3] = 32'd12;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST EXTENDED SEQUENTIAL PC: 33 sequential ADD instructions | final PC=132 (0x84) | x3=12",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test: directed branch execution
        //
        // Covers the four implemented conditional branches with both
        // taken and not-taken outcomes, plus an unsupported branch
        // funct3 and a negative branch offset.
        //
        // Program flow:
        //   0x00 : BEQ taken       -> 0x08
        //   0x08 : BNE taken       -> 0x10
        //   0x10 : BLT taken       -> 0x18
        //   0x18 : BGE taken       -> 0x20
        //   0x20 : BEQ not taken   -> 0x24
        //   0x24 : BNE not taken   -> 0x28
        //   0x28 : BLT not taken   -> 0x2C
        //   0x2C : BGE not taken   -> 0x30
        //   0x30 : unsupported     -> 0x34
        //   0x34 : BGE -8          -> 0x2C
        //
        // instr_count=14 is required so the driver loads instruction
        // memory through PC=0x34. The 14th execution starts at
        // PC=0x2C and advances to final PC=0x30, as independently
        // predicted by the reference model.
        // ============================================================

        task automatic test_branch_execution();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create(
                    "tr_branch_execution"
                );

            start_item(tr);

            tr.instr_count = 14;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            tr.instr_mem[0]  = encode_branch(3'b000, 5'd1,  5'd2,  8);
            tr.instr_mem[2]  = encode_branch(3'b001, 5'd3,  5'd4,  8);
            tr.instr_mem[4]  = encode_branch(3'b100, 5'd5,  5'd6,  8);
            tr.instr_mem[6]  = encode_branch(3'b101, 5'd7,  5'd8,  8);
            tr.instr_mem[8]  = encode_branch(3'b000, 5'd9,  5'd10, 4);
            tr.instr_mem[9]  = encode_branch(3'b001, 5'd11, 5'd12, 4);
            tr.instr_mem[10] = encode_branch(3'b100, 5'd13, 5'd14, 4);
            tr.instr_mem[11] = encode_branch(3'b101, 5'd15, 5'd16, 4);
            tr.instr_mem[12] = encode_branch(3'b010, 5'd1,  5'd2,  4);
            tr.instr_mem[13] = encode_branch(3'b101, 5'd7,  5'd8, -8);

            tr.init_int_regs[1]  = 32'd10;
            tr.init_int_regs[2]  = 32'd10;

            tr.init_int_regs[3]  = 32'd10;
            tr.init_int_regs[4]  = 32'd20;

            tr.init_int_regs[5]  = 32'hFFFFFFFB;
            tr.init_int_regs[6]  = 32'd5;

            tr.init_int_regs[7]  = 32'd5;
            tr.init_int_regs[8]  = 32'hFFFFFFFB;

            tr.init_int_regs[9]  = 32'd10;
            tr.init_int_regs[10] = 32'd20;

            tr.init_int_regs[11] = 32'd10;
            tr.init_int_regs[12] = 32'd10;

            tr.init_int_regs[13] = 32'd10;
            tr.init_int_regs[14] = 32'd5;

            tr.init_int_regs[15] = 32'd5;
            tr.init_int_regs[16] = 32'd10;

            tr.expected_pc = 32'd48;

            foreach (tr.init_int_regs[i])
                tr.exp_int_regs[i] = tr.init_int_regs[i];

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST BRANCH EXECUTION: BEQ/BNE/BLT/BGE taken+not-taken, unsupported funct3, negative offset | final PC=48 (0x30)",
                UVM_MEDIUM
            )

        endtask


        // ============================================================
        // Test: coverage closure for instruction/register fields
        //
        // Purpose:
        //   Close reachable DUT toggle residuals without artificial
        //   or misaligned taken-branch targets.
        //
        // Program flow:
        //   0x00 : ADD x4,  x16, x3
        //   0x04 : ADD x8,  x16, x3
        //   0x08 : ADD x16, x16, x3
        //   0x0C : BEQ x16, x3, +6  (not taken)
        //   0x10 : ADD x4,  x16, x3
        //
        // The +6 B-immediate exercises imm_ext[1], but the branch is
        // not taken, so the PC remains word-aligned.
        //
        // Target residuals:
        //   instruction[19] / rs1[4]
        //   instruction[20] / rs2[0]
        //   rd[2], rd[3], rd[4]
        //   imm_ext[1]
        //   branch 1->0
        //   instruction[6] 1->0
        // ============================================================

        task automatic test_coverage_closure_fields();

            cpu_transaction tr;

            tr =
                cpu_transaction::type_id::create(
                    "tr_coverage_closure_fields"
                );

            start_item(tr);

            tr.instr_count = 5;

            init_instruction_memory(tr);
            init_integer_registers(tr);
            init_expected_integer_registers(tr);
            init_expected_memory(tr);

            // ADD x4, x16, x3
            tr.instr_mem[0] = 32'h00380233;

            // ADD x8, x16, x3
            tr.instr_mem[1] = 32'h00380433;

            // ADD x16, x16, x3
            tr.instr_mem[2] = 32'h00380833;

            // BEQ x16, x3, +6
            // x16=11, x3=1 -> not taken.
            // The encoded immediate has imm[1]=1.
            tr.instr_mem[3] =
                encode_branch(3'b000, 5'd16, 5'd3, 6);

            // ADD x4, x16, x3
            // This also provides branch 1->0 and instruction[6] 1->0.
            tr.instr_mem[4] = 32'h00380233;

            // Initial architectural state.
            tr.init_int_regs[3]  = 32'd1;
            tr.init_int_regs[16] = 32'd10;

            tr.expected_pc = 32'd20;

            foreach (tr.init_int_regs[i])
                tr.exp_int_regs[i] = tr.init_int_regs[i];

            // Expected architectural results.
            tr.exp_int_regs[4]  = 32'd12;
            tr.exp_int_regs[8]  = 32'd11;
            tr.exp_int_regs[16] = 32'd11;

            finish_item(tr);

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "TEST COVERAGE CLOSURE: rs1[4]/rs2[0]/rd[2:4], imm_ext[1], branch 1->0 and instruction[6] 1->0",
                UVM_MEDIUM
            )

        endtask


        task body();

            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "Starting directed CPU execution suite",
                UVM_MEDIUM
            )


            // --------------------------------------------------------
            // R-type ALU operations
            // --------------------------------------------------------

            test_add();

            test_sub();

            test_and();

            test_or();

            test_xor();

            test_sll();

            test_sra();

            test_srl_unsupported();

            test_slt();

            test_slt_false();

            test_illegal_funct3();


            // --------------------------------------------------------
            // Memory path
            // --------------------------------------------------------

            test_sw_lw();

            test_sw_lw_all_ones();

            test_sw_lw_odd_offset();

            test_sw_lw_signed_immediates();

            test_sw_lw_max_immediate();


            // --------------------------------------------------------
            // Register-file architectural x0 behavior
            // --------------------------------------------------------

            test_x0_write();


            // --------------------------------------------------------
            // PC logic condition coverage
            // --------------------------------------------------------

            test_zero_instruction();

            // --------------------------------------------------------
            // ALU signed overflow expression coverage
            // --------------------------------------------------------

            test_add_overflow();

            test_sub_overflow();


            // --------------------------------------------------------
            // Floating-point register-file initialization path
            // --------------------------------------------------------

            test_fp_reg_init();

            test_sequential_pc_progression();

            test_extended_sequential_pc_progression();

            test_branch_execution();

            test_coverage_closure_fields();


            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "Directed CPU execution suite completed",
                UVM_MEDIUM
            )

        endtask


    endclass

endpackage

`endif