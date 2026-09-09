`ifndef AXI4_TEST_SV
`define AXI4_TEST_SV

`include "uvm_macros.svh"

package axi4_test_pkg;

    import uvm_pkg::*;
    import axi4_pkg::*;
    import axi4_env_pkg::*;
    import axi4_sequence_pkg::*;

    class axi4_test extends uvm_test;

        `uvm_component_utils(axi4_test)

        axi4_env env;

        function new(
            string name = "axi4_test",
            uvm_component parent = null
        );
            super.new(name, parent);
        endfunction

        function void build_phase(
            uvm_phase phase
        );
            super.build_phase(phase);

            env = axi4_env::type_id::create(
                "env",
                this
            );
        endfunction

        task run_phase(
            uvm_phase phase
        );

            axi4_smoke_sequence seq;

            phase.raise_objection(this);

            seq = axi4_smoke_sequence::type_id::create(
                "seq"
            );

            `uvm_info(
                "AXI4_TEST",
                "Starting AXI4 smoke sequence",
                UVM_MEDIUM
            )

            seq.start(env.agent.sequencer);

            `uvm_info(
                "AXI4_TEST",
                "AXI4 smoke sequence completed",
                UVM_MEDIUM
            )

            phase.drop_objection(this);

        endtask

    endclass

endpackage

`endif
