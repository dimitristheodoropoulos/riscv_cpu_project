`ifndef RISCV_RAL_ENV_SV
`define RISCV_RAL_ENV_SV

`include "uvm_macros.svh"

import uvm_pkg::*;

`include "riscv_reg.sv"
`include "riscv_reg_block.sv"
`include "riscv_ral_adapter.sv"
`include "riscv_ral_sequencer.sv"
`include "riscv_ral_access_driver.sv"

class riscv_ral_env extends uvm_env;

    `uvm_component_utils(riscv_ral_env)

    riscv_reg_block          ral;
    riscv_ral_adapter       adapter;
    riscv_ral_sequencer     sequencer;
    riscv_ral_access_driver driver;

    function new(
        string name = "riscv_ral_env",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        ral = riscv_reg_block::type_id::create("ral");
        ral.build();

        adapter = riscv_ral_adapter::type_id::create("adapter");

        sequencer = riscv_ral_sequencer::type_id::create(
            "sequencer",
            this
        );

        driver = riscv_ral_access_driver::type_id::create(
            "driver",
            this
        );

    endfunction

    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        ral.default_map.set_sequencer(
            sequencer,
            adapter
        );

        driver.seq_item_port.connect(
            sequencer.seq_item_export
        );

    endfunction

endclass

`endif
