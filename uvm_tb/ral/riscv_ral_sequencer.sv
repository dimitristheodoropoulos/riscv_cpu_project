`ifndef RISCV_RAL_SEQUENCER_SV
`define RISCV_RAL_SEQUENCER_SV

`include "uvm_macros.svh"
`include "riscv_ral_access_item.sv"

import uvm_pkg::*;

class riscv_ral_sequencer extends uvm_sequencer #(riscv_ral_access_item);

    `uvm_component_utils(riscv_ral_sequencer)

    function new(
        string name = "riscv_ral_sequencer",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

endclass

`endif
