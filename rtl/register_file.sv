module register_file (
    input clk,                          // Clock signal
    input reset,                        // Reset signal
    input [4:0] read_addr1, read_addr2, // Addresses for read ports
    input [4:0] write_addr,             // Address for write port
    input [31:0] write_data,            // Data to write
    input write_enable,                 // Write enable signal
    input is_fp,                        // Floating-point register select
    output reg [31:0] read_data1,       // Read data from port 1
    output reg [31:0] read_data2        // Read data from port 2
);

    reg [31:0] int_regs [31:0];  // 32 integer registers
    reg [31:0] fp_regs [31:0];   // 32 floating-point registers

    // Read operation (combinational logic)
    always @(*) begin
        if (is_fp) begin
            read_data1 = fp_regs[read_addr1];
            read_data2 = fp_regs[read_addr2];
        end else begin
            read_data1 = int_regs[read_addr1];
            read_data2 = int_regs[read_addr2];
        end
    end

    // Write operation (sequential logic)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            int_regs[write_addr] <= 32'b0;
            fp_regs[write_addr]  <= 32'b0;
        end else if (write_enable) begin
            if (is_fp)
                fp_regs[write_addr] <= write_data;
            else
                int_regs[write_addr] <= write_data;
        end
    end

endmodule
