`include "uvm_macros.svh"

package fpu_smoke_test_pkg;

    import uvm_pkg::*;
    import fpu_pkg::*;

    // ============================================================
    // FPU Smoke Test
    // ============================================================

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

            agent    = fpu_agent::type_id::create("agent", this);
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

            // Total transactions:
            //
            //   20 normal smoke transactions
            //   + 4 invalid opcode transactions
            //   = 24
            //
            localparam int NUM_RANDOM      = 20;
            localparam int NUM_INVALID     = 4;
            localparam int TOTAL_TRANSACTIONS =
                                      NUM_RANDOM + NUM_INVALID;

            phase.raise_objection(this);


            // ----------------------------------------------------
            // Give reset time to complete
            // ----------------------------------------------------

            #25;


            // ----------------------------------------------------
            // Normal smoke transactions
            // ----------------------------------------------------

            seq = fpu_sequence::type_id::create("seq");

            seq.num_transactions = NUM_RANDOM;

            seq.start(agent.sequencer);


            // ----------------------------------------------------
            // Directed invalid-opcode transactions
            // ----------------------------------------------------
            //
            // These are required to exercise:
            //
            //   op = 3'b100
            //   op = 3'b101
            //   op = 3'b110
            //   op = 3'b111
            //
            // They also activate the SVA properties:
            //
            //   p_invalid_opcode_result_zero
            //   p_invalid_opcode_ready
            //
            // ----------------------------------------------------

            for (int invalid_op = 3'b100;
                         invalid_op <= 3'b111;
                         invalid_op++) begin

                tx = fpu_transaction::type_id::create(
                    $sformatf("invalid_tx_%0d", invalid_op)
                );

                tx.a  = 32'h3F800000;  // 1.0
                tx.b  = 32'h40000000;  // 2.0
                tx.op = invalid_op[2:0];

                start_item_on_sequencer:
                agent.sequencer.execute_item(tx);

            end


            // ----------------------------------------------------
            // Wait for all monitored transactions
            // ----------------------------------------------------

            while (received < TOTAL_TRANSACTIONS) begin

                mon_fifo.get(tx);

                received++;

                if (tx.result === 32'bx) begin

                    `uvm_error(
                        "SMOKE",
                        "Transaction has X result"
                    )

                end

            end


            // ----------------------------------------------------
            // Summary
            // ----------------------------------------------------

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