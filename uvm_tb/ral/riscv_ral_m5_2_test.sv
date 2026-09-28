`ifndef RISCV_RAL_M5_2_TEST_SV
`define RISCV_RAL_M5_2_TEST_SV

`include "uvm_macros.svh"

package riscv_ral_m5_2_test_pkg;

    import uvm_pkg::*;

    `include "riscv_ral_env.sv"

    class riscv_ral_m5_2_test extends uvm_test;

        `uvm_component_utils(riscv_ral_m5_2_test)

        riscv_ral_env env;

        virtual cpu_exec_if vif;

        function new(
            string name = "riscv_ral_m5_2_test",
            uvm_component parent = null
        );
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);

            super.build_phase(phase);

            env = riscv_ral_env::type_id::create(
                "env",
                this
            );

            if (!uvm_config_db#(virtual cpu_exec_if)::get(
                    this,
                    "",
                    "vif",
                    vif
                )) begin

                `uvm_fatal(
                    "M5_VIF",
                    "Virtual cpu_exec_if was not provided"
                )

            end

        endfunction

        virtual task run_phase(uvm_phase phase);

            uvm_status_e status;
            uvm_reg_data_t read_value;

            phase.raise_objection(this);

            // ----------------------------------------------------
            // Deterministic DUT reset / idle initialization
            // ----------------------------------------------------

            vif.reset            = 1'b1;
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

            // ----------------------------------------------------
            // Integer register x5
            // ----------------------------------------------------

            `uvm_info(
                "RAL_M5_2",
                "Writing x5 through UVM RAL frontdoor",
                UVM_LOW
            )

            status = UVM_NOT_OK;

            env.ral.x[5].write(
                status,
                32'h12345678,
                UVM_FRONTDOOR
            );

            if (status != UVM_IS_OK) begin
                `uvm_error(
                    "RAL_M5_2",
                    $sformatf(
                        "x5 write failed: status=%s",
                        status.name()
                    )
                )
            end

            if (vif.int_regs[5] !== 32'h12345678) begin
                `uvm_error(
                    "RAL_M5_2",
                    $sformatf(
                        "DUT x5 mismatch after RAL write: expected=0x12345678 actual=0x%08h",
                        vif.int_regs[5]
                    )
                )
            end

            read_value = '0;
            status = UVM_NOT_OK;

            env.ral.x[5].read(
                status,
                read_value,
                UVM_FRONTDOOR
            );

            if (status != UVM_IS_OK) begin
                `uvm_error(
                    "RAL_M5_2",
                    $sformatf(
                        "x5 read failed: status=%s",
                        status.name()
                    )
                )
            end

            if (read_value !== 32'h12345678) begin
                `uvm_error(
                    "RAL_M5_2",
                    $sformatf(
                        "RAL x5 read mismatch: expected=0x12345678 actual=0x%08h",
                        read_value
                    )
                )
            end

            // ----------------------------------------------------
            // Floating-point register f7
            // ----------------------------------------------------

            `uvm_info(
                "RAL_M5_2",
                "Writing f7 through UVM RAL frontdoor",
                UVM_LOW
            )

            status = UVM_NOT_OK;

            env.ral.f[7].write(
                status,
                32'hA5A5A5A5,
                UVM_FRONTDOOR
            );

            if (status != UVM_IS_OK) begin
                `uvm_error(
                    "RAL_M5_2",
                    $sformatf(
                        "f7 write failed: status=%s",
                        status.name()
                    )
                )
            end

            if (vif.fp_regs[7] !== 32'hA5A5A5A5) begin
                `uvm_error(
                    "RAL_M5_2",
                    $sformatf(
                        "DUT f7 mismatch after RAL write: expected=0xA5A5A5A5 actual=0x%08h",
                        vif.fp_regs[7]
                    )
                )
            end

            read_value = '0;
            status = UVM_NOT_OK;

            env.ral.f[7].read(
                status,
                read_value,
                UVM_FRONTDOOR
            );

            if (status != UVM_IS_OK) begin
                `uvm_error(
                    "RAL_M5_2",
                    $sformatf(
                        "f7 read failed: status=%s",
                        status.name()
                    )
                )
            end

            if (read_value !== 32'hA5A5A5A5) begin
                `uvm_error(
                    "RAL_M5_2",
                    $sformatf(
                        "RAL f7 read mismatch: expected=0xA5A5A5A5 actual=0x%08h",
                        read_value
                    )
                )
            end

            // ----------------------------------------------------
            // x0 invariant
            // ----------------------------------------------------

            if (vif.int_regs[0] !== 32'h00000000) begin
                `uvm_error(
                    "RAL_M5_2",
                    $sformatf(
                        "x0 invariant violated: actual=0x%08h",
                        vif.int_regs[0]
                    )
                )
            end

            `uvm_info(
                "RAL_M5_2",
                "M5.2 RAL frontdoor integration test completed",
                UVM_LOW
            )

            phase.drop_objection(this);

        endtask

    endclass

endpackage

`endif
