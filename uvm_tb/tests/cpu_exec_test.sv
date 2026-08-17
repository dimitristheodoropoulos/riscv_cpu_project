`ifndef CPU_EXEC_TEST_SV
`define CPU_EXEC_TEST_SV

`include "uvm_macros.svh"

package cpu_exec_test_pkg;

    import uvm_pkg::*;

    import cpu_pkg::*;
    import cpu_agent_pkg::*;
    import cpu_env_pkg::*;
    import cpu_exec_sequence_pkg::*;

    // ------------------------------------------------------------
    // CPU Execution Test
    // ------------------------------------------------------------

    class cpu_exec_test extends uvm_test;

        `uvm_component_utils(cpu_exec_test)

        // --------------------------------------------------------
        // Environment
        // --------------------------------------------------------

        cpu_env env;

        // --------------------------------------------------------
        // Constructor
        // --------------------------------------------------------

        function new(
            string name = "cpu_exec_test",
            uvm_component parent = null
        );

            super.new(name, parent);

        endfunction

        // --------------------------------------------------------
        // Build phase
        // --------------------------------------------------------

        function void build_phase(uvm_phase phase);

            super.build_phase(phase);

            env =
                cpu_env::type_id::create(
                    "env",
                    this
                );

        endfunction

        // --------------------------------------------------------
        // End of elaboration
        // --------------------------------------------------------

        function void end_of_elaboration_phase(
            uvm_phase phase
        );

            super.end_of_elaboration_phase(phase);

            `uvm_info(
                "CPU_EXEC_TEST",
                "CPU execution test environment constructed",
                UVM_LOW
            )

            uvm_top.print_topology();

        endfunction

        // --------------------------------------------------------
        // Run phase
        // --------------------------------------------------------

        task run_phase(uvm_phase phase);

            cpu_exec_sequence seq;

            phase.raise_objection(this);

            `uvm_info(
                "CPU_EXEC_TEST",
                "Starting CPU execution sequence",
                UVM_MEDIUM
            )

            seq =
                cpu_exec_sequence::type_id::create(
                    "seq"
                );

            seq.start(
                env.agent.sequencer
            );

            `uvm_info(
                "CPU_EXEC_TEST",
                "CPU execution sequence completed",
                UVM_MEDIUM
            )

            // Allow monitor / scoreboard activity to complete.
            #1us;

            phase.drop_objection(this);

        endtask

        // --------------------------------------------------------
        // Report phase
        // --------------------------------------------------------

        function void report_phase(uvm_phase phase);

            uvm_report_server server;

            super.report_phase(phase);

            server =
                uvm_report_server::get_server();

            `uvm_info(
                "CPU_EXEC_TEST",
                "==============================================",
                UVM_NONE
            )

            `uvm_info(
                "CPU_EXEC_TEST",
                "CPU EXECUTION TEST COMPLETE",
                UVM_NONE
            )

            `uvm_info(
                "CPU_EXEC_TEST",
                $sformatf(
                    "UVM errors = %0d",
                    server.get_severity_count(UVM_ERROR)
                ),
                UVM_NONE
            )

            `uvm_info(
                "CPU_EXEC_TEST",
                "==============================================",
                UVM_NONE
            )

        endfunction

    endclass

endpackage

`endif
