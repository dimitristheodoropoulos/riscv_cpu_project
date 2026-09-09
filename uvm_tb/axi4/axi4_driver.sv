`ifndef AXI4_DRIVER_SV
`define AXI4_DRIVER_SV

`include "uvm_macros.svh"

package axi4_driver_pkg;

    import uvm_pkg::*;
    import axi4_pkg::*;

    class axi4_driver extends uvm_driver #(axi4_transaction);

        `uvm_component_utils(axi4_driver)

        virtual axi4_if vif;

        function new(
            string name = "axi4_driver",
            uvm_component parent = null
        );

            super.new(name,parent);

        endfunction

        function void build_phase(
            uvm_phase phase
        );

            super.build_phase(phase);

            if (!uvm_config_db#(virtual axi4_if)::get(
                    this,
                    "",
                    "vif",
                    vif
                )) begin

                `uvm_fatal(
                    "AXI4_DRV_NO_VIF",
                    "axi4_if virtual interface not found"
                )

            end

        endfunction

        // --------------------------------------------------------
        // Drive single-beat AXI4 write
        //
        // AW and W are independent AXI channels.
        // The current DUT accepts AW before W, therefore this
        // first driver implementation uses:
        //
        //     AW handshake
        //          |
        //          v
        //     W handshake
        //          |
        //          v
        //     B handshake
        // --------------------------------------------------------

        task drive_write(
            axi4_transaction tr
        );

            // ----------------------------------------------------
            // AW CHANNEL
            // ----------------------------------------------------

            @(negedge vif.clk);

            vif.awid    = tr.awid;
            vif.awaddr  = tr.awaddr;
            vif.awlen   = 8'h00;
            vif.awvalid = 1'b1;

            do begin
                @(posedge vif.clk);
            end
            while (!vif.awready);

            @(negedge vif.clk);

            vif.awvalid = 1'b0;

            `uvm_info(
                "AXI4_DRIVER",
                $sformatf(
                    "AW handshake: ID=%0h ADDR=%08h",
                    tr.awid,
                    tr.awaddr
                ),
                UVM_HIGH
            )

            // ----------------------------------------------------
            // W CHANNEL
            // ----------------------------------------------------

            vif.wdata  = tr.wdata;
            vif.wstrb  = tr.wstrb;
            vif.wlast  = 1'b1;
            vif.wvalid = 1'b1;

            do begin
                @(posedge vif.clk);
            end
            while (!vif.wready);

            @(negedge vif.clk);

            vif.wvalid = 1'b0;

            `uvm_info(
                "AXI4_DRIVER",
                $sformatf(
                    "W handshake: DATA=%08h STRB=%0h",
                    tr.wdata,
                    tr.wstrb
                ),
                UVM_HIGH
            )

            // ----------------------------------------------------
            // B CHANNEL
            // ----------------------------------------------------

            vif.bready = 1'b1;

            do begin
                @(posedge vif.clk);
            end
            while (!vif.bvalid);

            tr.bid   = vif.bid;
            tr.bresp = vif.bresp;

            @(negedge vif.clk);

            vif.bready = 1'b0;

            `uvm_info(
                "AXI4_DRIVER",
                $sformatf(
                    "B response: ID=%0h RESP=%0b",
                    tr.bid,
                    tr.bresp
                ),
                UVM_HIGH
            )

        endtask

        // --------------------------------------------------------
        // Drive single-beat AXI4 read
        //
        //     AR handshake
        //          |
        //          v
        //     R handshake
        // --------------------------------------------------------

        task drive_read(
            axi4_transaction tr
        );

            // ----------------------------------------------------
            // AR CHANNEL
            // ----------------------------------------------------

            @(negedge vif.clk);

            vif.arid    = tr.arid;
            vif.araddr  = tr.araddr;
            vif.arlen   = 8'h00;
            vif.arvalid = 1'b1;

            do begin
                @(posedge vif.clk);
            end
            while (!vif.arready);

            @(negedge vif.clk);

            vif.arvalid = 1'b0;

            `uvm_info(
                "AXI4_DRIVER",
                $sformatf(
                    "AR handshake: ID=%0h ADDR=%08h",
                    tr.arid,
                    tr.araddr
                ),
                UVM_HIGH
            )

            // ----------------------------------------------------
            // R CHANNEL
            // ----------------------------------------------------

            vif.rready = 1'b1;

            do begin
                @(posedge vif.clk);
            end
            while (!vif.rvalid);

            tr.rid   = vif.rid;
            tr.rdata = vif.rdata;
            tr.rresp = vif.rresp;
            tr.rlast = vif.rlast;

            @(negedge vif.clk);

            vif.rready = 1'b0;

            `uvm_info(
                "AXI4_DRIVER",
                $sformatf(
                    "R response: ID=%0h DATA=%08h RESP=%0b LAST=%0b",
                    tr.rid,
                    tr.rdata,
                    tr.rresp,
                    tr.rlast
                ),
                UVM_HIGH
            )

        endtask

        // --------------------------------------------------------
        // Transaction initialization
        // --------------------------------------------------------

        task initialize_interface();

            vif.awid    = '0;
            vif.awaddr  = '0;
            vif.awlen   = '0;
            vif.awvalid = 1'b0;

            vif.wdata   = '0;
            vif.wstrb   = '0;
            vif.wlast   = 1'b0;
            vif.wvalid  = 1'b0;

            vif.bready  = 1'b0;

            vif.arid    = '0;
            vif.araddr  = '0;
            vif.arlen   = '0;
            vif.arvalid = 1'b0;

            vif.rready  = 1'b0;

        endtask

        // --------------------------------------------------------
        // Drive transaction
        // --------------------------------------------------------

        task drive_transaction(
            axi4_transaction tr
        );

            initialize_interface();

            if (tr.awlen != 8'h00) begin

                `uvm_fatal(
                    "AXI4_DRV_BURST",
                    $sformatf(
                        "Only single-beat writes are supported, AWLEN=%0d",
                        tr.awlen
                    )
                )

            end

            if (tr.arlen != 8'h00) begin

                `uvm_fatal(
                    "AXI4_DRV_BURST",
                    $sformatf(
                        "Only single-beat reads are supported, ARLEN=%0d",
                        tr.arlen
                    )
                )

            end

            if (tr.wlast !== 1'b1) begin

                `uvm_fatal(
                    "AXI4_DRV_WLAST",
                    "Single-beat write requires WLAST=1"
                )

            end

            `uvm_info(
                "AXI4_DRIVER",
                $sformatf(
                    "Driving AXI4 transaction: %s",
                    tr.convert2string()
                ),
                UVM_MEDIUM
            )

            // ----------------------------------------------------
            // Determine operation.
            //
            // A non-zero write address/data identifies a write;
            // otherwise a read is driven.
            //
            // This is temporary for the first foundation stage.
            // The transaction will later receive an explicit
            // operation field when constrained-random sequences
            // are introduced.
            // ----------------------------------------------------

              if (tr.is_write) begin

                  drive_write(tr);

              end
              else begin

                  drive_read(tr);

              end

        endtask

        // --------------------------------------------------------
        // Run phase
        // --------------------------------------------------------

        task run_phase(
            uvm_phase phase
        );

            axi4_transaction tr;

            // Wait for DUT reset deassertion before driving transactions.
            wait (vif.reset == 1'b0);

            forever begin

                seq_item_port.get_next_item(tr);

                drive_transaction(tr);

                seq_item_port.item_done();

            end

        endtask

    endclass

endpackage

`endif
