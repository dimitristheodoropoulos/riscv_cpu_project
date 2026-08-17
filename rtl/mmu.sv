module mmu (
    input         clk,
    input         reset,
    input  [31:0] virtual_addr,
    input  [31:0] data_in,
    input         mem_read,
    input         mem_write,
    output reg [31:0] data_out,
    output     [31:0] physical_addr,
    output reg         mem_ready
);
    reg [31:0] memory [0:255];

    assign physical_addr = virtual_addr;

    wire [7:0] mem_index = physical_addr[7:0];

    always @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 256; i++) begin
                memory[i] <= 32'b0;
            end
        end
        else if (mem_write) begin
            memory[mem_index] <= data_in;
        end
    end

    always @(*) begin
        data_out  = mem_read ? memory[mem_index] : 32'b0;
        mem_ready = mem_read || mem_write;
    end
endmodule