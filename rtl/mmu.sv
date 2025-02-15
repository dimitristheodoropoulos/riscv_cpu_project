module mmu (
    input [31:0] virtual_addr,  // Input: virtual address
    input [31:0] data_in,       // Data to write to memory (if any)
    input mem_read,             // Read enable
    input mem_write,            // Write enable
    output reg [31:0] data_out, // Data read from memory
    output reg [31:0] physical_addr, // Translated physical address
    output reg mem_ready        // Indicate memory operation is complete
);

    reg [31:0] memory [0:255]; // A simple memory model (256 32-bit words)

    always @(*) begin
        // Default values
        data_out = 32'b0;
        physical_addr = virtual_addr;  // For simplicity, assume no virtual-to-physical mapping (direct mapping)
        mem_ready = 1'b0;

        // Memory Read
        if (mem_read) begin
            data_out = memory[physical_addr];  // Read from memory
            mem_ready = 1'b1;
        end
        
        // Memory Write
        if (mem_write) begin
            memory[physical_addr] = data_in;  // Write to memory
            mem_ready = 1'b1;
        end
    end

endmodule