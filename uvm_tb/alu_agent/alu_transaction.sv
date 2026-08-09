import uvm_pkg::*;
`include "uvm_macros.svh"

class alu_transaction extends uvm_sequence_item;
  // Τυχαία παραγόμενα πεδία εισόδου
  rand logic [31:0] a;
  rand logic [31:0] b;
  rand logic [3:0]  alu_control;
  
  // Πεδία εξόδου
  logic [31:0] result;
  logic        zero;
  logic        overflow;

  // UVM Automation Macros
  `uvm_object_utils_begin(alu_transaction)
    `uvm_field_int(a, UVM_ALL_ON)
    `uvm_field_int(b, UVM_ALL_ON)
    `uvm_field_int(alu_control, UVM_ALL_ON)
    `uvm_field_int(result, UVM_ALL_ON)
    `uvm_field_int(zero, UVM_ALL_ON)
    `uvm_field_int(overflow, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "alu_transaction");
    super.new(name);
  endfunction
endclass
