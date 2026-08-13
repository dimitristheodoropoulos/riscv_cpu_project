// ========================================================
// REGISTER FILE REFERENCE MODEL
//
// Independent architectural model of the register file.
//
// This model:
//   - does NOT access DUT internals
//   - maintains independent integer/FP state
//   - models x0 hardwired-zero behavior
//   - models write enable
//   - models reset behavior
// ========================================================

module register_file_reference_model;

    reg [31:0] int_regs [0:31];
    reg [31:0] fp_regs  [0:31];

    integer i;

    // ----------------------------------------------------
    // Reset model state
    // ----------------------------------------------------

    task reset;

        begin

            for (i = 0; i < 32; i = i + 1) begin

                int_regs[i] = 32'b0;
                fp_regs[i]  = 32'b0;

            end

        end

    endtask

    // ----------------------------------------------------
    // Apply write transaction to reference model
    // ----------------------------------------------------

    task write;

        input [4:0]  addr;
        input [31:0] data;
        input        fp;
        input        enable;

        begin

            if (enable) begin

                if (fp) begin

                    fp_regs[addr] = data;

                end
                else if (addr != 5'd0) begin

                    int_regs[addr] = data;

                end

            end

        end

    endtask

    // ----------------------------------------------------
    // Predict read port 1
    // ----------------------------------------------------

    function [31:0] predict_read1;

        input [4:0] addr;
        input        fp;

        begin

            if (fp) begin

                predict_read1 = fp_regs[addr];

            end
            else if (addr == 5'd0) begin

                predict_read1 = 32'b0;

            end
            else begin

                predict_read1 = int_regs[addr];

            end

        end

    endfunction

    // ----------------------------------------------------
    // Predict read port 2
    // ----------------------------------------------------

    function [31:0] predict_read2;

        input [4:0] addr;
        input        fp;

        begin

            if (fp) begin

                predict_read2 = fp_regs[addr];

            end
            else if (addr == 5'd0) begin

                predict_read2 = 32'b0;

            end
            else begin

                predict_read2 = int_regs[addr];

            end

        end

    endfunction

endmodule