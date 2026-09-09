`ifndef AXI4_MONITOR_SV
`define AXI4_MONITOR_SV

`include "uvm_macros.svh"

package axi4_monitor_pkg;

    import uvm_pkg::*;
    import axi4_pkg::*;

    class axi4_monitor extends uvm_monitor;

        `uvm_component_utils(axi4_monitor)

        virtual axi4_if vif;

        uvm_analysis_port #(axi4_transaction) analysis_port;

        axi4_transaction pending_write;
        axi4_transaction pending_read;

        function new(
            string name = "axi4_monitor",
            uvm_component parent = null
        );
            super.new(name, parent);

            analysis_port = new("analysis_port", this);
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
                    "AXI4_MON_NO_VIF",
                    "axi4_if virtual interface not found"
                )
            end
        endfunction

        task monitor_write_channel();

            forever begin

                @(posedge vif.clk);

                if (vif.awvalid && vif.awready) begin

                    if (pending_write == null)
                        pending_write = axi4_transaction::type_id::create(
                            "pending_write"
                        );

                      pending_write.is_write = 1'b1;
                    pending_write.awid   = vif.awid;
                    pending_write.awaddr = vif.awaddr;
                    pending_write.awlen  = vif.awlen;

                    `uvm_info(
                        "AXI4_MONITOR",
                        $sformatf(
                            "AW handshake: ID=%0h ADDR=%08h LEN=%0d",
                            vif.awid,
                            vif.awaddr,
                            vif.awlen
                        ),
                        UVM_HIGH
                    )
                end

                if (vif.wvalid && vif.wready) begin

                    if (pending_write == null)
                        pending_write = axi4_transaction::type_id::create(
                            "pending_write"
                        );

                    pending_write.wdata = vif.wdata;
                    pending_write.wstrb = vif.wstrb;
                    pending_write.wlast = vif.wlast;

                    `uvm_info(
                        "AXI4_MONITOR",
                        $sformatf(
                            "W handshake: DATA=%08h STRB=%0h LAST=%0b",
                            vif.wdata,
                            vif.wstrb,
                            vif.wlast
                        ),
                        UVM_HIGH
                    )
                end

                if (vif.bvalid && vif.bready) begin

                    if (pending_write == null)
                        pending_write = axi4_transaction::type_id::create(
                            "pending_write"
                        );

                    pending_write.bid   = vif.bid;
                    pending_write.bresp = vif.bresp;

                    `uvm_info(
                        "AXI4_MONITOR",
                        $sformatf(
                            "B handshake: ID=%0h RESP=%0b",
                            vif.bid,
                            vif.bresp
                        ),
                        UVM_HIGH
                    )

                    analysis_port.write(pending_write);

                    pending_write = null;
                end

            end

        endtask

        task monitor_read_channel();

            forever begin

                @(posedge vif.clk);

                if (vif.arvalid && vif.arready) begin

                    if (pending_read == null)
                        pending_read = axi4_transaction::type_id::create(
                            "pending_read"
                        );
                      pending_read.is_write = 1'b0;

                    pending_read.arid   = vif.arid;
                    pending_read.araddr = vif.araddr;
                    pending_read.arlen  = vif.arlen;

                    `uvm_info(
                        "AXI4_MONITOR",
                        $sformatf(
                            "AR handshake: ID=%0h ADDR=%08h LEN=%0d",
                            vif.arid,
                            vif.araddr,
                            vif.arlen
                        ),
                        UVM_HIGH
                    )
                end

                if (vif.rvalid && vif.rready) begin

                    if (pending_read == null)
                        pending_read = axi4_transaction::type_id::create(
                            "pending_read"
                        );

                    pending_read.rid   = vif.rid;
                    pending_read.rdata = vif.rdata;
                    pending_read.rresp = vif.rresp;
                    pending_read.rlast = vif.rlast;

                    `uvm_info(
                        "AXI4_MONITOR",
                        $sformatf(
                            "R handshake: ID=%0h DATA=%08h RESP=%0b LAST=%0b",
                            vif.rid,
                            vif.rdata,
                            vif.rresp,
                            vif.rlast
                        ),
                        UVM_HIGH
                    )

                    analysis_port.write(pending_read);

                    pending_read = null;
                end

            end

        endtask

        task run_phase(
            uvm_phase phase
        );

            pending_write = null;
            pending_read  = null;

            fork
                monitor_write_channel();
                monitor_read_channel();
            join

        endtask

    endclass

endpackage

`endif
