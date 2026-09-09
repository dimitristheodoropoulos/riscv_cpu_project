`ifndef AXI4_AGENT_SV
`define AXI4_AGENT_SV

`include "uvm_macros.svh"

package axi4_agent_pkg;

    import uvm_pkg::*;
    import axi4_pkg::*;
    import axi4_driver_pkg::*;
    import axi4_monitor_pkg::*;

    class axi4_agent extends uvm_agent;

        `uvm_component_utils(axi4_agent)

        uvm_sequencer #(axi4_transaction) sequencer;

        axi4_driver  driver;
        axi4_monitor monitor;

        function new(
            string name = "axi4_agent",
            uvm_component parent = null
        );
            super.new(name, parent);
        endfunction

        function void build_phase(
            uvm_phase phase
        );
            super.build_phase(phase);

            sequencer = uvm_sequencer#(axi4_transaction)::type_id::create(
                "sequencer",
                this
            );

            driver = axi4_driver::type_id::create(
                "driver",
                this
            );

            monitor = axi4_monitor::type_id::create(
                "monitor",
                this
            );
        endfunction

        function void connect_phase(
            uvm_phase phase
        );
            super.connect_phase(phase);

            driver.seq_item_port.connect(
                sequencer.seq_item_export
            );
        endfunction

    endclass

endpackage

`endif
