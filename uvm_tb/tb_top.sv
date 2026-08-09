`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

// ALU UVM components
`include "alu_transaction.sv"
`include "alu_driver.sv"
`include "alu_monitor.sv"
`include "alu_sequencer.sv"
`include "alu_agent.sv"
`include "alu_sequence.sv"
`include "alu_scoreboard.sv"
`include "alu_coverage.sv"
`include "alu_env.sv"
`include "alu_test.sv"

// SVA
`include "../../sva/alu_assertions.sv"

module tb_top;

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
  alu_if intf(clk);

  // ------------------------------------------------------------
  // Design Under Test
  // ------------------------------------------------------------
  alu dut (
    .A        (intf.a),
    .B        (intf.b),
    .Op       (intf.alu_control),
    .Result   (intf.result),
    .zero     (intf.zero),
    .overflow (intf.overflow)
  );

  // ------------------------------------------------------------
  // ALU SystemVerilog Assertions
  //
  // Explicitly reference tb_top.clk.
  // The bound alu module itself does not contain a clock.
  // ------------------------------------------------------------
  bind alu alu_assertions u_alu_sva (
    .clk      (tb_top.clk),
    .A        (A),
    .B        (B),
    .Result   (Result),
    .Op        (Op),
    .zero     (zero),
    .overflow (overflow)
  );

  // ------------------------------------------------------------
  // UVM Configuration + Test Start
  // ------------------------------------------------------------
  initial begin

    // Pass Virtual Interface to UVM configuration database
    uvm_config_db#(virtual alu_if)::set(
      null,
      "*",
      "vif",
      intf
    );

    // Start UVM test
    run_test("alu_test");

  end

endmodule