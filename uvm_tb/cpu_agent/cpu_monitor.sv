`ifndef CPU_MONITOR_SV
`define CPU_MONITOR_SV

`include "uvm_macros.svh"

package cpu_monitor_pkg;

    import uvm_pkg::*;
    import cpu_pkg::*;

    // ------------------------------------------------------------
    // CPU UVM Monitor
    //
    // Observes architectural state exclusively through
    // cpu_exec_if.
    //
    // No direct DUT hierarchy access is performed here.
    //
    // One transaction is published after execution_done.
    // ------------------------------------------------------------

    class cpu_monitor extends uvm_monitor;

        `uvm_component_utils(cpu_monitor)

        // --------------------------------------------------------
        // Virtual interface
        // --------------------------------------------------------

        virtual cpu_exec_if vif;

        // --------------------------------------------------------
        // Analysis port
        // --------------------------------------------------------

        uvm_analysis_port #(cpu_transaction) analysis_port;

        // --------------------------------------------------------
        // Constructor
        // --------------------------------------------------------

        function new(
            string name = "cpu_monitor",
            uvm_component parent = null
        );

            super.new(name, parent);

            analysis_port =
                new("analysis_port", this);

        endfunction

        // --------------------------------------------------------
        // Build phase
        // --------------------------------------------------------

        function void build_phase(uvm_phase phase);

            super.build_phase(phase);

            if (!uvm_config_db#(virtual cpu_exec_if)::get(
                    this,
                    "",
                    "vif",
                    vif
                )) begin

                `uvm_fatal(
                    "CPU_MON_NO_VIF",
                    "cpu_exec_if virtual interface not found"
                )

            end

        endfunction

        // --------------------------------------------------------
        // Capture architectural state
        // --------------------------------------------------------

        task capture_state(
            output cpu_transaction tr
        );

            int i;

            tr = cpu_transaction::type_id::create(
                "monitored_transaction"
            );

            // ----------------------------------------------------
            // Basic observations
            // ----------------------------------------------------

            tr.observed_pc     = vif.pc;
            tr.observed_result = vif.result;

            // ----------------------------------------------------
            // Integer register file
            // ----------------------------------------------------

            for (i = 0; i < 32; i++) begin

                tr.observed_int_regs[i] =
                    vif.int_regs[i];

            end

            // ----------------------------------------------------
            // Data memory
            // ----------------------------------------------------

            for (i = 0; i < 256; i++) begin

                tr.observed_mem[i] =
                    vif.data_mem[i];

            end

            // ----------------------------------------------------
            // RISC-V x0 architectural invariant
            // ----------------------------------------------------

            if (tr.observed_int_regs[0] != 32'h00000000) begin

                `uvm_error(
                    "CPU_MON_X0",
                    $sformatf(
                        "Observed x0 is not zero: %08h",
                        tr.observed_int_regs[0]
                    )
                )

            end

        endtask

        // --------------------------------------------------------
        // Run phase
        // --------------------------------------------------------

        task run_phase(uvm_phase phase);

            cpu_transaction tr;

            forever begin

                // ------------------------------------------------
                // Wait until the driver reports that execution
                // of the current program is complete.
                // ------------------------------------------------

                @(posedge vif.execution_done);

                // ------------------------------------------------
                // Capture the final architectural state.
                // ------------------------------------------------

                capture_state(tr);

                `uvm_info(
                    "CPU_MONITOR",
                    $sformatf(
                        "Observed final CPU state: PC=%08h RESULT=%08h",
                        tr.observed_pc,
                        tr.observed_result
                    ),
                    UVM_MEDIUM
                )

                // ------------------------------------------------
                // Publish to scoreboard.
                // ------------------------------------------------

                analysis_port.write(tr);

            end

        endtask

    endclass

endpackage

`endif