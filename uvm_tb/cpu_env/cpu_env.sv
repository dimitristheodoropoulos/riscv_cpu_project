`ifndef CPU_ENV_SV
`define CPU_ENV_SV

`include "uvm_macros.svh"

package cpu_env_pkg;

    import uvm_pkg::*;
    import cpu_pkg::*;

    import cpu_agent_pkg::*;
    import cpu_scoreboard_pkg::*;

    // ------------------------------------------------------------
    // CPU UVM Environment
    //
    // Contains:
    //   - CPU agent
    //   - CPU scoreboard
    //
    // Analysis connections:
    //
    //   driver.analysis_port
    //          |
    //          v
    //   scoreboard.expected_export
    //
    //   monitor.analysis_port
    //          |
    //          v
    //   scoreboard.observed_export
    //
    // The scoreboard uses the original stimulus transaction
    // together with the observed architectural state.
    // ------------------------------------------------------------

    class cpu_env extends uvm_env;

        `uvm_component_utils(cpu_env)

        // --------------------------------------------------------
        // Components
        // --------------------------------------------------------

        cpu_agent      agent;
        cpu_scoreboard scoreboard;

        // --------------------------------------------------------
        // Constructor
        // --------------------------------------------------------

        function new(
            string name = "cpu_env",
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
            // CPU agent
            // ----------------------------------------------------

            agent =
                cpu_agent::type_id::create(
                    "agent",
                    this
                );

            // ----------------------------------------------------
            // Scoreboard
            // ----------------------------------------------------

            scoreboard =
                cpu_scoreboard::type_id::create(
                    "scoreboard",
                    this
                );

        endfunction

        // --------------------------------------------------------
        // Connect phase
        // --------------------------------------------------------

        function void connect_phase(uvm_phase phase);

            super.connect_phase(phase);

            // ----------------------------------------------------
            // Original stimulus -> scoreboard
            // ----------------------------------------------------

            agent.driver.analysis_port.connect(
                scoreboard.expected_export
            );

            // ----------------------------------------------------
            // Observed DUT state -> scoreboard
            // ----------------------------------------------------

            agent.monitor.analysis_port.connect(
                scoreboard.observed_export
            );

        endfunction

    endclass

endpackage

`endif