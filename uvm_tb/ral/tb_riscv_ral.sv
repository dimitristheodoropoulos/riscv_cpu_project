`timescale 1ns/1ps

`include "uvm_macros.svh"

import uvm_pkg::*;
import riscv_ral_test_pkg::*;

module tb_riscv_ral;

    logic clk;

    cpu_exec_if cpu_if(clk);

    cpu_exec_uvm_wrapper dut_wrapper (
        .cpu_if(cpu_if)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin

        uvm_config_db#(virtual cpu_exec_if)::set(
            null,
            "*",
            "vif",
            cpu_if
        );

        run_test("riscv_ral_smoke_test");

    end

endmodule
