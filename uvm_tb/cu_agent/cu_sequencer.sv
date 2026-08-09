import uvm_pkg::*;
`include "uvm_macros.svh"

class cu_sequencer extends uvm_sequencer #(cu_transaction);
  `uvm_component_utils(cu_sequencer)

  function new(string name = "cu_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass