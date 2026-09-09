`ifndef AXI4_ENV_SV
`define AXI4_ENV_SV

`include "uvm_macros.svh"

package axi4_env_pkg;

    import uvm_pkg::*;
    import axi4_pkg::*;
    import axi4_agent_pkg::*;
    import axi4_scoreboard_pkg::*;

    class axi4_env extends uvm_env;

        `uvm_component_utils(axi4_env)

        axi4_agent agent;
        axi4_scoreboard scoreboard;

        function new(
            string name = "axi4_env",
            uvm_component parent = null
        );
            super.new(name, parent);
        endfunction

        function void build_phase(
            uvm_phase phase
        );
            super.build_phase(phase);

            agent = axi4_agent::type_id::create(
                "agent",
                this
            );

            scoreboard = axi4_scoreboard::type_id::create(
                "scoreboard",
                this
            );
        endfunction

        function void connect_phase(
            uvm_phase phase
        );
            super.connect_phase(phase);

            agent.monitor.analysis_port.connect(
                scoreboard.analysis_export
            );
        endfunction

    endclass

endpackage

`endif
