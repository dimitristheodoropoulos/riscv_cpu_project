`include "uvm_macros.svh"

import uvm_pkg::*;
import fpu_pkg::*;
import fpu_smoke_test_pkg::*;

module tb_top_fpu;

    bit clk;

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
    end

    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // FPU interface
    // ------------------------------------------------------------
    fpu_if fpu_vif (
        .clk(clk)
    );

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    fpu dut (
        .clk    (clk),
        .rst    (fpu_vif.rst),
        .a      (fpu_vif.a),
        .b      (fpu_vif.b),
        .op      (fpu_vif.op),
        .result (fpu_vif.result),
        .ready  (fpu_vif.ready)
    );

    // ------------------------------------------------------------
    // SVA
    //
    // Assertions monitor the same signals used by the DUT.
    // ------------------------------------------------------------
    fpu_sva sva (
        .clk    (clk),
        .rst    (fpu_vif.rst),
        .a      (fpu_vif.a),
        .b      (fpu_vif.b),
        .op      (fpu_vif.op),
        .result (fpu_vif.result),
        .ready  (fpu_vif.ready)
    );

    // ------------------------------------------------------------
    // Reset and initial values
    // ------------------------------------------------------------
    initial begin

        fpu_vif.rst = 1'b1;
        fpu_vif.a   = 32'b0;
        fpu_vif.b   = 32'b0;
        fpu_vif.op  = 3'b000;

        // Hold reset for two clock cycles.
        #20;

        fpu_vif.rst = 1'b0;

    end

    // ------------------------------------------------------------
    // UVM configuration + test selection
    //
    // The test is selected from the command line:
    //
    //   +UVM_TESTNAME=fpu_smoke_test
    //   +UVM_TESTNAME=fpu_regression_test
    //   +UVM_TESTNAME=fpu_corner_case_test
    //   +UVM_TESTNAME=fpu_long_regression_test
    //   +UVM_TESTNAME=fpu_closure_test
    //
    // Do NOT hard-code a specific test here.
    // ------------------------------------------------------------
    initial begin

        uvm_config_db #(virtual fpu_if)::set(
            null,
            "*",
            "vif",
            fpu_vif
        );

        run_test();

    end

endmodule