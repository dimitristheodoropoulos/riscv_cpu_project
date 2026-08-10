`timescale 1ns/1ps

module cu_tb;

    reg  [31:0] instruction;

    wire [3:0]  ALU_op;
    wire [4:0]  rs1, rs2, rd;
    wire        is_fp;
    wire        mem_read, mem_write, reg_write;
    wire [31:0] imm_ext;

    integer tests;
    integer passed;

    // Functional coverage tracking
    integer opcode_hits [0:127];
    integer cov_i;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    cu uut (
        .instruction(instruction),
        .ALU_op(ALU_op),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .is_fp(is_fp),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .reg_write(reg_write),
        .imm_ext(imm_ext)
    );

    // ------------------------------------------------------------
    // Self-checking task
    // ------------------------------------------------------------
    task check_result;
        input [3:0]  expected_alu_op;
        input [4:0]  expected_rs1;
        input [4:0]  expected_rs2;
        input [4:0]  expected_rd;
        input        expected_mem_read;
        input        expected_mem_write;
        input        expected_reg_write;
        input [31:0] expected_imm_ext;
        input [255:0] test_name;

        begin
            tests = tests + 1;
            opcode_hits[instruction[6:0]] = opcode_hits[instruction[6:0]] + 1;

            #1;

            if ((ALU_op    === expected_alu_op)    &&
                (rs1       === expected_rs1)       &&
                (rs2       === expected_rs2)       &&
                (rd        === expected_rd)        &&
                (mem_read  === expected_mem_read)  &&
                (mem_write === expected_mem_write) &&
                (reg_write === expected_reg_write) &&
                (imm_ext   === expected_imm_ext)) begin

                passed = passed + 1;

                $display(
                    "PASS: %s | instr=%h ALU_op=%b rs1=%0d rs2=%0d rd=%0d mr=%b mw=%b rw=%b imm=%h",
                    test_name, instruction, ALU_op, rs1, rs2, rd, mem_read, mem_write, reg_write, imm_ext
                );

            end else begin

                $display(
                    "FAIL: %s | instr=%h | Expected: ALU_op=%b rs1=%0d rs2=%0d rd=%0d mr=%b mw=%b rw=%b imm=%h | Got: ALU_op=%b rs1=%0d rs2=%0d rd=%0d mr=%b mw=%b rw=%b imm=%h",
                    test_name, instruction,
                    expected_alu_op, expected_rs1, expected_rs2, expected_rd,
                    expected_mem_read, expected_mem_write, expected_reg_write, expected_imm_ext,
                    ALU_op, rs1, rs2, rd, mem_read, mem_write, reg_write, imm_ext
                );

            end
        end
    endtask

    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------
    initial begin

        tests  = 0;
        passed = 0;
        for (cov_i = 0; cov_i < 128; cov_i = cov_i + 1)
            opcode_hits[cov_i] = 0;

        $display("========================================");
        $display("Control Unit Functional Verification");
        $display("========================================");

        // --------------------------------------------------------
        // R-type: ADD  (funct7=0000000, rs2=3, rs1=2, funct3=000, rd=1, opcode=0110011)
        // --------------------------------------------------------
        instruction = {7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011};
        check_result(
            4'b0010, 5'd2, 5'd3, 5'd1,
            1'b0, 1'b0, 1'b1,
            32'b0,
            "R-type ADD"
        );

        // --------------------------------------------------------
        // R-type: SUB (funct7=0100000, rs2=5, rs1=4, funct3=000, rd=6, opcode=0110011)
        // --------------------------------------------------------
        instruction = {7'b0100000, 5'd5, 5'd4, 3'b000, 5'd6, 7'b0110011};
        check_result(
            4'b0110, 5'd4, 5'd5, 5'd6,
            1'b0, 1'b0, 1'b1,
            32'b0,
            "R-type SUB"
        );

        // --------------------------------------------------------
        // R-type: AND (funct3=111)
        // --------------------------------------------------------
        instruction = {7'b0000000, 5'd8, 5'd7, 3'b111, 5'd9, 7'b0110011};
        check_result(
            4'b0000, 5'd7, 5'd8, 5'd9,
            1'b0, 1'b0, 1'b1,
            32'b0,
            "R-type AND"
        );

        // --------------------------------------------------------
        // R-type: OR (funct3=110)
        // --------------------------------------------------------
        instruction = {7'b0000000, 5'd11, 5'd10, 3'b110, 5'd12, 7'b0110011};
        check_result(
            4'b0001, 5'd10, 5'd11, 5'd12,
            1'b0, 1'b0, 1'b1,
            32'b0,
            "R-type OR"
        );

        // --------------------------------------------------------
        // R-type: SLT (funct3=010)
        // --------------------------------------------------------
        instruction = {7'b0000000, 5'd14, 5'd13, 3'b010, 5'd15, 7'b0110011};
        check_result(
            4'b0111, 5'd13, 5'd14, 5'd15,
            1'b0, 1'b0, 1'b1,
            32'b0,
            "R-type SLT"
        );

        // --------------------------------------------------------
        // Load (LW): imm=4, rs1=2, rd=1, opcode=0000011
        // --------------------------------------------------------
        instruction = {12'd4, 5'd2, 3'b010, 5'd1, 7'b0000011};
        check_result(
            4'b0000, 5'd2, 5'd0, 5'd1,
            1'b1, 1'b0, 1'b1,
            32'd4,
            "Load (LW)"
        );

        // --------------------------------------------------------
        // Store (SW): imm=8, rs2=3, rs1=2, opcode=0100011
        // imm[11:5]=0000000, imm[4:0]=01000
        // --------------------------------------------------------
        instruction = {7'b0000000, 5'd3, 5'd2, 3'b010, 5'b01000, 7'b0100011};
        check_result(
            4'b0000, 5'd2, 5'd3, 5'd0,
            1'b0, 1'b1, 1'b0,
            32'd8,
            "Store (SW)"
        );

        // --------------------------------------------------------
        // Unsupported opcode -> all defaults (NOP)
        // --------------------------------------------------------
        instruction = {25'b0, 7'b1100011}; // branch opcode, not decoded
        check_result(
            4'b0000, 5'd0, 5'd0, 5'd0,
            1'b0, 1'b0, 1'b0,
            32'b0,
            "Unsupported opcode (NOP)"
        );

        // --------------------------------------------------------
        // Functional coverage report
        // --------------------------------------------------------
        $display("========================================");
        $display("CU FUNCTIONAL COVERAGE REPORT");
        $display("========================================");
        $display("R-type  (0110011): %0d hits", opcode_hits[7'b0110011]);
        $display("Load    (0000011): %0d hits", opcode_hits[7'b0000011]);
        $display("Store   (0100011): %0d hits", opcode_hits[7'b0100011]);
        $display("Unsupported (other): %0d hits", opcode_hits[7'b1100011]);

        // --------------------------------------------------------
        // Summary
        // --------------------------------------------------------
        $display("========================================");
        $display("CU VERIFICATION SUMMARY");
        $display("Tests : %0d", tests);
        $display("Passed: %0d", passed);
        $display("Failed: %0d", tests - passed);
        $display("========================================");

        if (passed != tests) begin
            $display("CU VERIFICATION FAILED");
            $fatal(1);
        end else begin
            $display("CU VERIFICATION PASSED");
        end

        $finish;
    end

endmodule
