`ifndef AXI4_SEQUENCE_SV
`define AXI4_SEQUENCE_SV

`include "uvm_macros.svh"

package axi4_sequence_pkg;

    import uvm_pkg::*;
    import axi4_pkg::*;

    class axi4_smoke_sequence extends uvm_sequence #(axi4_transaction);

        `uvm_object_utils(axi4_smoke_sequence)

        function new(
            string name = "axi4_smoke_sequence"
        );
            super.new(name);
        endfunction

        task send_write(
            bit [3:0]  id,
            bit [31:0] addr,
            bit [31:0] data,
            bit [3:0]  strb
        );

            axi4_transaction tr;

            tr = axi4_transaction::type_id::create("write_tr");

            start_item(tr);

            tr.set_write_address(id, addr);
            tr.set_write_data(data, strb);

            finish_item(tr);

        endtask

        task send_read(
            bit [3:0]  id,
            bit [31:0] addr
        );

            axi4_transaction tr;

            tr = axi4_transaction::type_id::create("read_tr");

            start_item(tr);

            tr.set_read_address(id, addr);

            finish_item(tr);

        endtask

        task body();

            // ========================================================
            // 1. FULL WRITE — LOW address
            // ========================================================

            send_write(
                4'h1,
                32'h0000_0010,
                32'hA5A5_1234,
                4'b1111
            );

            // ========================================================
            // 2. BYTE WRITE — LOW address
            // ========================================================

            send_write(
                4'h0,
                32'h0000_0014,
                32'h1122_3344,
                4'b0001
            );

            // ========================================================
            // 3. BYTE WRITE — MID address
            // ========================================================

            send_write(
                4'h3,
                32'h0000_0050,
                32'h5566_7788,
                4'b0100
            );

            // ========================================================
            // 4. PARTIAL WRITE — MID address
            // ========================================================

            send_write(
                4'h4,
                32'h0000_00A0,
                32'hDEAD_BEEF,
                4'b0110
            );

            // ========================================================
            // 5. NONE WSTRB — HIGH address
            // ========================================================

            send_write(
                4'hF,
                32'h0000_0200,
                32'hCAFE_BABE,
                4'b0000
            );

            // ========================================================
            // 6. FULL WRITE — HIGH address
            // ========================================================

            send_write(
                4'h2,
                32'h0000_0300,
                32'h1234_5678,
                4'b1111
            );

            // ========================================================
            // 7. READ — LOW address / ID 0
            // ========================================================

            send_read(
                4'h0,
                32'h0000_0010
            );

            // ========================================================
            // 8. READ — MID address / ID 4
            // ========================================================

            send_read(
                4'h4,
                32'h0000_0050
            );

            // ========================================================
            // 9. READ — HIGH address / ID F
            // ========================================================

            send_read(
                4'hF,
                32'h0000_0300
            );

            // ========================================================
            // 10. READ-after-WRITE — LOW address
            // ========================================================

            send_write(
                4'h5,
                32'h0000_0018,
                32'hFACE_CAFE,
                4'b1111
            );

            send_read(
                4'h6,
                32'h0000_0018
            );

            `uvm_info(
                "AXI4_SEQ",
                "Directed AXI4 coverage sequence completed",
                UVM_MEDIUM
            )

        endtask

    endclass

endpackage

`endif
