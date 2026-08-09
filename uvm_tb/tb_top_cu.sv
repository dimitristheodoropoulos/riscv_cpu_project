`timescale 1ns/1ps
import uvm_pkg::*;
`include "uvm_macros.svh"

`include "cu_transaction.sv"
`include "cu_driver.sv"
`include "cu_monitor.sv"
`include "cu_sequencer.sv"
`include "cu_agent.sv"
`include "cu_sequence.sv"
`include "cu_scoreboard.sv"
`include "cu_env.sv"
`include "cu_test.sv"

module tb_top_cu;
  logic clk;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  cu_if intf(clk);

  cu dut (
    .instruction(intf.instruction),
    .ALU_op(intf.alu_op),
    .rs1(intf.rs1),
    .rs2(intf.rs2),
    .rd(intf.rd),
    .is_fp(intf.is_fp),
    .mem_read(intf.mem_read),
    .mem_write(intf.mem_write),
    .reg_write(intf.reg_write),
    .imm_ext(intf.imm_ext)
  );

  initial begin
    uvm_config_db#(virtual cu_if)::set(null, "*", "vif", intf);
    run_test("cu_test");
  end
endmodule