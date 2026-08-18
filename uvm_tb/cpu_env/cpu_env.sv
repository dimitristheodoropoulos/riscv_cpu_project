`ifndef CPU_ENV_SV
`define CPU_ENV_SV

`include "uvm_macros.svh"

package cpu_env_pkg;

    import uvm_pkg::*;
    import cpu_pkg::*;

    import cpu_agent_pkg::*;
    import cpu_scoreboard_pkg::*;
    import cpu_coverage_pkg::*;    // added

    // ------------------------------------------------------------
    // CPU UVM Environment
    // ------------------------------------------------------------

    class cpu_env extends uvm_env;

        `uvm_component_utils(cpu_env)

        // --------------------------------------------------------
        // Components
        // --------------------------------------------------------

        cpu_agent               agent;
        cpu_scoreboard          scoreboard;
        cpu_functional_coverage coverage_h;   // added

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

            // ----------------------------------------------------
            // Functional coverage
            // ----------------------------------------------------

            coverage_h =
                cpu_functional_coverage::type_id::create(
                    "coverage_h",
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
            // Original stimulus -> functional coverage
            // ----------------------------------------------------

            agent.driver.analysis_port.connect(
                coverage_h.analysis_export
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