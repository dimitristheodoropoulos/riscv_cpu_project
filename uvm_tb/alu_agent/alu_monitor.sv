import uvm_pkg::*;
`include "uvm_macros.svh"

class alu_monitor extends uvm_monitor;
  `uvm_component_utils(alu_monitor)

  virtual alu_if vif;
  uvm_analysis_port #(alu_transaction) item_collected_port;

  function new(string name = "alu_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Could not get virtual interface 'vif'")
  endfunction

  task run_phase(uvm_phase phase);
    alu_transaction trans;
    forever begin
      @(posedge vif.clk);
      #1; // περίμενε settle των NBA + combinational propagation πριν δειγματίσεις
      trans = alu_transaction::type_id::create("trans");
      trans.a           = vif.a;
      trans.b           = vif.b;
      trans.alu_control = vif.alu_control;
      trans.result      = vif.result;
      trans.zero        = vif.zero;
      trans.overflow    = vif.overflow;
      item_collected_port.write(trans);
    end
  endtask
endclass