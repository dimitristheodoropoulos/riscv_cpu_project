`ifndef RISCV_RAL_SMOKE_TEST_SV
`define RISCV_RAL_SMOKE_TEST_SV

`include "uvm_macros.svh"

package riscv_ral_test_pkg;

    import uvm_pkg::*;

    `include "riscv_reg.sv"
    `include "riscv_reg_block.sv"
    `include "riscv_ral_access_item.sv"
    `include "riscv_ral_adapter.sv"
    `include "riscv_ral_sequencer.sv"
    `include "riscv_ral_access_driver.sv"

class riscv_ral_smoke_test extends uvm_test;

    `uvm_component_utils(riscv_ral_smoke_test)

    virtual cpu_exec_if vif;

    riscv_reg_block          ral;
    riscv_ral_sequencer      sequencer;
    riscv_ral_access_driver  driver;
    riscv_ral_adapter        adapter;

    function new(
        string name = "riscv_ral_smoke_test",
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
                "RAL_TEST_NO_VIF",
                "Virtual cpu_exec_if was not provided"
            )
        end

        ral = riscv_reg_block::type_id::create("ral");
        ral.build();

        sequencer = riscv_ral_sequencer::type_id::create(
            "sequencer",
            this
        );

        driver = riscv_ral_access_driver::type_id::create(
            "driver",
            this
        );

        adapter = riscv_ral_adapter::type_id::create(
            "adapter"
        );

        ral.default_map.set_sequencer(
            sequencer,
            adapter
        );

    endfunction

    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        driver.seq_item_port.connect(
            sequencer.seq_item_export
        );

    endfunction

    virtual task run_phase(uvm_phase phase);

        uvm_status_e status;
        uvm_reg_data_t data;

        phase.raise_objection(this);

        // ----------------------------------------------------
        // Deterministic idle instruction for RAL-only operation
        //
        // The CPU execution wrapper also instantiates the
        // existing CPU assertions.  Since this RAL test does
        // not load a CPU program, initialize instruction memory
        // entry 0 to the existing idle/NOP value before
        // releasing reset.
        // ----------------------------------------------------

        vif.reset = 1'b1;
        vif.execution_enable = 1'b0;

        vif.program_enable = 1'b0;
        vif.program_addr   = 32'h00000000;
        vif.program_data   = 32'h00000000;

        vif.reg_init_enable = 1'b0;
        vif.reg_init_addr   = 5'd0;
        vif.reg_init_data   = 32'h00000000;
        vif.reg_init_is_fp  = 1'b0;

        vif.program_enable = 1'b1;

        @(posedge vif.clk);

        vif.program_enable = 1'b0;
        vif.program_addr   = 32'h00000000;
        vif.program_data   = 32'h00000000;

        repeat (1)
            @(posedge vif.clk);

        vif.reset = 1'b0;

        repeat (2)
            @(posedge vif.clk);

        `uvm_info(
            "RAL_SMOKE",
            "Starting RAL x5 write/read",
            UVM_LOW
        )

        ral.x[5].write(
            status,
            32'h12345678,
            UVM_FRONTDOOR
        );

        if (status != UVM_IS_OK) begin
            `uvm_error(
                "RAL_SMOKE",
                "x5 write returned non-OK status"
            )
        end

        @(posedge vif.clk);

        if (vif.int_regs[5] !== 32'h12345678) begin
            `uvm_error(
                "RAL_SMOKE",
                $sformatf(
                    "DUT x5 mismatch after write: expected=0x12345678 actual=0x%08h",
                    vif.int_regs[5]
                )
            )
        end
        else begin
            `uvm_info(
                "RAL_SMOKE",
                "DUT x5 write verified",
                UVM_LOW
            )
        end

        ral.x[5].read(
            status,
            data,
            UVM_FRONTDOOR
        );

        if (status != UVM_IS_OK) begin
            `uvm_error(
                "RAL_SMOKE",
                "x5 read returned non-OK status"
            )
        end

        if (data !== 32'h12345678) begin
            `uvm_error(
                "RAL_SMOKE",
                $sformatf(
                    "RAL x5 read mismatch: expected=0x12345678 actual=0x%08h",
                    data
                )
            )
        end
        else begin
            `uvm_info(
                "RAL_SMOKE",
                "RAL x5 read verified",
                UVM_LOW
            )
        end

        `uvm_info(
            "RAL_SMOKE",
            "Starting RAL f7 write/read",
            UVM_LOW
        )

        ral.f[7].write(
            status,
            32'hA5A5A5A5,
            UVM_FRONTDOOR
        );

        if (status != UVM_IS_OK) begin
            `uvm_error(
                "RAL_SMOKE",
                "f7 write returned non-OK status"
            )
        end

        @(posedge vif.clk);

        if (vif.fp_regs[7] !== 32'hA5A5A5A5) begin
            `uvm_error(
                "RAL_SMOKE",
                $sformatf(
                    "DUT f7 mismatch after write: expected=0xA5A5A5A5 actual=0x%08h",
                    vif.fp_regs[7]
                )
            )
        end
        else begin
            `uvm_info(
                "RAL_SMOKE",
                "DUT f7 write verified",
                UVM_LOW
            )
        end

        ral.f[7].read(
            status,
            data,
            UVM_FRONTDOOR
        );

        if (status != UVM_IS_OK) begin
            `uvm_error(
                "RAL_SMOKE",
                "f7 read returned non-OK status"
            )
        end

        if (data !== 32'hA5A5A5A5) begin
            `uvm_error(
                "RAL_SMOKE",
                $sformatf(
                    "RAL f7 read mismatch: expected=0xA5A5A5A5 actual=0x%08h",
                    data
                )
            )
        end
        else begin
            `uvm_info(
                "RAL_SMOKE",
                "RAL f7 read verified",
                UVM_LOW
            )
        end

        if (vif.int_regs[0] !== 32'h00000000) begin
            `uvm_error(
                "RAL_SMOKE",
                $sformatf(
                    "x0 changed unexpectedly: actual=0x%08h",
                    vif.int_regs[0]
                )
            )
        end
        else begin
            `uvm_info(
                "RAL_SMOKE",
                "x0 remains zero",
                UVM_LOW
            )
        end

        phase.drop_objection(this);

    endtask

endclass

endpackage

`endif
