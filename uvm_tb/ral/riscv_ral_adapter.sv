`ifndef RISCV_RAL_ADAPTER_SV
`define RISCV_RAL_ADAPTER_SV

`include "uvm_macros.svh"
`include "riscv_ral_access_item.sv"
import uvm_pkg::*;

class riscv_ral_adapter extends uvm_reg_adapter;

    `uvm_object_utils(riscv_ral_adapter)

    function new(string name = "riscv_ral_adapter");
        super.new(name);

        supports_byte_enable = 0;
        provides_responses   = 0;
    endfunction

    virtual function uvm_sequence_item reg2bus(
        const ref uvm_reg_bus_op rw
    );

        riscv_ral_access_item item;

        item = riscv_ral_access_item::type_id::create(
            "item"
        );

        item.addr = rw.addr;
        item.data = rw.data;
        item.kind = rw.kind;

        return item;

    endfunction

    virtual function void bus2reg(
        uvm_sequence_item bus_item,
        ref uvm_reg_bus_op rw
    );

        riscv_ral_access_item item;

        if (!$cast(item, bus_item)) begin
            `uvm_fatal(
                "RAL_ADAPTER_CAST",
                "bus_item is not a riscv_ral_access_item"
            )
        end

        rw.kind   = item.kind;
        rw.addr   = item.addr;
        rw.data   = item.data;
        rw.status = UVM_IS_OK;

    endfunction

endclass

`endif
