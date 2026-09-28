`ifndef RISCV_RAL_ENV_TEST_SV
`define RISCV_RAL_ENV_TEST_SV

`include "uvm_macros.svh"

package riscv_ral_env_test_pkg;

    import uvm_pkg::*;

    `include "riscv_ral_env.sv"

    class riscv_ral_env_test extends uvm_test;

        `uvm_component_utils(riscv_ral_env_test)

        riscv_ral_env env;

        function new(
            string name = "riscv_ral_env_test",
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

        endfunction

        virtual task run_phase(uvm_phase phase);

            phase.raise_objection(this);

            `uvm_info(
                "RAL_M5",
                "M5.1 RAL environment connectivity test started",
                UVM_LOW
            )

            #1ns;

            `uvm_info(
                "RAL_M5",
                "M5.1 RAL environment connectivity test completed",
                UVM_LOW
            )

            phase.drop_objection(this);

        endtask

    endclass

endpackage

`endif
