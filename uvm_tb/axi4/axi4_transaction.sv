`ifndef AXI4_TRANSACTION_SV
`define AXI4_TRANSACTION_SV

`include "uvm_macros.svh"

package axi4_pkg;

    import uvm_pkg::*;

    // ------------------------------------------------------------
    // AXI4 transaction
    //
    // Current verification scope:
    //
    //   - AXI4
    //   - 32-bit address
    //   - 32-bit data
    //   - 4-bit transaction ID
    //   - single-beat transfers
    //
    // Contains:
    //
    //   Write address channel:
    //     - AWID
    //     - AWADDR
    //     - AWLEN
    //
    //   Write data channel:
    //     - WDATA
    //     - WSTRB
    //     - WLAST
    //
    //   Write response channel:
    //     - BID
    //     - BRESP
    //
    //   Read address channel:
    //     - ARID
    //     - ARADDR
    //     - ARLEN
    //
    //   Read data channel:
    //     - RID
    //     - RDATA
    //     - RRESP
    //     - RLAST
    //
    // Handshake timing is handled by the driver/monitor.
    // The transaction represents the transfer contents.
    // ------------------------------------------------------------

    class axi4_transaction extends uvm_sequence_item;

        // --------------------------------------------------------
        // AXI4 parameters
        // --------------------------------------------------------

        localparam int ADDR_WIDTH = 32;
        localparam int DATA_WIDTH = 32;
        localparam int ID_WIDTH   = 4;
        localparam int STRB_WIDTH = DATA_WIDTH / 8;

        // --------------------------------------------------------
        // Transaction operation
        // --------------------------------------------------------

        bit is_write;

        // --------------------------------------------------------
        // Write Address Channel
        // --------------------------------------------------------

        bit [ID_WIDTH-1:0]   awid;
        bit [ADDR_WIDTH-1:0] awaddr;
        bit [7:0]            awlen;

        // --------------------------------------------------------
        // Write Data Channel
        // --------------------------------------------------------

        bit [DATA_WIDTH-1:0] wdata;
        bit [STRB_WIDTH-1:0] wstrb;
        bit                  wlast;

        // --------------------------------------------------------
        // Write Response Channel
        // --------------------------------------------------------

        bit [ID_WIDTH-1:0] bid;
        bit [1:0]          bresp;

        // --------------------------------------------------------
        // Read Address Channel
        // --------------------------------------------------------

        bit [ID_WIDTH-1:0]   arid;
        bit [ADDR_WIDTH-1:0] araddr;
        bit [7:0]            arlen;

        // --------------------------------------------------------
        // Read Data Channel
        // --------------------------------------------------------

        bit [ID_WIDTH-1:0]   rid;
        bit [DATA_WIDTH-1:0] rdata;
        bit [1:0]            rresp;
        bit                  rlast;

        `uvm_object_utils(axi4_transaction)

        // --------------------------------------------------------
        // Constructor
        // --------------------------------------------------------

        function new(string name = "axi4_transaction");

            super.new(name);

            reset_transaction();

        endfunction

        // --------------------------------------------------------
        // Reset / initialize transaction contents
        // --------------------------------------------------------

        function void reset_transaction();

            // Transaction operation
            is_write = 1'b0;

            // Write address
            awid   = '0;
            awaddr = '0;
            awlen  = 8'h00;

            // Write data
            wdata = '0;
            wstrb = '1;
            wlast = 1'b1;

            // Write response
            bid   = '0;
            bresp = 2'b00;

            // Read address
            arid   = '0;
            araddr = '0;
            arlen  = 8'h00;

            // Read data
            rid   = '0;
            rdata = '0;
            rresp = 2'b00;
            rlast = 1'b1;

        endfunction

        // --------------------------------------------------------
        // Write address helper
        // --------------------------------------------------------

        function void set_write_address(
            bit [ID_WIDTH-1:0]   id,
            bit [ADDR_WIDTH-1:0] addr
        );

            is_write = 1'b1;

            awid   = id;
            awaddr = addr;
            awlen  = 8'h00;

        endfunction

        // --------------------------------------------------------
        // Write data helper
        // --------------------------------------------------------

        function void set_write_data(
            bit [DATA_WIDTH-1:0] data,
            bit [STRB_WIDTH-1:0] strb
        );

            wdata = data;
            wstrb = strb;
            wlast = 1'b1;

        endfunction

        // --------------------------------------------------------
        // Read address helper
        // --------------------------------------------------------

        function void set_read_address(
            bit [ID_WIDTH-1:0]   id,
            bit [ADDR_WIDTH-1:0] addr
        );

            is_write = 1'b0;

            arid   = id;
            araddr = addr;
            arlen  = 8'h00;

        endfunction

        // --------------------------------------------------------
        // UVM copy
        // --------------------------------------------------------

        function void do_copy(
            uvm_object rhs
        );

            axi4_transaction rhs_tr;

            super.do_copy(rhs);

            if (!$cast(rhs_tr, rhs)) begin

                `uvm_fatal(
                    "AXI4_TR_COPY",
                    "Failed to cast rhs to axi4_transaction"
                )

            end

            // Transaction operation
            is_write = rhs_tr.is_write;

            // Write address
            awid   = rhs_tr.awid;
            awaddr = rhs_tr.awaddr;
            awlen  = rhs_tr.awlen;

            // Write data
            wdata = rhs_tr.wdata;
            wstrb = rhs_tr.wstrb;
            wlast = rhs_tr.wlast;

            // Write response
            bid   = rhs_tr.bid;
            bresp = rhs_tr.bresp;

            // Read address
            arid   = rhs_tr.arid;
            araddr = rhs_tr.araddr;
            arlen  = rhs_tr.arlen;

            // Read data
            rid   = rhs_tr.rid;
            rdata = rhs_tr.rdata;
            rresp = rhs_tr.rresp;
            rlast = rhs_tr.rlast;

        endfunction

        // --------------------------------------------------------
        // UVM compare
        // --------------------------------------------------------

        function bit do_compare(
            uvm_object rhs,
            uvm_comparer comparer
        );

            axi4_transaction rhs_tr;

            if (!$cast(rhs_tr, rhs))
                return 0;

            if (!super.do_compare(rhs, comparer))
                return 0;

            if (is_write != rhs_tr.is_write)
                return 0;

            if (awid   != rhs_tr.awid)
                return 0;

            if (awaddr != rhs_tr.awaddr)
                return 0;

            if (awlen  != rhs_tr.awlen)
                return 0;

            if (wdata  != rhs_tr.wdata)
                return 0;

            if (wstrb  != rhs_tr.wstrb)
                return 0;

            if (wlast  != rhs_tr.wlast)
                return 0;

            if (bid    != rhs_tr.bid)
                return 0;

            if (bresp  != rhs_tr.bresp)
                return 0;

            if (arid   != rhs_tr.arid)
                return 0;

            if (araddr != rhs_tr.araddr)
                return 0;

            if (arlen  != rhs_tr.arlen)
                return 0;

            if (rid    != rhs_tr.rid)
                return 0;

            if (rdata  != rhs_tr.rdata)
                return 0;

            if (rresp  != rhs_tr.rresp)
                return 0;

            if (rlast  != rhs_tr.rlast)
                return 0;

            return 1;

        endfunction

        // --------------------------------------------------------
        // String representation
        // --------------------------------------------------------

        function string convert2string();

            return $sformatf(
                "AWID=%0h AWADDR=%08h AWLEN=%0d WDATA=%08h WSTRB=%0h WLAST=%0b BID=%0h BRESP=%0b ARID=%0h ARADDR=%08h ARLEN=%0d RID=%0h RDATA=%08h RRESP=%0b RLAST=%0b",
                awid,
                awaddr,
                awlen,
                wdata,
                wstrb,
                wlast,
                bid,
                bresp,
                arid,
                araddr,
                arlen,
                rid,
                rdata,
                rresp,
                rlast
            );

        endfunction

    endclass

endpackage

`endif
