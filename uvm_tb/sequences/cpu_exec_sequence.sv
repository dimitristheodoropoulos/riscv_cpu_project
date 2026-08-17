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
        // Test 10: x0 write suppression
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


            // --------------------------------------------------------
            // Register-file architectural x0 behavior
            // --------------------------------------------------------

            test_x0_write();


            // --------------------------------------------------------
            // PC logic condition coverage
            // --------------------------------------------------------

            test_zero_instruction();


            // --------------------------------------------------------
            // Floating-point register-file initialization path
            // --------------------------------------------------------

            test_fp_reg_init();


            `uvm_info(
                "CPU_EXEC_SEQUENCE",
                "Directed CPU execution suite completed",
                UVM_MEDIUM
            )

        endtask


    endclass

endpackage

`endif