`ifndef AXI4_COVERAGE_SV
`define AXI4_COVERAGE_SV

`include "uvm_macros.svh"

package axi4_coverage_pkg;

    import uvm_pkg::*;
    import axi4_pkg::*;

    class axi4_coverage extends uvm_subscriber #(axi4_transaction);

        `uvm_component_utils(axi4_coverage)

        // ------------------------------------------------------------
        // Operation coverage
        // ------------------------------------------------------------

        int operation_read;
        int operation_write;

        // ------------------------------------------------------------
        // ID coverage
        // ------------------------------------------------------------

        int read_id_bins[16];
        int write_id_bins[16];

        // ------------------------------------------------------------
        // WRITE WSTRB coverage
        // ------------------------------------------------------------

        int wstrb_none;
        int wstrb_full;
        int wstrb_byte;
        int wstrb_partial;

        // ------------------------------------------------------------
        // Response coverage
        // ------------------------------------------------------------

        int bresp_okay;
        int bresp_other;

        int rresp_okay;
        int rresp_other;

        // ------------------------------------------------------------
        // Address coverage
        // ------------------------------------------------------------

        int read_address_low;
        int read_address_mid;
        int read_address_high;

        int write_address_low;
        int write_address_mid;
        int write_address_high;

        // ------------------------------------------------------------
        // Meaningful cross coverage
        // ------------------------------------------------------------

        int write_wstrb_none;
        int write_wstrb_full;
        int write_wstrb_byte;
        int write_wstrb_partial;

        int read_id_covered;
        int write_id_covered;

        function new(
            string name = "axi4_coverage",
            uvm_component parent = null
        );
            super.new(name, parent);

            operation_read  = 0;
            operation_write = 0;

            foreach (read_id_bins[i])
                read_id_bins[i] = 0;

            foreach (write_id_bins[i])
                write_id_bins[i] = 0;

            wstrb_none    = 0;
            wstrb_full    = 0;
            wstrb_byte    = 0;
            wstrb_partial = 0;

            bresp_okay  = 0;
            bresp_other = 0;

            rresp_okay  = 0;
            rresp_other = 0;

            read_address_low  = 0;
            read_address_mid  = 0;
            read_address_high = 0;

            write_address_low  = 0;
            write_address_mid  = 0;
            write_address_high = 0;

            write_wstrb_none    = 0;
            write_wstrb_full    = 0;
            write_wstrb_byte    = 0;
            write_wstrb_partial = 0;

            read_id_covered  = 0;
            write_id_covered = 0;
        endfunction

        function void write(axi4_transaction t);

            int unsigned id;
            bit [7:0] address_word;

            if (t == null) begin
                `uvm_error(
                    "AXI4_COV",
                    "Received null transaction"
                )
                return;
            end

            // ========================================================
            // WRITE transaction
            // ========================================================

            if (t.is_write) begin

                operation_write++;

                id = t.awid;
                address_word = t.awaddr[9:2];

                // ID
                if (id < 16)
                    write_id_bins[id]++;

                // WSTRB -- WRITE ONLY
                if (t.wstrb == 4'b0000) begin
                    wstrb_none++;
                    write_wstrb_none++;
                end
                else if (t.wstrb == 4'b1111) begin
                    wstrb_full++;
                    write_wstrb_full++;
                end
                else if (
                    t.wstrb == 4'b0001 ||
                    t.wstrb == 4'b0010 ||
                    t.wstrb == 4'b0100 ||
                    t.wstrb == 4'b1000
                ) begin
                    wstrb_byte++;
                    write_wstrb_byte++;
                end
                else begin
                    wstrb_partial++;
                    write_wstrb_partial++;
                end

                // BRESP -- WRITE ONLY
                if (t.bresp == 2'b00)
                    bresp_okay++;
                else
                    bresp_other++;

                // Address region -- WRITE
                if (address_word <= 8'd15)
                    write_address_low++;
                else if (address_word <= 8'd63)
                    write_address_mid++;
                else
                    write_address_high++;

            end

            // ========================================================
            // READ transaction
            // ========================================================

            else begin

                operation_read++;

                id = t.arid;
                address_word = t.araddr[9:2];

                // ID
                if (id < 16)
                    read_id_bins[id]++;

                // RRESP -- READ ONLY
                if (t.rresp == 2'b00)
                    rresp_okay++;
                else
                    rresp_other++;

                // Address region -- READ
                if (address_word <= 8'd15)
                    read_address_low++;
                else if (address_word <= 8'd63)
                    read_address_mid++;
                else
                    read_address_high++;

            end

        endfunction

        function real get_coverage();

            int covered;
            int total;
            int read_ids;
            int write_ids;

            covered = 0;
            total   = 0;

            // --------------------------------------------------------
            // Operation: READ / WRITE
            // --------------------------------------------------------

            total += 2;

            if (operation_read > 0)
                covered++;

            if (operation_write > 0)
                covered++;

            // --------------------------------------------------------
            // READ ID: 16 bins
            // --------------------------------------------------------

            total += 16;
            read_ids = 0;

            foreach (read_id_bins[i]) begin
                if (read_id_bins[i] > 0) begin
                    covered++;
                    read_ids++;
                end
            end

            // --------------------------------------------------------
            // WRITE ID: 16 bins
            // --------------------------------------------------------

            total += 16;
            write_ids = 0;

            foreach (write_id_bins[i]) begin
                if (write_id_bins[i] > 0) begin
                    covered++;
                    write_ids++;
                end
            end

            read_id_covered  = read_ids;
            write_id_covered = write_ids;

            // --------------------------------------------------------
            // WRITE WSTRB: 4 meaningful bins
            // --------------------------------------------------------

            total += 4;

            if (wstrb_none > 0)
                covered++;

            if (wstrb_full > 0)
                covered++;

            if (wstrb_byte > 0)
                covered++;

            if (wstrb_partial > 0)
                covered++;

            // --------------------------------------------------------
            // BRESP: 2 meaningful WRITE bins
            // --------------------------------------------------------

            total += 2;

            if (bresp_okay > 0)
                covered++;

            if (bresp_other > 0)
                covered++;

            // --------------------------------------------------------
            // RRESP: 2 meaningful READ bins
            // --------------------------------------------------------

            total += 2;

            if (rresp_okay > 0)
                covered++;

            if (rresp_other > 0)
                covered++;

            // --------------------------------------------------------
            // READ address regions
            // --------------------------------------------------------

            total += 3;

            if (read_address_low > 0)
                covered++;

            if (read_address_mid > 0)
                covered++;

            if (read_address_high > 0)
                covered++;

            // --------------------------------------------------------
            // WRITE address regions
            // --------------------------------------------------------

            total += 3;

            if (write_address_low > 0)
                covered++;

            if (write_address_mid > 0)
                covered++;

            if (write_address_high > 0)
                covered++;

            // --------------------------------------------------------
            // WRITE × WSTRB meaningful cross
            // --------------------------------------------------------

            total += 4;

            if (write_wstrb_none > 0)
                covered++;

            if (write_wstrb_full > 0)
                covered++;

            if (write_wstrb_byte > 0)
                covered++;

            if (write_wstrb_partial > 0)
                covered++;

            if (total == 0)
                return 0.0;

            return (100.0 * covered) / total;

        endfunction

        function void report_phase(uvm_phase phase);

            super.report_phase(phase);

            `uvm_info(
                "AXI4_COV",
                $sformatf(
                    "AXI4 FUNCTIONAL COVERAGE = %0.2f%%",
                    get_coverage()
                ),
                UVM_NONE
            )

            `uvm_info(
                "AXI4_COV",
                $sformatf(
                    "OPERATIONS: READ=%0d WRITE=%0d",
                    operation_read,
                    operation_write
                ),
                UVM_NONE
            )

            `uvm_info(
                "AXI4_COV",
                $sformatf(
                    "READ IDs COVERED=%0d/16 WRITE IDs COVERED=%0d/16",
                    read_id_covered,
                    write_id_covered
                ),
                UVM_NONE
            )

            `uvm_info(
                "AXI4_COV",
                $sformatf(
                    "WRITE WSTRB: NONE=%0d FULL=%0d BYTE=%0d PARTIAL=%0d",
                    wstrb_none,
                    wstrb_full,
                    wstrb_byte,
                    wstrb_partial
                ),
                UVM_NONE
            )

            `uvm_info(
                "AXI4_COV",
                $sformatf(
                    "WRITE RESP: OKAY=%0d OTHER=%0d",
                    bresp_okay,
                    bresp_other
                ),
                UVM_NONE
            )

            `uvm_info(
                "AXI4_COV",
                $sformatf(
                    "READ RESP: OKAY=%0d OTHER=%0d",
                    rresp_okay,
                    rresp_other
                ),
                UVM_NONE
            )

            `uvm_info(
                "AXI4_COV",
                $sformatf(
                    "READ ADDRESS: LOW=%0d MID=%0d HIGH=%0d",
                    read_address_low,
                    read_address_mid,
                    read_address_high
                ),
                UVM_NONE
            )

            `uvm_info(
                "AXI4_COV",
                $sformatf(
                    "WRITE ADDRESS: LOW=%0d MID=%0d HIGH=%0d",
                    write_address_low,
                    write_address_mid,
                    write_address_high
                ),
                UVM_NONE
            )

        endfunction

    endclass

endpackage

`endif
