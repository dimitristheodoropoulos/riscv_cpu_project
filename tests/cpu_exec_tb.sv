`timescale 1ns/1ps

module cpu_exec_tb;

    logic clk;
    logic reset;

    logic [31:0] pc;
    logic [31:0] result;
    logic [31:0] last_result;

    integer errors;

    cpu_exec_core dut (
        .clk    (clk),
        .reset  (reset),
        .pc     (pc),
        .result (result)
    );

    always #5 clk = ~clk;

    // --------------------------------------------------------
    // RV32I instruction encoders
    // --------------------------------------------------------

    function automatic [31:0] enc_rtype;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;

        begin
            enc_rtype = {
                funct7,
                rs2,
                rs1,
                funct3,
                rd,
                7'b0110011
            };
        end
    endfunction

    function automatic [31:0] enc_lw;
        input [4:0] rs1;
        input [4:0] rd;
        input integer imm;

        begin
            enc_lw = {
                imm[11:0],
                rs1,
                3'b010,
                rd,
                7'b0000011
            };
        end
    endfunction

    function automatic [31:0] enc_sw;
        input [4:0] rs1;
        input [4:0] rs2;
        input integer imm;

        begin
            enc_sw = {
                imm[11:5],
                rs2,
                rs1,
                3'b010,
                imm[4:0],
                7'b0100011
            };
        end
    endfunction

    // --------------------------------------------------------
    // Check helper
    // --------------------------------------------------------

    task automatic check_reg;
        input integer index;
        input [31:0] expected;

        begin
            if (dut.u_rf.int_regs[index] !== expected) begin
                $display(
                    "FAIL: x%0d = %h, expected %h",
                    index,
                    dut.u_rf.int_regs[index],
                    expected
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: x%0d = %h",
                    index,
                    dut.u_rf.int_regs[index]
                );
            end
        end
    endtask

    // --------------------------------------------------------
    // Test
    // --------------------------------------------------------

    initial begin

        clk    = 1'b0;
        reset  = 1'b1;
        errors = 0;

        // ----------------------------------------------------
        // Program
        // ----------------------------------------------------

        dut.instr_mem[0] =
            enc_rtype(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3);
            // ADD x3, x1, x2

        dut.instr_mem[1] =
            enc_rtype(7'b0100000, 5'd1, 5'd3, 3'b000, 5'd4);
            // SUB x4, x3, x1

        dut.instr_mem[2] =
            enc_rtype(7'b0000000, 5'd2, 5'd3, 3'b111, 5'd5);
            // AND x5, x3, x2

        dut.instr_mem[3] =
            enc_rtype(7'b0000000, 5'd2, 5'd3, 3'b110, 5'd6);
            // OR x6, x3, x2

        dut.instr_mem[4] =
            enc_rtype(7'b0000000, 5'd2, 5'd1, 3'b010, 5'd7);
            // SLT x7, x1, x2

        dut.instr_mem[5] =
            enc_sw(5'd0, 5'd3, 0);
            // SW x3, 0(x0)

        dut.instr_mem[6] =
            enc_lw(5'd0, 5'd8, 0);
            // LW x8, 0(x0)

        dut.instr_mem[7] =
            enc_rtype(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd0);
            // ADD x0, x1, x2
            // x0 must remain hardwired to zero.

        dut.instr_mem[8] =
            enc_sw(5'd0, 5'd3, 4);
            // SW x3, 4(x0)

        dut.instr_mem[9] =
            enc_lw(5'd0, 5'd9, 4);
            // LW x9, 4(x0)

        dut.instr_mem[10] =
            enc_rtype(7'b0000000, 5'd1, 5'd12, 3'b010, 5'd10);
            // SLT x10, x12, x1
            // x12 = -5, x1 = 10 => -5 < 10 => x10 = 1

        dut.instr_mem[11] =
            enc_rtype(7'b0100000, 5'd12, 5'd1, 3'b000, 5'd11);
            // SUB x11, x1, x12
            // x1 - x12 = 10 - (-5) = 15

        dut.instr_mem[12] =
            enc_rtype(7'b0000000, 5'd2, 5'd1, 3'b001, 5'd13);
            // Unsupported R-type funct3=001
            //
            // Expected architectural effect:
            //   CU  -> default -> ALU_op = 4'b1111
            //   ALU -> default -> Result  = 32'b0
            //
            // This targeted vector covers:
            //   - cu.sv  : default branch for unsupported funct3
            //   - alu.sv : default branch for unsupported ALU_op

        // ----------------------------------------------------
        // Wait for reset
        // ----------------------------------------------------

        #12;
        reset = 1'b0;

        // ----------------------------------------------------
        // Initialize architectural state for directed test.
        //
        // This is intentionally testbench-only. No RTL
        // initialization is being introduced.
        // ----------------------------------------------------

        dut.u_rf.int_regs[1]  = 32'd10;
        dut.u_rf.int_regs[2]  = 32'd20;
        dut.u_rf.int_regs[12] = 32'hFFFF_FFFB; // -5

        // ----------------------------------------------------
        // Execute thirteen instructions.
        // ----------------------------------------------------

        repeat (13) begin
            @(posedge clk);
            #1;

            $display(
                "cycle: pc=%08h instruction=%08h result=%08h",
                pc,
                dut.instruction,
                result
            );

            // The final valid instruction is at PC=48.
            // Do not overwrite last_result with the result of the
            // uninitialized instruction at PC=52.
            if (pc <= 32'd48)
                last_result = result;
        end

        // ----------------------------------------------------
        // Architectural checks
        // ----------------------------------------------------

        check_reg(0,  32'd0);   // x0 hardwired to zero
        check_reg(3,  32'd30);  // ADD
        check_reg(4,  32'd20);  // SUB
        check_reg(5,  32'd20);  // AND
        check_reg(6,  32'd30);  // OR
        check_reg(7,  32'd1);   // SLT positive
        check_reg(8,  32'd30);  // LW offset 0
        check_reg(9,  32'd30);  // LW offset 4
        check_reg(10, 32'd1);   // SLT negative
        check_reg(11, 32'd15);  // SUB with negative operand

        // ----------------------------------------------------
        // Store checks
        // ----------------------------------------------------

        if (dut.u_mmu.memory[0] !== 32'd30) begin
            $display(
                "FAIL: memory[0] = %h, expected 0000001e",
                dut.u_mmu.memory[0]
            );
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS: memory[0] = %h",
                dut.u_mmu.memory[0]
            );
        end

        if (dut.u_mmu.memory[4] !== 32'd30) begin
            $display(
                "FAIL: memory[4] = %h, expected 0000001e",
                dut.u_mmu.memory[4]
            );
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS: memory[4] = %h",
                dut.u_mmu.memory[4]
            );
        end

        // ----------------------------------------------------
        // PC check
        //
        // Thirteen instructions have executed, therefore after
        // the thirteenth rising edge PC should be 52.
        // ----------------------------------------------------

        if (pc !== 32'd52) begin
            $display(
                "FAIL: PC = %0d, expected 52",
                pc
            );
            errors = errors + 1;
        end
        else begin
            $display("PASS: PC = 52");
        end

        // ----------------------------------------------------
        // Final ALU result sanity check.
        //
        // The last executed real instruction is:
        //
        //     Unsupported R-type funct3=001
        //
        // Therefore the final ALU result is 0.
        // ----------------------------------------------------

        if (last_result !== 32'd0) begin
            $display(
                "FAIL: final ALU result = %h, expected 00000000",
                last_result
            );
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS: final ALU result = %h",
                last_result
            );
        end

        // ----------------------------------------------------
        // Final status
        // ----------------------------------------------------

        if (errors == 0) begin
            $display("");
            $display("CPU EXEC VERIFICATION PASSED");
        end
        else begin
            $display("");
            $display(
                "CPU EXEC VERIFICATION FAILED: %0d errors",
                errors
            );
        end

        $finish;
    end

endmodule