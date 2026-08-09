import uvm_pkg::*;
`include "uvm_macros.svh"

class alu_agent extends uvm_agent;
  `uvm_component_utils(alu_agent)

  alu_driver    driver;
  alu_monitor   monitor;
  alu_sequencer sequencer;

  function new(string name = "alu_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = alu_monitor::type_id::create("monitor", this);
    
    if (get_is_active() == UVM_ACTIVE) begin
      driver    = alu_driver::type_id::create("driver", this);
      sequencer = alu_sequencer::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction
endclass
