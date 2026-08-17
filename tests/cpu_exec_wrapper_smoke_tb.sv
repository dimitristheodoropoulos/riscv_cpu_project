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
    // Test
    // --------------------------------------------------------

    initial begin

        errors = 0;

        cpu_if.reset          = 1'b1;
        cpu_if.program_enable = 1'b0;
        cpu_if.program_addr   = 32'd0;
        cpu_if.program_data   = 32'd0;

        $display("========================================");
        $display("CPU EXEC WRAPPER SMOKE TEST");
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
        // AND x5, x3, x2
        // OR  x6, x3, x2
        //
        // Encodings:
        //
        // ADD x3,x1,x2 = 0x002081B3
        // SUB x4,x3,x1 = 0x40118233
        // AND x5,x3,x2 = 0x0021F2B3
        // OR  x6,x3,x2 = 0x0021E333
        // ----------------------------------------------------

        load_instruction(
            32'h00000000,
            32'h002081B3
        );

        load_instruction(
            32'h00000004,
            32'h40118233
        );

        load_instruction(
            32'h00000008,
            32'h0021F2B3
        );

        load_instruction(
            32'h0000000C,
            32'h0021E333
        );

        // ----------------------------------------------------
        // Release reset
        // ----------------------------------------------------

        @(negedge clk);
        cpu_if.reset = 1'b0;

        // ----------------------------------------------------
        // Execution
        // ----------------------------------------------------

        @(posedge clk);
        #1;

        check_pc(
            32'h00000004,
            "PC after instruction 0"
        );

        // Result of ADD depends on register-file initial state.
        // The current register file reset initializes registers
        // to zero, therefore:
        //
        // x3 = x1 + x2 = 0
        //
        check_result(
            32'h00000000,
            "ADD result"
        );

        @(posedge clk);
        #1;

        check_pc(
            32'h00000008,
            "PC after instruction 1"
        );

        check_result(
            32'h00000000,
            "SUB result"
        );

        @(posedge clk);
        #1;

        check_pc(
            32'h0000000C,
            "PC after instruction 2"
        );

        check_result(
            32'h00000000,
            "AND result"
        );

        @(posedge clk);
        #1;

        check_pc(
            32'h00000010,
            "PC after instruction 3"
        );

        check_result(
            32'h00000000,
            "OR result"
        );

        // ----------------------------------------------------
        // Summary
        // ----------------------------------------------------

        $display("========================================");

        if (errors == 0) begin
            $display("CPU EXEC WRAPPER SMOKE PASSED");
        end
        else begin
            $display(
                "CPU EXEC WRAPPER SMOKE FAILED: %0d errors",
                errors
            );
        end

        $display("========================================");

        if (errors != 0)
            $fatal(1);

        $finish;

    end

endmodule
