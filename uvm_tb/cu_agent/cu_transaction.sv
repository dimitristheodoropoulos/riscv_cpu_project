import uvm_pkg::*;
`include "uvm_macros.svh"

class cu_transaction extends uvm_sequence_item;
  rand logic [31:0] instruction;

  logic [3:0]  alu_op;
  logic [4:0]  rs1, rs2, rd;
  logic        is_fp;
  logic        mem_read;
  logic        mem_write;
  logic        reg_write;
  logic [31:0] imm_ext;

  `uvm_object_utils_begin(cu_transaction)
    `uvm_field_int(instruction, UVM_ALL_ON)
    `uvm_field_int(alu_op,      UVM_ALL_ON)
    `uvm_field_int(rs1,         UVM_ALL_ON)
    `uvm_field_int(rs2,         UVM_ALL_ON)
    `uvm_field_int(rd,          UVM_ALL_ON)
    `uvm_field_int(is_fp,       UVM_ALL_ON)
    `uvm_field_int(mem_read,    UVM_ALL_ON)
    `uvm_field_int(mem_write,   UVM_ALL_ON)
    `uvm_field_int(reg_write,   UVM_ALL_ON)
    `uvm_field_int(imm_ext,     UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "cu_transaction");
    super.new(name);
  endfunction
endclass