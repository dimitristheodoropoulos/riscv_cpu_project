`timescale 1ns/1ps

`include "register_file_coverage.sv"
`include "register_file_reference_model.sv"
`include "register_file_scoreboard.sv"
`include "register_file_assertions.sv"

module register_file_tb;

reg         clk;
reg         reset;

reg  [4:0]  read_addr1;
reg  [4:0]  read_addr2;

reg  [4:0]  write_addr;
reg  [31:0] write_data;

reg         write_enable;
reg         is_fp;

wire [31:0] read_data1;
wire [31:0] read_data2;

integer tests;
integer passed;

// --------------------------------------------------------
// Coverage model
// --------------------------------------------------------

register_file_coverage cov();

// --------------------------------------------------------
// Reference model + scoreboard
// --------------------------------------------------------

register_file_scoreboard sb();

// --------------------------------------------------------
// Assertion checker
//
// The assertion module is intentionally portless.
// Assertions are invoked procedurally by the testbench.
// --------------------------------------------------------

register_file_assertions assertions();

// --------------------------------------------------------
// DUT
// --------------------------------------------------------

register_file uut (
    .clk          (clk),
    .reset        (reset),

    .read_addr1   (read_addr1),
    .read_addr2   (read_addr2),

    .write_addr   (write_addr),
    .write_data   (write_data),

    .write_enable (write_enable),
    .is_fp        (is_fp),

    .read_data1   (read_data1),
    .read_data2   (read_data2)
);

// --------------------------------------------------------
// Clock generation
// --------------------------------------------------------

initial clk = 1'b0;

always #5 clk = ~clk;

// --------------------------------------------------------
// Reset task
//
// Reset is applied to both DUT and reference model.
//
// Assertion checks are performed explicitly after reset.
// --------------------------------------------------------

task apply_reset;

    begin

        reset        = 1'b1;
        write_enable = 1'b0;

        sb.reset();

        #1;

        @(posedge clk);

        #1;

        reset = 1'b0;

    end

endtask

// --------------------------------------------------------
// Write transaction
// --------------------------------------------------------

task write_register;

    input [4:0]  addr;
    input [31:0] data;
    input        fp;

    begin

        write_addr   = addr;
        write_data   = data;
        is_fp        = fp;
        write_enable = 1'b1;

        cov.sample_write(
            addr,
            fp
        );

        sb.observe_write(
            addr,
            data,
            fp,
            1'b1
        );

        @(posedge clk);

        #1;

        write_enable = 1'b0;

    end

endtask

// --------------------------------------------------------
// Read/check transaction
//
// The scoreboard owns functional PASS/FAIL checking.
//
// The assertion layer independently checks that read
// outputs contain no X/Z values.
//
// x0 assertions are handled explicitly by the test cases.
// --------------------------------------------------------

task check_read;

    input [4:0]    addr1;
    input [4:0]    addr2;

    input          fp;

    input [1023:0] test_name;

    begin

        tests = tests + 1;

        read_addr1 = addr1;
        read_addr2 = addr2;
        is_fp      = fp;

        cov.sample_read(
            addr1,
            addr2,
            fp
        );

        #1;

        // ------------------------------------------------
        // Independent scoreboard check
        // ------------------------------------------------

        sb.check_read(
            addr1,
            addr2,
            fp,
            read_data1,
            read_data2,
            test_name
        );

        if (sb.last_check_pass)
            passed = passed + 1;

        // ------------------------------------------------
        // Assertion: no X/Z on read outputs
        // ------------------------------------------------

        assertions.check_no_xz(
            read_data1,
            read_data2
        );

    end

endtask

// --------------------------------------------------------
// Main verification sequence
// --------------------------------------------------------

initial begin

    tests  = 0;
    passed = 0;

    reset = 1'b0;

    read_addr1 = 5'd0;
    read_addr2 = 5'd0;

    write_addr = 5'd0;
    write_data = 32'd0;

    write_enable = 1'b0;
    is_fp        = 1'b0;

    $display("========================================");
    $display("REGISTER FILE FUNCTIONAL VERIFICATION");
    $display("========================================");

    // ----------------------------------------------------
    // Reset
    // ----------------------------------------------------

    apply_reset();

    // ----------------------------------------------------
    // Integer reset verification
    // ----------------------------------------------------

    check_read(
        5'd1,
        5'd31,
        1'b0,
        "Integer registers reset to zero"
    );

    assertions.check_integer_reset(
        read_data1,
        read_data2
    );

    // ----------------------------------------------------
    // FP reset verification
    // ----------------------------------------------------

    check_read(
        5'd1,
        5'd31,
        1'b1,
        "FP registers reset to zero"
    );

    assertions.check_fp_reset(
        read_data1,
        read_data2
    );

    // ----------------------------------------------------
    // x0 must always read zero
    // ----------------------------------------------------

    check_read(
        5'd0,
        5'd0,
        1'b0,
        "Integer x0 hardwired to zero"
    );

    assertions.check_x0_read(
        read_data1,
        read_data2,
        1'b1,
        1'b1
    );

    // ----------------------------------------------------
    // Integer write/read
    // ----------------------------------------------------

    write_register(
        5'd1,
        32'h12345678,
        1'b0
    );

    check_read(
        5'd1,
        5'd1,
        1'b0,
        "Integer register write/read"
    );

    // ----------------------------------------------------
    // Second integer register
    // ----------------------------------------------------

    write_register(
        5'd15,
        32'hA5A5A5A5,
        1'b0
    );

    check_read(
        5'd1,
        5'd15,
        1'b0,
        "Independent integer registers"
    );

    // ----------------------------------------------------
    // Integer register 31
    // ----------------------------------------------------

    write_register(
        5'd31,
        32'hDEADBEEF,
        1'b0
    );

    check_read(
        5'd16,
        5'd31,
        1'b0,
        "Integer register 31"
    );

    // ----------------------------------------------------
    // FP register write/read
    // ----------------------------------------------------

    write_register(
        5'd1,
        32'h3F800000,
        1'b1
    );

    check_read(
        5'd1,
        5'd1,
        1'b1,
        "FP register write/read"
    );

    // ----------------------------------------------------
    // FP register 16
    // ----------------------------------------------------

    write_register(
        5'd16,
        32'h40000000,
        1'b1
    );

    check_read(
        5'd1,
        5'd16,
        1'b1,
        "Independent FP registers"
    );

    // ----------------------------------------------------
    // Integer / FP isolation
    // ----------------------------------------------------

    check_read(
        5'd1,
        5'd15,
        1'b0,
        "Integer state isolated from FP state"
    );

    check_read(
        5'd1,
        5'd16,
        1'b1,
        "FP state isolated from integer state"
    );

    // ----------------------------------------------------
    // x0 write must be ignored
    // ----------------------------------------------------

    write_register(
        5'd0,
        32'hFFFFFFFF,
        1'b0
    );

    check_read(
        5'd0,
        5'd1,
        1'b0,
        "Write to x0 is ignored"
    );

    assertions.check_x0_read(
        read_data1,
        read_data2,
        1'b1,
        1'b0
    );

    assertions.check_x0_write_ignored(
        read_data1
    );

    // ----------------------------------------------------
    // Write enable disabled
    //
    // Capture observable state before the disabled write.
    // ----------------------------------------------------

    read_addr1 = 5'd1;
    read_addr2 = 5'd1;
    is_fp      = 1'b0;

    #1;

    begin : disabled_write_check

        reg [31:0] before_data1;
        reg [31:0] before_data2;

        before_data1 = read_data1;
        before_data2 = read_data2;

        write_addr   = 5'd1;
        write_data   = 32'hFFFFFFFF;
        is_fp        = 1'b0;
        write_enable = 1'b0;

        @(posedge clk);

        #1;

        assertions.check_write_disabled_preserves(
            before_data1,
            before_data2,
            read_data1,
            read_data2
        );

    end

    check_read(
        5'd1,
        5'd1,
        1'b0,
        "Write disabled preserves register"
    );

    // ----------------------------------------------------
    // Overwrite integer register
    // ----------------------------------------------------

    write_register(
        5'd1,
        32'hCAFEBABE,
        1'b0
    );

    check_read(
        5'd1,
        5'd31,
        1'b0,
        "Integer register overwrite"
    );

    // ----------------------------------------------------
    // Reset again
    // ----------------------------------------------------

    apply_reset();

    // ----------------------------------------------------
    // Verify integer reset
    // ----------------------------------------------------

    check_read(
        5'd1,
        5'd31,
        1'b0,
        "Reset clears integer register state"
    );

    assertions.check_integer_reset(
        read_data1,
        read_data2
    );

    // ----------------------------------------------------
    // Verify FP reset
    // ----------------------------------------------------

    check_read(
        5'd1,
        5'd16,
        1'b1,
        "Reset clears FP register state"
    );

    assertions.check_fp_reset(
        read_data1,
        read_data2
    );

    // ----------------------------------------------------
    // Verify x0 after reset
    // ----------------------------------------------------

    check_read(
        5'd0,
        5'd0,
        1'b0,
        "x0 remains zero after reset"
    );

    assertions.check_x0_read(
        read_data1,
        read_data2,
        1'b1,
        1'b1
    );

    // ----------------------------------------------------
    // Scoreboard report
    // ----------------------------------------------------

    sb.report();

    // ----------------------------------------------------
    // Coverage report
    // ----------------------------------------------------

    cov.report();

    // ----------------------------------------------------
    // Assertion report
    // ----------------------------------------------------

    assertions.report();

    // ----------------------------------------------------
    // Verification summary
    // ----------------------------------------------------

    $display("");
    $display("========================================");
    $display("REGISTER FILE VERIFICATION SUMMARY");
    $display("========================================");

    $display(
        "Tests              : %0d",
        tests
    );

    $display(
        "Passed             : %0d",
        passed
    );

    $display(
        "Failed             : %0d",
        tests - passed
    );

    $display(
        "Scoreboard checks  : %0d",
        sb.checks
    );

    $display(
        "Scoreboard passed  : %0d",
        sb.passed
    );

    $display(
        "Scoreboard failures: %0d",
        sb.failed
    );

    $display(
        "Assertion checks   : %0d",
        assertions.assertion_checks
    );

    $display(
        "Assertion passed   : %0d",
        assertions.assertion_passed
    );

    $display(
        "Assertion failures : %0d",
        assertions.assertion_failed
    );

    $display("========================================");

    // ----------------------------------------------------
    // Verification gate
    //
    // The simulation passes only if:
    //
    // 1. Every functional test passed.
    // 2. Scoreboard has zero failures.
    // 3. Assertion layer has zero failures.
    // ----------------------------------------------------

    if ((passed != tests) ||
        (sb.failed != 0) ||
        (assertions.assertion_failed != 0)) begin

        $display("");
        $display("REGISTER FILE VERIFICATION FAILED");

        $fatal(1);

    end
    else begin

        $display("");
        $display("REGISTER FILE VERIFICATION PASSED");

    end

    $finish;

end

endmodule