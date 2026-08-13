`include "uvm_macros.svh"

package fpu_smoke_test_pkg;

    import uvm_pkg::*;
    import fpu_pkg::*;

    // ------------------------------------------------------------
    // FPU Smoke Test
    // ------------------------------------------------------------
    class fpu_smoke_test extends uvm_test;

        `uvm_component_utils(fpu_smoke_test)

        fpu_agent agent;
        uvm_tlm_analysis_fifo #(fpu_transaction) mon_fifo;

        function new(
            string name = "fpu_smoke_test",
            uvm_component parent = null
        );
            super.new(name, parent);
        endfunction

        // --------------------------------------------------------
        // Build
        // --------------------------------------------------------
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            agent = fpu_agent::type_id::create("agent", this);
            mon_fifo = new("mon_fifo", this);
        endfunction

        // --------------------------------------------------------
        // Connect
        // --------------------------------------------------------
        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);

            agent.monitor.ap.connect(mon_fifo.analysis_export);
        endfunction

        // --------------------------------------------------------
        // Run
        // --------------------------------------------------------
        virtual task run_phase(uvm_phase phase);

            fpu_sequence seq;
            fpu_transaction tx;
            int received = 0;

            phase.raise_objection(this);

            // Give reset time to complete.
            #25;

            seq = fpu_sequence::type_id::create("seq");
            seq.num_transactions = 20;

            seq.start(agent.sequencer);

            // Wait for all 20 monitored transactions.
            while (received < 20) begin

                mon_fifo.get(tx);
                received++;

                if (tx.result === 32'bx) begin
                    `uvm_error(
                        "SMOKE",
                        "Transaction has X result"
                    )
                end

            end

            `uvm_info(
                "SMOKE",
                $sformatf(
                    "Successfully received %0d transactions",
                    received
                ),
                UVM_MEDIUM
            )

            phase.drop_objection(this);

        endtask

    endclass

endpackage
