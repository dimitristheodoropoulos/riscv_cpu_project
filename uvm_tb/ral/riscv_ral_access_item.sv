`ifndef RISCV_RAL_ACCESS_ITEM_SV
`define RISCV_RAL_ACCESS_ITEM_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class riscv_ral_access_item extends uvm_sequence_item;

    `uvm_object_utils(riscv_ral_access_item)

    // Logical RAL address.
    rand uvm_reg_addr_t addr;

    // Write data or returned read data.
    rand uvm_reg_data_t data;

    // RAL access direction.
    rand uvm_access_e kind;

    function new(string name = "riscv_ral_access_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf(
            "kind=%s addr=0x%0h data=0x%0h",
            kind.name(),
            addr,
            data
        );
    endfunction

endclass

`endif
