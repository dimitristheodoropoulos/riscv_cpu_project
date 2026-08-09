`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

// CU UVM components
`include "cu_transaction.sv"
`include "cu_driver.sv"
`include "cu_monitor.sv"
`include "cu_sequencer.sv"
`include "cu_agent.sv"
`include "cu_sequence.sv"
`include "cu_scoreboard.sv"
`include "cu_env.sv"
`include "cu_test.sv"

// SVA
`include "../../sva/cu_assertions.sv"

module tb_top_cu;

  logic clk;

  // ------------------------------------------------------------
  // Clock Generation
  // 100 MHz clock: 10 ns period
  // ------------------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // ------------------------------------------------------------
  // Interface Instance
  // ------------------------------------------------------------
  cu_if intf(clk);

  // ------------------------------------------------------------
  // Design Under Test
  // ------------------------------------------------------------
  cu dut (
    .instruction (intf.instruction),
    .ALU_op      (intf.alu_op),
    .rs1         (intf.rs1),
    .rs2         (intf.rs2),
    .rd          (intf.rd),
    .is_fp       (intf.is_fp),
    .mem_read    (intf.mem_read),
    .mem_write   (intf.mem_write),
    .reg_write   (intf.reg_write),
    .imm_ext     (intf.imm_ext)
  );

  // ------------------------------------------------------------
  // CU SystemVerilog Assertions
  //
  // Explicitly reference tb_top_cu.clk.
  // The bound cu module itself does not contain a clock.
  // ------------------------------------------------------------
  bind cu cu_assertions u_cu_sva (
    .clk        (tb_top_cu.clk),
    .instruction(instruction),
    .ALU_op     (ALU_op),
    .rs1        (rs1),
    .rs2        (rs2),
    .rd         (rd),
    .mem_read   (mem_read),
    .mem_write  (mem_write),
    .reg_write  (reg_write)
  );

  // ------------------------------------------------------------
  // UVM Configuration + Test Start
  // ------------------------------------------------------------
  initial begin

    // Pass Virtual Interface to UVM configuration database
    uvm_config_db#(virtual cu_if)::set(
      null,
      "*",
      "vif",
      intf
    );

    // Start UVM test
    run_test("cu_test");

  end

endmodule