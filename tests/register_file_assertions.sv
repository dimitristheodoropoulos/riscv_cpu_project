// ========================================================
// REGISTER FILE ASSERTION CHECKER
//
// Deterministic procedural assertion layer.
//
// The checker intentionally avoids SystemVerilog concurrent
// assertions so that it remains compatible with Icarus Verilog.
//
// Checks:
//   1. Integer x0 always reads zero.
//   2. Integer x0 writes are ignored.
//   3. Reset clears integer register state.
//   4. Reset clears FP register state.
//   5. Disabled writes preserve register state.
//   6. Read outputs contain no X/Z.
//
// ========================================================

module register_file_assertions;

// --------------------------------------------------------
// Statistics
// --------------------------------------------------------

integer assertion_checks;
integer assertion_passed;
integer assertion_failed;

// --------------------------------------------------------
// Initialization
// --------------------------------------------------------

initial begin

    assertion_checks = 0;
    assertion_passed = 0;
    assertion_failed = 0;

end

// --------------------------------------------------------
// Internal PASS helper
// --------------------------------------------------------

task pass;

    input [1023:0] name;

    begin

        assertion_checks = assertion_checks + 1;
        assertion_passed = assertion_passed + 1;

        $display(
            "ASSERT PASS: %0s",
            name
        );

    end

endtask

// --------------------------------------------------------
// Internal FAIL helper
// --------------------------------------------------------

task fail;

    input [1023:0] name;

    begin

        assertion_checks = assertion_checks + 1;
        assertion_failed = assertion_failed + 1;

        $display(
            "ASSERT FAIL: %0s",
            name
        );

    end

endtask

// --------------------------------------------------------
// Assertion 1
//
// Integer x0 must always read zero.
//
// The testbench provides the observed read values and
// indicates which read ports are currently selecting x0.
// --------------------------------------------------------

task check_x0_read;

    input [31:0] read_data1;
    input [31:0] read_data2;
    input        check_port1;
    input        check_port2;

    begin

        if (check_port1) begin

            if (read_data1 === 32'd0)
                pass("Integer x0 read port 1 is zero");
            else
                fail("Integer x0 read port 1 is zero");

        end

        if (check_port2) begin

            if (read_data2 === 32'd0)
                pass("Integer x0 read port 2 is zero");
            else
                fail("Integer x0 read port 2 is zero");

        end

    end

endtask

// --------------------------------------------------------
// Assertion 2
//
// Integer x0 writes must be ignored.
//
// The testbench provides the observed value of x0 after
// the write clock edge.
// --------------------------------------------------------

task check_x0_write_ignored;

    input [31:0] read_data;

    begin

        if (read_data === 32'd0)
            pass("Integer x0 write is ignored");
        else
            fail("Integer x0 write is ignored");

    end

endtask

// --------------------------------------------------------
// Assertion 3
//
// Reset must clear integer register state.
// --------------------------------------------------------

task check_integer_reset;

    input [31:0] read_data1;
    input [31:0] read_data2;

    begin

        if ((read_data1 === 32'd0) &&
            (read_data2 === 32'd0)) begin

            pass("Reset clears integer register reads");

        end
        else begin

            fail("Reset clears integer register reads");

        end

    end

endtask

// --------------------------------------------------------
// Assertion 4
//
// Reset must clear FP register state.
// --------------------------------------------------------

task check_fp_reset;

    input [31:0] read_data1;
    input [31:0] read_data2;

    begin

        if ((read_data1 === 32'd0) &&
            (read_data2 === 32'd0)) begin

            pass("Reset clears FP register reads");

        end
        else begin

            fail("Reset clears FP register reads");

        end

    end

endtask

// --------------------------------------------------------
// Assertion 5
//
// A disabled write must preserve the observable state.
// --------------------------------------------------------

task check_write_disabled_preserves;

    input [31:0] before_data1;
    input [31:0] before_data2;

    input [31:0] after_data1;
    input [31:0] after_data2;

    begin

        if ((before_data1 === after_data1) &&
            (before_data2 === after_data2)) begin

            pass("Write disabled preserves register state");

        end
        else begin

            fail("Write disabled preserves register state");

        end

    end

endtask

// --------------------------------------------------------
// Assertion 6
//
// Read outputs must not contain X or Z.
//
// Reduction XOR returns X if any bit is X or Z.
// --------------------------------------------------------

task check_no_xz;

    input [31:0] read_data1;
    input [31:0] read_data2;

    begin

        if ((^read_data1) !== 1'bx)
            pass("Read data port 1 contains no X/Z");
        else
            fail("Read data port 1 contains no X/Z");

        if ((^read_data2) !== 1'bx)
            pass("Read data port 2 contains no X/Z");
        else
            fail("Read data port 2 contains no X/Z");

    end

endtask

// --------------------------------------------------------
// Final assertion report
// --------------------------------------------------------

task report;

    begin

        $display("");
        $display("========================================");
        $display("REGISTER FILE ASSERTION SUMMARY");
        $display("========================================");

        $display(
            "Checks : %0d",
            assertion_checks
        );

        $display(
            "Passed : %0d",
            assertion_passed
        );

        $display(
            "Failed : %0d",
            assertion_failed
        );

        if (assertion_failed == 0)
            $display("Assertions: PASSED");
        else
            $display("Assertions: FAILED");

        $display("========================================");

    end

endtask

endmodule