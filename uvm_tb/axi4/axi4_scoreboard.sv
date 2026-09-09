`ifndef AXI4_SCOREBOARD_SV
`define AXI4_SCOREBOARD_SV

`include "uvm_macros.svh"

package axi4_scoreboard_pkg;

    import uvm_pkg::*;
    import axi4_pkg::*;

    class axi4_scoreboard extends uvm_scoreboard;

        `uvm_component_utils(axi4_scoreboard)

        uvm_analysis_imp #(axi4_transaction, axi4_scoreboard) analysis_export;

        localparam int MEM_DEPTH = 256;

        bit [31:0] model_mem [0:MEM_DEPTH-1];

        int write_count;
        int read_count;
        int error_count;

        function new(
            string name = "axi4_scoreboard",
            uvm_component parent = null
        );
            super.new(name, parent);
            analysis_export = new("analysis_export", this);
            write_count = 0;
            read_count  = 0;
            error_count = 0;

            foreach (model_mem[i])
                model_mem[i] = 32'h0000_0000;
        endfunction

        function void write(axi4_transaction tr);

            int unsigned word_index;
            bit [31:0] expected_data;

            if (tr == null) begin
                error_count++;
                `uvm_error(
                    "AXI4_SCB",
                    "Received null transaction"
                )
                return;
            end

            if (tr.is_write) begin

                write_count++;

                word_index = tr.awaddr[31:2];

                if (word_index >= MEM_DEPTH) begin
                    error_count++;
                    `uvm_error(
                        "AXI4_SCB",
                        $sformatf(
                            "WRITE address out of range: AWADDR=%08h",
                            tr.awaddr
                        )
                    )
                    return;
                end

                if (tr.bid !== tr.awid) begin
                    error_count++;
                    `uvm_error(
                        "AXI4_SCB",
                        $sformatf(
                            "WRITE ID mismatch: AWID=%0h BID=%0h",
                            tr.awid,
                            tr.bid
                        )
                    )
                end

                if (tr.bresp !== 2'b00) begin
                    error_count++;
                    `uvm_error(
                        "AXI4_SCB",
                        $sformatf(
                            "WRITE response error: BRESP=%0b",
                            tr.bresp
                        )
                    )
                end

                if (tr.wlast !== 1'b1) begin
                    error_count++;
                    `uvm_error(
                        "AXI4_SCB",
                        "WRITE WLAST is not asserted"
                    )
                end

                if (tr.wstrb[0])
                    model_mem[word_index][7:0] =
                        tr.wdata[7:0];

                if (tr.wstrb[1])
                    model_mem[word_index][15:8] =
                        tr.wdata[15:8];

                if (tr.wstrb[2])
                    model_mem[word_index][23:16] =
                        tr.wdata[23:16];

                if (tr.wstrb[3])
                    model_mem[word_index][31:24] =
                        tr.wdata[31:24];

                `uvm_info(
                    "AXI4_SCB",
                    $sformatf(
                        "WRITE checked: ADDR=%08h DATA=%08h STRB=%0h ID=%0h",
                        tr.awaddr,
                        tr.wdata,
                        tr.wstrb,
                        tr.awid
                    ),
                    UVM_MEDIUM
                )

            end
            else begin

                read_count++;

                word_index = tr.araddr[31:2];

                if (word_index >= MEM_DEPTH) begin
                    error_count++;
                    `uvm_error(
                        "AXI4_SCB",
                        $sformatf(
                            "READ address out of range: ARADDR=%08h",
                            tr.araddr
                        )
                    )
                    return;
                end

                expected_data = model_mem[word_index];

                if (tr.rid !== tr.arid) begin
                    error_count++;
                    `uvm_error(
                        "AXI4_SCB",
                        $sformatf(
                            "READ ID mismatch: ARID=%0h RID=%0h",
                            tr.arid,
                            tr.rid
                        )
                    )
                end

                if (tr.rresp !== 2'b00) begin
                    error_count++;
                    `uvm_error(
                        "AXI4_SCB",
                        $sformatf(
                            "READ response error: RRESP=%0b",
                            tr.rresp
                        )
                    )
                end

                if (tr.rlast !== 1'b1) begin
                    error_count++;
                    `uvm_error(
                        "AXI4_SCB",
                        "READ RLAST is not asserted"
                    )
                end

                if (tr.rdata !== expected_data) begin
                    error_count++;
                    `uvm_error(
                        "AXI4_SCB",
                        $sformatf(
                            "READ DATA mismatch: ADDR=%08h EXPECTED=%08h ACTUAL=%08h",
                            tr.araddr,
                            expected_data,
                            tr.rdata
                        )
                    )
                end
                else begin
                    `uvm_info(
                        "AXI4_SCB",
                        $sformatf(
                            "READ checked: ADDR=%08h DATA=%08h ID=%0h",
                            tr.araddr,
                            tr.rdata,
                            tr.arid
                        ),
                        UVM_MEDIUM
                    )
                end

            end

        endfunction

        function void report_phase(uvm_phase phase);

            super.report_phase(phase);

            if (error_count == 0) begin
                `uvm_info(
                    "AXI4_SCB",
                    $sformatf(
                        "AXI4 SCOREBOARD PASS: writes=%0d reads=%0d errors=%0d",
                        write_count,
                        read_count,
                        error_count
                    ),
                    UVM_NONE
                )
            end
            else begin
                `uvm_error(
                    "AXI4_SCB",
                    $sformatf(
                        "AXI4 SCOREBOARD FAIL: writes=%0d reads=%0d errors=%0d",
                        write_count,
                        read_count,
                        error_count
                    )
                )
            end

        endfunction

    endclass

endpackage

`endif
