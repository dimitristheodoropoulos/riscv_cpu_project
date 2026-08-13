module mmu (
    input         clk,
    input  [31:0] virtual_addr,
    input  [31:0] data_in,
    input         mem_read,
    input         mem_write,
    output reg [31:0] data_out,
    output     [31:0] physical_addr,
    output reg         mem_ready
);
    reg [31:0] memory [0:255];

    assign physical_addr = virtual_addr; // direct mapping, unchanged

    wire [7:0] mem_index = physical_addr[7:0]; // masked to 256-word range

    // Synchronous write (real RAM behavior)
    always @(posedge clk) begin
        if (mem_write)
            memory[mem_index] <= data_in;
    end

    // Combinational read + ready
    always @(*) begin
        data_out  = mem_read ? memory[mem_index] : 32'b0;
        mem_ready = mem_read || mem_write;
    end
endmodule
