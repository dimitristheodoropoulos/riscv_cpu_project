`ifndef RISCV_RAL_ACCESS_DRIVER_SV
`define RISCV_RAL_ACCESS_DRIVER_SV

`include "uvm_macros.svh"
`include "riscv_ral_access_item.sv"

import uvm_pkg::*;

class riscv_ral_access_driver extends uvm_driver #(riscv_ral_access_item);

    `uvm_component_utils(riscv_ral_access_driver)

    virtual cpu_exec_if vif;

    function new(
        string name = "riscv_ral_access_driver",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual cpu_exec_if)::get(
                this,
                "",
                "vif",
                vif
            )) begin

            `uvm_fatal(
                "RAL_DRV_NO_VIF",
                "Virtual cpu_exec_if was not provided"
            )
        end
    endfunction

    virtual task run_phase(uvm_phase phase);

        riscv_ral_access_item item;

        forever begin

            seq_item_port.get_next_item(item);

            if (item.kind == UVM_WRITE)
                drive_write(item);
            else if (item.kind == UVM_READ)
                drive_read(item);
            else
                `uvm_fatal(
                    "RAL_DRV_KIND",
                    "Unsupported RAL access kind"
                )

            seq_item_port.item_done();

        end

    endtask

    virtual task drive_write(
        riscv_ral_access_item item
    );

        int unsigned reg_index;
        bit is_fp;

        decode_address(
            item.addr,
            reg_index,
            is_fp
        );

        if (!is_fp && reg_index == 0) begin
            `uvm_fatal(
                "RAL_DRV_X0_WRITE",
                "Attempted write to read-only x0"
            )
        end

        @(negedge vif.clk);

        vif.reg_init_addr   = reg_index[4:0];
        vif.reg_init_data   = item.data;
        vif.reg_init_is_fp  = is_fp;
        vif.reg_init_enable = 1'b1;

        @(posedge vif.clk);

        vif.reg_init_enable = 1'b0;

        // Allow the DUT register-file NBA update to complete
        // before the RAL write transaction is considered done.
        @(negedge vif.clk);

    endtask

    virtual task drive_read(
        riscv_ral_access_item item
    );

        int unsigned reg_index;
        bit is_fp;

        decode_address(
            item.addr,
            reg_index,
            is_fp
        );

        if (is_fp)
            item.data = vif.fp_regs[reg_index];
        else
            item.data = vif.int_regs[reg_index];

    endtask

    virtual function void decode_address(
        uvm_reg_addr_t addr,
        output int unsigned reg_index,
        output bit is_fp
    );

        if (addr < 32'h80) begin

            if ((addr % 4) != 0)
                `uvm_fatal(
                    "RAL_DRV_ADDR",
                    $sformatf(
                        "Unaligned integer register address: 0x%0h",
                        addr
                    )
                )

            reg_index = addr / 4;
            is_fp = 1'b0;

        end
        else if (addr <= 32'hFC) begin

            if (((addr - 32'h80) % 4) != 0)
                `uvm_fatal(
                    "RAL_DRV_ADDR",
                    $sformatf(
                        "Unaligned FP register address: 0x%0h",
                        addr
                    )
                )

            reg_index = (addr - 32'h80) / 4;
            is_fp = 1'b1;

        end
        else begin

            `uvm_fatal(
                "RAL_DRV_ADDR",
                $sformatf(
                    "Invalid RAL register address: 0x%0h",
                    addr
                )
            )

        end

    endfunction

endclass

`endif
