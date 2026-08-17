`timescale 1ns/1ps

`include "uvm_macros.svh"

module tb_top_cpu_exec;

    import uvm_pkg::*;
    import cpu_exec_test_pkg::*;

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    logic clk;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // CPU execution interface
    // ------------------------------------------------------------

    cpu_exec_if cpu_if (
        .clk(clk)
    );

    // ------------------------------------------------------------
    // CPU UVM wrapper / DUT
    // ------------------------------------------------------------

    cpu_exec_uvm_wrapper dut_wrapper (
        .cpu_if(cpu_if)
    );

    // ------------------------------------------------------------
    // UVM virtual-interface configuration
    // ------------------------------------------------------------

    initial begin

        uvm_config_db#(virtual cpu_exec_if)::set(
            null,
            "*",
            "vif",
            cpu_if
        );

        run_test("cpu_exec_test");

    end

endmodule