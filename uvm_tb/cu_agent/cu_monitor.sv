import uvm_pkg::*;
`include "uvm_macros.svh"

class cu_monitor extends uvm_monitor;
  `uvm_component_utils(cu_monitor)

  virtual cu_if vif;
  uvm_analysis_port #(cu_transaction) item_collected_port;

  function new(string name = "cu_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual cu_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Could not get virtual interface 'vif'")
  endfunction

  task run_phase(uvm_phase phase);
    cu_transaction trans;
    forever begin
      @(posedge vif.clk);
      #1; // δίνει χρόνο στο combinational decode logic να σταθεροποιηθεί
      trans = cu_transaction::type_id::create("trans");
      trans.instruction = vif.instruction;
      trans.alu_op       = vif.alu_op;
      trans.rs1          = vif.rs1;
      trans.rs2          = vif.rs2;
      trans.rd            = vif.rd;
      trans.is_fp         = vif.is_fp;
      trans.mem_read      = vif.mem_read;
      trans.mem_write     = vif.mem_write;
      trans.reg_write     = vif.reg_write;
      trans.imm_ext       = vif.imm_ext;
      item_collected_port.write(trans);
    end
  endtask
endclass