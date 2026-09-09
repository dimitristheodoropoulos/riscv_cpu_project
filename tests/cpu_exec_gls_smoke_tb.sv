`timescale 1ns/1ps

module cpu_exec_gls_smoke_tb;

    logic        clk;
    logic        reset;
    logic        execution_enable;

    logic        instr_mem_we;
    logic [5:0]  instr_mem_waddr;
    logic [31:0] instr_mem_wdata;

    logic        reg_init_enable;
    logic [4:0]  reg_init_addr;
    logic [31:0] reg_init_data;
    logic        reg_init_is_fp;

    wire [31:0]  pc;
    wire [31:0]  result;

    cpu_exec_core dut (
        .clk              (clk),
        .reset            (reset),
        .execution_enable (execution_enable),

        .instr_mem_we     (instr_mem_we),
        .instr_mem_waddr  (instr_mem_waddr),
        .instr_mem_wdata  (instr_mem_wdata),

        .reg_init_enable  (reg_init_enable),
        .reg_init_addr    (reg_init_addr),
        .reg_init_data    (reg_init_data),
        .reg_init_is_fp   (reg_init_is_fp),

        .pc               (pc),
        .result           (result)
    );

    always #5 clk = ~clk;

    task automatic program_instruction(
        input logic [5:0]  addr,
        input logic [31:0] data
    );
        begin
            @(negedge clk);
            instr_mem_waddr = addr;
            instr_mem_wdata = data;
            instr_mem_we    = 1'b1;

            @(posedge clk);
            #1;

            instr_mem_we = 1'b0;
        end
    endtask

    task automatic init_int_reg(
        input logic [4:0]  addr,
        input logic [31:0] data
    );
        begin
            @(negedge clk);
            reg_init_addr   = addr;
            reg_init_data   = data;
            reg_init_is_fp  = 1'b0;
            reg_init_enable = 1'b1;

            @(posedge clk);
            #1;

            reg_init_enable = 1'b0;
        end
    endtask

    task automatic check_result(
        input string       name,
        input logic [31:0] expected
    );
        begin
            if (result !== expected) begin
                $error(
                    "GLS FAIL: %s result=%h expected=%h",
                    name,
                    result,
                    expected
                );
                $fatal(1);
            end

            $display(
                "GLS PASS: %s result=%h",
                name,
                result
            );
        end
    endtask

    initial begin

        clk              = 1'b0;
        reset            = 1'b1;
        execution_enable = 1'b0;

        instr_mem_we     = 1'b0;
        instr_mem_waddr  = 6'd0;
        instr_mem_wdata  = 32'd0;

        reg_init_enable  = 1'b0;
        reg_init_addr    = 5'd0;
        reg_init_data    = 32'd0;
        reg_init_is_fp   = 1'b0;

        $display("========================================");
        $display("GLS RV32I ALU SMOKE TEST");
        $display("========================================");

        repeat (2) @(posedge clk);
        #1;
        reset = 1'b0;

        /*
         * Program the same seven instructions already validated
         * by the DUT-to-Spike differential test.
         */
        program_instruction(6'd0, 32'h002081B3); // ADD x3,x1,x2
        program_instruction(6'd1, 32'h40218233); // SUB x4,x3,x2
        program_instruction(6'd2, 32'h0020F2B3); // AND x5,x1,x2
        program_instruction(6'd3, 32'h0020E3B3); // OR  x7,x1,x2
        program_instruction(6'd4, 32'h0020C433); // XOR x8,x1,x2
        program_instruction(6'd5, 32'h006114B3); // SLL x9,x2,x6
        program_instruction(6'd6, 32'h00112533); // SLT x10,x2,x1
        program_instruction(6'd7, 32'h00302023); // SW  x3,0(x0)
        program_instruction(6'd8, 32'h00002583); // LW  x11,0(x0)

        /*
         * Architectural register initialization:
         * x1 = 10
         * x2 = 7
         * x6 = 5
         */
        init_int_reg(5'd1, 32'd10);
        init_int_reg(5'd2, 32'd7);
        init_int_reg(5'd6, 32'd5);

        /*
         * Start execution only after programming and initialization
         * are complete.
         */
        @(negedge clk);
        execution_enable = 1'b1;

        /*
         * The ALU result is combinational and corresponds to the
         * instruction currently addressed by PC. Therefore the
         * instruction result must be sampled BEFORE the rising edge
         * that advances PC to the next instruction.
         *
         * After each rising edge, verify the architectural PC advance.
         */

        check_result("ADD x3,x1,x2", 32'h00000011);
        @(posedge clk);
        #1;
        if (pc !== 32'h00000004) begin
            $error("GLS FAIL: PC after ADD=%h expected=%h",
                   pc, 32'h00000004);
            $fatal(1);
        end

        check_result("SUB x4,x3,x2", 32'h0000000A);
        @(posedge clk);
        #1;
        if (pc !== 32'h00000008) begin
            $error("GLS FAIL: PC after SUB=%h expected=%h",
                   pc, 32'h00000008);
            $fatal(1);
        end

        check_result("AND x5,x1,x2", 32'h00000002);
        @(posedge clk);
        #1;
        if (pc !== 32'h0000000C) begin
            $error("GLS FAIL: PC after AND=%h expected=%h",
                   pc, 32'h0000000C);
            $fatal(1);
        end

        check_result("OR x7,x1,x2", 32'h0000000F);
        @(posedge clk);
        #1;
        if (pc !== 32'h00000010) begin
            $error("GLS FAIL: PC after OR=%h expected=%h",
                   pc, 32'h00000010);
            $fatal(1);
        end

        check_result("XOR x8,x1,x2", 32'h0000000D);
        @(posedge clk);
        #1;
        if (pc !== 32'h00000014) begin
            $error("GLS FAIL: PC after XOR=%h expected=%h",
                   pc, 32'h00000014);
            $fatal(1);
        end

        check_result("SLL x9,x2,x6", 32'h000000E0);
        @(posedge clk);
        #1;
        if (pc !== 32'h00000018) begin
            $error("GLS FAIL: PC after SLL=%h expected=%h",
                   pc, 32'h00000018);
            $fatal(1);
        end

        check_result("SLT x10,x2,x1", 32'h00000001);
        @(posedge clk);
        #1;

        if (pc !== 32'h0000001C) begin
            $error(
                "GLS FAIL: final PC=%h expected=%h",
                pc,
                32'h0000001C
            );
            $fatal(1);
        end

        /*
         * Architectural GLS checks.
         *
         * The synthesized/mapped netlist does not expose register-file
         * and MMU memories as portable hierarchical observability points
         * under Icarus. Therefore GLS observes only the CPU top-level
         * architectural outputs: result and PC.
         *
         * RF and MMU state are verified separately by the RTL integration
         * testbench (tests/cpu_exec_tb.sv).
         */

        /*
         * Execute SW x3,0(x0).
         *
         * For this CPU, result is the ALU result / effective address.
         * Therefore SW x3,0(x0) must produce address 0.
         */
        check_result("SW x3,0(x0) effective address", 32'h00000000);
        @(posedge clk);
        #1;

        if (pc !== 32'h00000020) begin
            $error(
                "GLS FAIL: PC after SW=%h expected=%h",
                pc,
                32'h00000020
            );
            $fatal(1);
        end

        /*
         * Execute LW x11,0(x0).
         *
         * result remains the effective address in this CPU
         * (0 for this instruction), while the actual load-data
         * writeback is verified by the RTL integration test.
         */
        check_result("LW x11,0(x0) effective address", 32'h00000000);
        @(posedge clk);
        #1;

        if (pc !== 32'h00000024) begin
            $error(
                "GLS FAIL: PC after LW=%h expected=%h",
                pc,
                32'h00000024
            );
            $fatal(1);
        end

        $display("GLS PASS: ALU result=%h", result);
        $display("GLS PASS: final PC=%h", pc);
        $display("GLS RV32I ARCHITECTURAL GLS SMOKE PASSED");

        $finish;
    end

endmodule
