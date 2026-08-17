`ifndef CPU_AGENT_SV
`define CPU_AGENT_SV

`include "uvm_macros.svh"

package cpu_agent_pkg;

    import uvm_pkg::*;
    import cpu_pkg::*;
    import cpu_driver_pkg::*;
    import cpu_monitor_pkg::*;

    // ------------------------------------------------------------
    // CPU UVM Agent
    //
    // Contains:
    //   - sequencer
    //   - driver
    //   - monitor
    //
    // The agent does not access DUT hierarchy.
    // ------------------------------------------------------------

    class cpu_agent extends uvm_agent;

        `uvm_component_utils(cpu_agent)

        // --------------------------------------------------------
        // Components
        // --------------------------------------------------------

        uvm_sequencer #(cpu_transaction) sequencer;

        cpu_driver  driver;
        cpu_monitor monitor;

        // --------------------------------------------------------
        // Constructor
        // --------------------------------------------------------

        function new(
            string name = "cpu_agent",
            uvm_component parent = null
        );

            super.new(name, parent);

        endfunction

        // --------------------------------------------------------
        // Build phase
        // --------------------------------------------------------

        function void build_phase(uvm_phase phase);

            super.build_phase(phase);

            // ----------------------------------------------------
            // Create monitor always.
            // ----------------------------------------------------

            monitor =
                cpu_monitor::type_id::create(
                    "monitor",
                    this
                );

            // ----------------------------------------------------
            // Create active components only for active agent.
            // ----------------------------------------------------

            if (is_active == UVM_ACTIVE) begin

                sequencer =
                    uvm_sequencer#(cpu_transaction)::type_id::create(
                        "sequencer",
                        this
                    );

                driver =
                    cpu_driver::type_id::create(
                        "driver",
                        this
                    );

            end

        endfunction

        // --------------------------------------------------------
        // Connect phase
        // --------------------------------------------------------

        function void connect_phase(uvm_phase phase);

            super.connect_phase(phase);

            if (is_active == UVM_ACTIVE) begin

                driver.seq_item_port.connect(
                    sequencer.seq_item_export
                );

            end

        endfunction

    endclass

endpackage

`endif