`timescale 1ns/1ps

module cpu_exec_wrapper_smoke_tb;

    logic clk;

    cpu_exec_if cpu_if (
        .clk(clk)
    );

    cpu_exec_uvm_wrapper dut (
        .cpu_if(cpu_if)
    );

    integer errors;

    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // --------------------------------------------------------
    // Program loading helper
    //
    // program_addr is a byte address.
    // --------------------------------------------------------

    task automatic load_instruction(
        input logic [31:0] addr,
        input logic [31:0] instruction
    );
        begin
            @(negedge clk);

            cpu_if.program_addr   = addr;
            cpu_if.program_data   = instruction;
            cpu_if.program_enable = 1'b1;

            @(posedge clk);

            #1;

            cpu_if.program_enable = 1'b0;
        end
    endtask

    // --------------------------------------------------------
    // Check PC
    // --------------------------------------------------------

    task automatic check_pc(
        input logic [31:0] expected,
        input string       name
    );
        begin
            if (cpu_if.pc !== expected) begin
                $display(
                    "FAIL: %s: PC = %h, expected %h",
                    name,
                    cpu_if.pc,
                    expected
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: %s: PC = %h",
                    name,
                    cpu_if.pc
                );
            end
        end
    endtask

    // --------------------------------------------------------
    // Check result
    // --------------------------------------------------------

    task automatic check_result(
        input logic [31:0] expected,
        input string       name
    );
        begin
            if (cpu_if.result !== expected) begin
                $display(
                    "FAIL: %s: Result = %h, expected %h",
                    name,
                    cpu_if.result,
                    expected
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: %s: Result = %h",
                    name,
                    cpu_if.result
                );
            end
        end
    endtask

    // --------------------------------------------------------
    // Register initialization helper
    // --------------------------------------------------------

    task automatic init_integer_register(
        input logic [4:0]  addr,
        input logic [31:0] data
    );
        begin
            @(negedge clk);

            cpu_if.reg_init_addr   = addr;
            cpu_if.reg_init_data   = data;
            cpu_if.reg_init_is_fp  = 1'b0;
            cpu_if.reg_init_enable = 1'b1;

            @(posedge clk);
            #1;

            cpu_if.reg_init_enable = 1'b0;
            cpu_if.reg_init_addr   = 5'd0;
            cpu_if.reg_init_data   = 32'h00000000;
        end
    endtask

    // --------------------------------------------------------
    // Instruction timing / architectural result check
    //
    // The wrapper commit_* signals are combinational observations
    // of the current DUT state. They therefore advance to the next
    // instruction after the execution posedge updates the PC.
    //
    // This probe instead samples the instruction before the edge
    // and checks the architectural result after NBA completion.
    // --------------------------------------------------------

    task automatic check_instruction_before_edge(
        input logic [31:0] expected_pc,
        input logic [31:0] expected_instruction,
        input logic [4:0]  expected_rd,
        input string       name
    );
        begin
            if (cpu_if.pc !== expected_pc) begin
                $display(
                    "FAIL: %s: pre-edge PC = %h, expected %h",
                    name,
                    cpu_if.pc,
                    expected_pc
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: %s: pre-edge PC = %h",
                    name,
                    cpu_if.pc
                );
            end

            if (cpu_if.commit_instruction !== expected_instruction) begin
                $display(
                    "FAIL: %s: pre-edge instruction = %h, expected %h",
                    name,
                    cpu_if.commit_instruction,
                    expected_instruction
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: %s: pre-edge instruction = %h",
                    name,
                    cpu_if.commit_instruction
                );
            end

            if (cpu_if.commit_rd !== expected_rd) begin
                $display(
                    "FAIL: %s: pre-edge rd = %0d, expected %0d",
                    name,
                    cpu_if.commit_rd,
                    expected_rd
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: %s: pre-edge rd = %0d",
                    name,
                    cpu_if.commit_rd
                );
            end

        end
    endtask

    task automatic check_architectural_result(
        input logic [31:0] expected_pc,
        input logic [31:0] expected_arch_value,
        input logic [4:0]  expected_arch_rd,
        input string       name
    );
        begin
            if (cpu_if.int_regs[expected_arch_rd] !== expected_arch_value) begin
                $display(
                    "FAIL: %s: post-NBA int_regs[%0d] = %h, expected %h",
                    name,
                    expected_arch_rd,
                    cpu_if.int_regs[expected_arch_rd],
                    expected_arch_value
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: %s: post-NBA int_regs[%0d] = %h",
                    name,
                    expected_arch_rd,
                    cpu_if.int_regs[expected_arch_rd]
                );
            end

            if (cpu_if.pc !== expected_pc) begin
                $display(
                    "FAIL: %s: post-NBA PC = %h, expected %h",
                    name,
                    cpu_if.pc,
                    expected_pc
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: %s: post-NBA PC = %h",
                    name,
                    cpu_if.pc
                );
            end
        end
    endtask

    // --------------------------------------------------------
    // Test
    // --------------------------------------------------------

    initial begin

        errors = 0;

        cpu_if.reset            = 1'b1;
        cpu_if.execution_enable = 1'b0;

        cpu_if.program_enable   = 1'b0;
        cpu_if.program_addr     = 32'd0;
        cpu_if.program_data     = 32'd0;

        cpu_if.reg_init_enable  = 1'b0;
        cpu_if.reg_init_addr    = 5'd0;
        cpu_if.reg_init_data    = 32'h00000000;
        cpu_if.reg_init_is_fp   = 1'b0;

        $display("========================================");
        $display("CPU TRACE TIMING SMOKE TEST");
        $display("========================================");

        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (2) @(posedge clk);
        #1;

        check_pc(
            32'h00000000,
            "PC after reset"
        );

        // ----------------------------------------------------
        // Program
        //
        // ADD x3, x1, x2
        // SUB x4, x3, x1
        //
        // ADD x3,x1,x2 = 0x002081B3
        // SUB x4,x3,x1 = 0x40118233
        // ----------------------------------------------------

        load_instruction(
            32'h00000000,
            32'h002081B3
        );

        load_instruction(
            32'h00000004,
            32'h40118233
        );

        // ----------------------------------------------------
        // Release reset before architectural register initialization.
        //
        // The register file ignores writes while reset is asserted.
        // ----------------------------------------------------

        @(negedge clk);
        cpu_if.reset = 1'b0;

        // ----------------------------------------------------
        // Initialize:
        //
        // x1 = 5
        // x2 = 7
        //
        // execution_enable remains deasserted, so initialization
        // cannot advance the architectural PC.
        // ----------------------------------------------------

        init_integer_register(
            5'd1,
            32'd5
        );

        init_integer_register(
            5'd2,
            32'd7
        );

        // ----------------------------------------------------
        // Enable execution.
        // ----------------------------------------------------

        @(negedge clk);
        cpu_if.execution_enable = 1'b1;

        // ----------------------------------------------------
        // Instruction 0:
        //
        // ADD x3, x1, x2
        //
        // Expected architectural commit:
        //   PC          = 0x00000000
        //   instruction = 0x002081B3
        //   rd          = x3
        //   rd_we       = 1
        //   rd_value    = 12
        //
        // Expected post-NBA architectural state:
        //   x3 = 12
        // ----------------------------------------------------

        check_instruction_before_edge(
            32'h00000000,
            32'h002081B3,
            5'd3,
            "ADD x3,x1,x2"
        );

        @(posedge clk);
        #1;

        check_architectural_result(
            32'h00000004,
            32'd12,
            5'd3,
            "ADD x3,x1,x2"
        );

        // ----------------------------------------------------
        // Instruction 1:
        //
        // SUB x4, x3, x1
        //
        // x3 = 12, x1 = 5 -> x4 = 7
        // ----------------------------------------------------

        check_instruction_before_edge(
            32'h00000004,
            32'h40118233,
            5'd4,
            "SUB x4,x3,x1"
        );

        @(posedge clk);
        #1;

        check_architectural_result(
            32'h00000008,
            32'd7,
            5'd4,
            "SUB x4,x3,x1"
        );

        // ----------------------------------------------------
        // Summary
        // ----------------------------------------------------

        $display("========================================");

        if (errors == 0) begin
            $display("CPU TRACE TIMING SMOKE PASSED");
            $finish;
        end
        else begin
            $display(
                "CPU TRACE TIMING SMOKE FAILED: %0d errors",
                errors
            );
        end

        $display("========================================");

        if (errors != 0)
            $fatal(1);
    end

endmodule
