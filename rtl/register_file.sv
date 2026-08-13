module register_file (
    input         clk,
    input         reset,

    input  [4:0]  read_addr1,
    input  [4:0]  read_addr2,

    input  [4:0]  write_addr,
    input  [31:0] write_data,
    input         write_enable,

    input         is_fp,

    output reg [31:0] read_data1,
    output reg [31:0] read_data2
);

    // --------------------------------------------------------
    // Register storage
    // --------------------------------------------------------
    reg [31:0] int_regs [31:0];
    reg [31:0] fp_regs  [31:0];

    integer i;

    // --------------------------------------------------------
    // Combinational read logic
    //
    // RISC-V integer x0 is hardwired to zero.
    // Floating-point registers do not have the x0 restriction.
    // --------------------------------------------------------
    always @(*) begin

        if (is_fp) begin

            read_data1 = fp_regs[read_addr1];
            read_data2 = fp_regs[read_addr2];

        end
        else begin

            if (read_addr1 == 5'd0)
                read_data1 = 32'b0;
            else
                read_data1 = int_regs[read_addr1];

            if (read_addr2 == 5'd0)
                read_data2 = 32'b0;
            else
                read_data2 = int_regs[read_addr2];

        end

    end

    // --------------------------------------------------------
    // Sequential write / reset logic
    //
    // Reset clears the complete integer and FP register files.
    //
    // Integer register x0 is never written.
    // --------------------------------------------------------
    always @(posedge clk or posedge reset) begin

        if (reset) begin

            for (i = 0; i < 32; i = i + 1) begin
                int_regs[i] <= 32'b0;
                fp_regs[i]  <= 32'b0;
            end

        end
        else if (write_enable) begin

            if (is_fp) begin

                fp_regs[write_addr] <= write_data;

            end
            else if (write_addr != 5'd0) begin

                int_regs[write_addr] <= write_data;

            end

        end

    end

endmodule
