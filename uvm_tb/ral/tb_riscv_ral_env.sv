`timescale 1ns/1ps

`include "uvm_macros.svh"

import uvm_pkg::*;
import riscv_ral_env_test_pkg::*;

module tb_riscv_ral_env;

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

        // Deterministic idle/reset state for standalone RAL connectivity test
        cpu_if.reset            = 1'b1;
        cpu_if.execution_enable = 1'b0;

        cpu_if.program_enable = 1'b0;
        cpu_if.program_addr   = 32'h00000000;
        cpu_if.program_data   = 32'h00000000;

        cpu_if.reg_init_enable = 1'b0;
        cpu_if.reg_init_addr   = 5'd0;
        cpu_if.reg_init_data   = 32'h00000000;
        cpu_if.reg_init_is_fp  = 1'b0;

        uvm_config_db#(virtual cpu_exec_if)::set(
            null,
            "*",
            "vif",
            cpu_if
        );

        run_test("riscv_ral_env_test");

    end

endmodule
