`timescale 1ns/1ps

`include "mmu_coverage.sv"

module mmu_tb;

    reg         clk;
    reg  [31:0] virtual_addr;
    reg  [31:0] data_in;
    reg         mem_read;
    reg         mem_write;

    wire [31:0] data_out;
    wire [31:0] physical_addr;
    wire        mem_ready;

    integer tests;
    integer passed;

    // --------------------------------------------------------
    // Coverage model instance
    // --------------------------------------------------------
    mmu_coverage cov();

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    mmu uut (
        .clk(clk),
        .virtual_addr(virtual_addr),
        .data_in(data_in),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .data_out(data_out),
        .physical_addr(physical_addr),
        .mem_ready(mem_ready)
    );

    // --------------------------------------------------------
    // Clock generation
    // --------------------------------------------------------

    initial clk = 0;
    always #5 clk = ~clk;

    // --------------------------------------------------------
    // WRITE transaction
    // --------------------------------------------------------

    task write_word;
        input [31:0] addr;
        input [31:0] data;

        begin

            // Drive inputs before active clock edge.
            virtual_addr = addr;
            data_in      = data;
            mem_write    = 1'b1;
            mem_read     = 1'b0;

            // Update functional coverage.
            cov.sample_write(addr);

            // DUT samples write here.
            @(posedge clk);

            // Deassert after sampling edge.
            #1;
            mem_write = 1'b0;

        end

    endtask

    // --------------------------------------------------------
    // READ transaction + self-checking
    // --------------------------------------------------------

    task check_read;
        input [31:0] addr;
        input [31:0] expected;
        input [255:0] test_name;

        begin

            tests = tests + 1;

            // Drive read request.
            virtual_addr = addr;
            mem_read     = 1'b1;
            mem_write    = 1'b0;

            // Update functional coverage.
            cov.sample_read(addr);

            // Combinational read settle.
            #1;

            // Self-checking comparison.
            if (data_out === expected) begin

                passed = passed + 1;

                $display(
                    "PASS: %s | addr=%0d expected=%0d got=%0d",
                    test_name,
                    addr,
                    expected,
                    data_out
                );

            end
            else begin

                $display(
                    "FAIL: %s | addr=%0d expected=%0d got=%0d",
                    test_name,
                    addr,
                    expected,
                    data_out
                );

            end

            // End read request.
            mem_read = 1'b0;

        end

    endtask

    // --------------------------------------------------------
    // Test sequence
    // --------------------------------------------------------

    initial begin

        tests  = 0;
        passed = 0;

        virtual_addr = 32'd0;
        data_in      = 32'd0;
        mem_read     = 1'b0;
        mem_write    = 1'b0;

        $display("========================================");
        $display("MMU Functional Verification");
        $display("========================================");

        // ----------------------------------------------------
        // Basic write/read at address 10
        // ----------------------------------------------------

        write_word(
            32'd10,
            32'd42
        );

        check_read(
            32'd10,
            32'd42,
            "Basic write/read (addr=10)"
        );

        // ----------------------------------------------------
        // Second address
        // ----------------------------------------------------

        write_word(
            32'd20,
            32'd84
        );

        check_read(
            32'd20,
            32'd84,
            "Second write/read (addr=20)"
        );

        // ----------------------------------------------------
        // Address 10 remains unchanged
        // ----------------------------------------------------

        check_read(
            32'd10,
            32'd42,
            "Address 10 unaffected by later write"
        );

        // ----------------------------------------------------
        // Overwrite address 10
        // ----------------------------------------------------

        write_word(
            32'd10,
            32'd99
        );

        check_read(
            32'd10,
            32'd99,
            "Overwrite address 10"
        );

        // ----------------------------------------------------
        // Boundary address 255
        // ----------------------------------------------------

        write_word(
            32'd255,
            32'hDEADBEEF
        );

        check_read(
            32'd255,
            32'hDEADBEEF,
            "Boundary address 255"
        );

        // ----------------------------------------------------
        // Address masking
        //
        // 256 -> physical_addr[7:0] == 0
        // ----------------------------------------------------

        write_word(
            32'd256,
            32'hCAFEF00D
        );

        check_read(
            32'd0,
            32'hCAFEF00D,
            "Address masking: 256 wraps to index 0"
        );

        // ----------------------------------------------------
        // Idle state
        // ----------------------------------------------------

        virtual_addr = 32'd10;
        mem_read     = 1'b0;
        mem_write    = 1'b0;

        #1;

        tests = tests + 1;

        if (data_out === 32'b0) begin

            passed = passed + 1;

            $display(
                "PASS: Idle state (mem_read=0, mem_write=0) -> data_out=0"
            );

        end
        else begin

            $display(
                "FAIL: Idle state (mem_read=0, mem_write=0) -> data_out=%0d (expected 0)",
                data_out
            );

        end

        // ----------------------------------------------------
        // Functional coverage report
        // ----------------------------------------------------

        cov.report();

        // ----------------------------------------------------
        // Verification summary
        // ----------------------------------------------------

        $display("");
        $display("========================================");
        $display("MMU VERIFICATION SUMMARY");
        $display("========================================");

        $display("Tests : %0d", tests);
        $display("Passed: %0d", passed);
        $display("Failed: %0d", tests - passed);

        $display("========================================");

        // ----------------------------------------------------
        // Verification gate
        // ----------------------------------------------------

        if (passed != tests) begin

            $display("MMU VERIFICATION FAILED");
            $fatal(1);

        end
        else begin

            $display("MMU VERIFICATION PASSED");

        end

        $finish;

    end

endmodule
