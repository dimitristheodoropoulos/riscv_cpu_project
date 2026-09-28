`timescale 1ns/1ps

`include "uvm_macros.svh"

import uvm_pkg::*;
import riscv_ral_semantic_test_pkg::*;

module tb_riscv_ral_semantic;

    initial begin

        run_test("riscv_ral_semantic_test");

    end

endmodule
