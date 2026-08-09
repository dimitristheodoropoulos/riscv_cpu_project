import uvm_pkg::*;
`include "uvm_macros.svh"

class cu_test extends uvm_test;
  `uvm_component_utils(cu_test)

  cu_env env;

  function new(string name = "cu_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = cu_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    cu_random_sequence seq;
    phase.raise_objection(this);
    seq = cu_random_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    #20;
    phase.drop_objection(this);
  endtask
endclass