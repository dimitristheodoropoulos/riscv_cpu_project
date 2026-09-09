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

        task body();

            axi4_transaction write_tr;
            axi4_transaction read_tr;

            // ----------------------------------------------------
            // Single-beat write
            // ----------------------------------------------------

            write_tr = axi4_transaction::type_id::create(
                "write_tr"
            );

            start_item(write_tr);

            write_tr.set_write_address(
                4'h1,
                32'h0000_0010
            );

            write_tr.set_write_data(
                32'hA5A5_1234,
                4'b1111
            );

            finish_item(write_tr);

            `uvm_info(
                "AXI4_SEQ",
                "Single-beat WRITE transaction sent",
                UVM_MEDIUM
            )

            // ----------------------------------------------------
            // Single-beat read
            // ----------------------------------------------------

            read_tr = axi4_transaction::type_id::create(
                "read_tr"
            );

            start_item(read_tr);

            read_tr.set_read_address(
                4'h2,
                32'h0000_0010
            );

            finish_item(read_tr);

            `uvm_info(
                "AXI4_SEQ",
                "Single-beat READ transaction sent",
                UVM_MEDIUM
            )

        endtask

    endclass

endpackage

`endif
