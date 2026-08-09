`timescale 1ns/1ps
import uvm_pkg::*;
`include "uvm_macros.svh"

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

module tb_top;
  logic clk;

  // Clock Generation (100MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Interface Instance
  alu_if intf(clk);

  // Design Under Test (DUT) Instance
  alu dut (
    .A(intf.a),
    .B(intf.b),
    .Op(intf.alu_control),
    .Result(intf.result),
    .zero(intf.zero),
    .overflow(intf.overflow)
  );

  initial begin
    // Pass Virtual Interface to UVM DB
    uvm_config_db#(virtual alu_if)::set(null, "*", "vif", intf);

    // Start UVM Simulation
    run_test("alu_test");
  end
endmodule