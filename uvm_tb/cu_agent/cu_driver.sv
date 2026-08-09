import uvm_pkg::*;
`include "uvm_macros.svh"

class cu_driver extends uvm_driver #(cu_transaction);
  `uvm_component_utils(cu_driver)

  virtual cu_if vif;

  function new(string name = "cu_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual cu_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "Could not get virtual interface 'vif'")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_item(cu_transaction item);
    @(posedge vif.clk);
    vif.instruction <= item.instruction;
  endtask
endclass