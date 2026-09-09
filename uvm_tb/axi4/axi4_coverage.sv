`ifndef AXI4_COVERAGE_SV
`define AXI4_COVERAGE_SV

`include "uvm_macros.svh"

package axi4_coverage_pkg;

    import uvm_pkg::*;
    import axi4_pkg::*;

    class axi4_coverage extends uvm_subscriber #(axi4_transaction);

        `uvm_component_utils(axi4_coverage)

        // ------------------------------------------------------------
        // Basic functional coverage counters
        // ------------------------------------------------------------

        int operation_read;
        int operation_write;

        int read_id_bins[16];
        int write_id_bins[16];

        int wstrb_none;
        int wstrb_full;
        int wstrb_byte;
        int wstrb_partial;

        int bresp_okay;
        int bresp_other;

        int rresp_okay;
        int rresp_other;

        int read_address_low;
        int read_address_mid;
        int read_address_high;

        int write_address_low;
        int write_address_mid;
        int write_address_high;

        // ------------------------------------------------------------
        // REAL functional cross coverage
        //
        // Indexing:
        //   address region : 0=low, 1=mid, 2=high
        //   WSTRB class    : 0=none, 1=full, 2=byte, 3=partial
        //
        // Only transaction combinations actually sampled are marked.
        // ------------------------------------------------------------

        bit write_addr_x_wstrb[3][4];
        bit write_id_x_wstrb[16][4];
        bit read_id_x_addr[16][3];
        bit write_id_x_addr[16][3];

        // ------------------------------------------------------------
        // Covered-bin counters
        // ------------------------------------------------------------

        int read_id_covered;
        int write_id_covered;

        int write_addr_x_wstrb_covered;
        int write_id_x_wstrb_covered;
        int read_id_x_addr_covered;
        int write_id_x_addr_covered;

        // ------------------------------------------------------------
        // Constructor
        // ------------------------------------------------------------

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

            read_id_covered  = 0;
            write_id_covered = 0;

            foreach (write_addr_x_wstrb[i,j])
                write_addr_x_wstrb[i][j] = 0;

            foreach (write_id_x_wstrb[i,j])
                write_id_x_wstrb[i][j] = 0;

            foreach (read_id_x_addr[i,j])
                read_id_x_addr[i][j] = 0;

            foreach (write_id_x_addr[i,j])
                write_id_x_addr[i][j] = 0;

            write_addr_x_wstrb_covered = 0;
            write_id_x_wstrb_covered   = 0;
            read_id_x_addr_covered     = 0;
            write_id_x_addr_covered    = 0;

        endfunction

        // ------------------------------------------------------------
        // WSTRB classification
        // ------------------------------------------------------------

        function automatic int classify_wstrb(bit [3:0] strb);

            if (strb == 4'b0000)
                return 0;

            if (strb == 4'b1111)
                return 1;

            if (
                strb == 4'b0001 ||
                strb == 4'b0010 ||
                strb == 4'b0100 ||
                strb == 4'b1000
            )
                return 2;

            return 3;

        endfunction

        // ------------------------------------------------------------
        // Address-region classification
        // ------------------------------------------------------------

        function automatic int classify_address(
            bit [7:0] address_word
        );

            if (address_word <= 8'd15)
                return 0;

            if (address_word <= 8'd63)
                return 1;

            return 2;

        endfunction

        // ------------------------------------------------------------
        // Transaction sampling
        // ------------------------------------------------------------

        function void write(axi4_transaction t);

            int id;
            int address_region;
            int wstrb_class;

            if (t == null) begin

                `uvm_error(
                    "AXI4_COV",
                    "Received null transaction"
                )

                return;

            end

            // ========================================================
            // WRITE
            // ========================================================

            if (t.is_write) begin

                operation_write++;

                id = t.awid;
                address_region = classify_address(t.awaddr[9:2]);
                wstrb_class = classify_wstrb(t.wstrb);

                // ----------------------------------------------------
                // Basic coverage
                // ----------------------------------------------------

                if (id >= 0 && id < 16)
                    write_id_bins[id]++;

                case (wstrb_class)

                    0: wstrb_none++;
                    1: wstrb_full++;
                    2: wstrb_byte++;
                    3: wstrb_partial++;

                endcase

                if (t.bresp == 2'b00)
                    bresp_okay++;
                else
                    bresp_other++;

                case (address_region)

                    0: write_address_low++;
                    1: write_address_mid++;
                    2: write_address_high++;

                endcase

                // ----------------------------------------------------
                // REAL CROSS:
                // WRITE ADDRESS × WSTRB
                // ----------------------------------------------------

                if (!write_addr_x_wstrb[address_region][wstrb_class]) begin

                    write_addr_x_wstrb[address_region][wstrb_class] = 1'b1;
                    write_addr_x_wstrb_covered++;

                end

                // ----------------------------------------------------
                // REAL CROSS:
                // WRITE ID × WSTRB
                // ----------------------------------------------------

                if (!write_id_x_wstrb[id][wstrb_class]) begin

                    write_id_x_wstrb[id][wstrb_class] = 1'b1;
                    write_id_x_wstrb_covered++;

                end

                // ----------------------------------------------------
                // REAL CROSS:
                // WRITE ID × ADDRESS
                // ----------------------------------------------------

                if (!write_id_x_addr[id][address_region]) begin

                    write_id_x_addr[id][address_region] = 1'b1;
                    write_id_x_addr_covered++;

                end

            end

            // ========================================================
            // READ
            // ========================================================

            else begin

                operation_read++;

                id = t.arid;
                address_region = classify_address(t.araddr[9:2]);

                // ----------------------------------------------------
                // Basic coverage
                // ----------------------------------------------------

                if (id >= 0 && id < 16)
                    read_id_bins[id]++;

                if (t.rresp == 2'b00)
                    rresp_okay++;
                else
                    rresp_other++;

                case (address_region)

                    0: read_address_low++;
                    1: read_address_mid++;
                    2: read_address_high++;

                endcase

                // ----------------------------------------------------
                // REAL CROSS:
                // READ ID × ADDRESS
                // ----------------------------------------------------

                if (!read_id_x_addr[id][address_region]) begin

                    read_id_x_addr[id][address_region] = 1'b1;
                    read_id_x_addr_covered++;

                end

            end

        endfunction

        // ------------------------------------------------------------
        // Manual executable coverage
        //
        // Total meaningful bins:
        //
        //   Operation                         2
        //   Read IDs                         16
        //   Write IDs                        16
        //   WSTRB classes                     4
        //   BRESP OKAY/OTHER                  2
        //   RRESP OKAY/OTHER                  2
        //   Read address regions               3
        //   Write address regions              3
        //   Write address × WSTRB            12
        //   Write ID × WSTRB                 64
        //   Read ID × address                48
        //   Write ID × address               48
        //
        //   Total                            220
        //
        // Coverage is based on unique bins actually sampled.
        // ------------------------------------------------------------

        function real get_coverage();

            int covered;
            int total;

            covered = 0;

            // Basic bins
            if (operation_read > 0)
                covered++;

            if (operation_write > 0)
                covered++;

            foreach (read_id_bins[i]) begin
                if (read_id_bins[i] > 0)
                    covered++;
            end

            foreach (write_id_bins[i]) begin
                if (write_id_bins[i] > 0)
                    covered++;
            end

            if (wstrb_none > 0)
                covered++;

            if (wstrb_full > 0)
                covered++;

            if (wstrb_byte > 0)
                covered++;

            if (wstrb_partial > 0)
                covered++;

            if (bresp_okay > 0)
                covered++;

            if (bresp_other > 0)
                covered++;

            if (rresp_okay > 0)
                covered++;

            if (rresp_other > 0)
                covered++;

            if (read_address_low > 0)
                covered++;

            if (read_address_mid > 0)
                covered++;

            if (read_address_high > 0)
                covered++;

            if (write_address_low > 0)
                covered++;

            if (write_address_mid > 0)
                covered++;

            if (write_address_high > 0)
                covered++;

            // Crosses
            covered += write_addr_x_wstrb_covered;
            covered += write_id_x_wstrb_covered;
            covered += read_id_x_addr_covered;
            covered += write_id_x_addr_covered;

            total = 220;

            return (100.0 * covered) / total;

        endfunction

        // ------------------------------------------------------------
        // Report phase
        // ------------------------------------------------------------

        function void report_phase(uvm_phase phase);

            real cov;

            super.report_phase(phase);

            cov = get_coverage();

            // Recalculate unique basic ID coverage.
            read_id_covered = 0;
            write_id_covered = 0;

            foreach (read_id_bins[i]) begin
                if (read_id_bins[i] > 0)
                    read_id_covered++;
            end

            foreach (write_id_bins[i]) begin
                if (write_id_bins[i] > 0)
                    write_id_covered++;
            end

            `uvm_info(
                "AXI4_COV",
                $sformatf(
                    "AXI4 FUNCTIONAL COVERAGE = %0.2f%%",
                    cov
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

            `uvm_info(
                "AXI4_COV",
                $sformatf(
                    "CROSS WRITE_ADDR_X_WSTRB = %0d/12",
                    write_addr_x_wstrb_covered
                ),
                UVM_NONE
            )

            `uvm_info(
                "AXI4_COV",
                $sformatf(
                    "CROSS WRITE_ID_X_WSTRB = %0d/64",
                    write_id_x_wstrb_covered
                ),
                UVM_NONE
            )

            `uvm_info(
                "AXI4_COV",
                $sformatf(
                    "CROSS READ_ID_X_ADDR = %0d/48",
                    read_id_x_addr_covered
                ),
                UVM_NONE
            )

            `uvm_info(
                "AXI4_COV",
                $sformatf(
                    "CROSS WRITE_ID_X_ADDR = %0d/48",
                    write_id_x_addr_covered
                ),
                UVM_NONE
            )

        endfunction

    endclass

endpackage

`endif
