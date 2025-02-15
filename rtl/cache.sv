module cache (
    input [31:0] virtual_addr,   // Address from the CPU (ALU or MMU)
    input [31:0] data_in,        // Data to be written (in case of store)
    input mem_read,              // Memory read signal
    input mem_write,             // Memory write signal
    output reg [31:0] data_out,  // Data to be read from cache
    output reg hit,              // Cache hit signal
    output reg miss,             // Cache miss signal
    output reg [31:0] physical_addr  // Physical address corresponding to the cache line
);

    // Cache array to hold 16 cache lines (32-bit data)
    reg [31:0] cache_mem [0:15];
    reg [31:0] tag [0:15];      // Cache tag array for direct-mapped cache
    reg valid [0:15];           // Valid bit array for cache lines
    reg [3:0] index;           // Index for cache lookup (4-bit for 16 lines)

    // Memory simulation (for the sake of simplicity)
    reg [31:0] memory [0:255]; // Main memory (256 locations for simplicity)

    always @(*) begin
        // Calculate the cache index based on the lower 4 bits of the virtual address
        index = virtual_addr[3:0];
        physical_addr = tag[index];  // Physical address corresponds to the tag

        // Cache hit or miss logic
        if (valid[index] && tag[index] == virtual_addr[31:4]) begin
            hit = 1;      // Cache hit
            miss = 0;     // Cache miss
            data_out = cache_mem[index];  // Return data from cache
        end else begin
            hit = 0;      // Cache miss
            miss = 1;     // Cache miss
            data_out = memory[virtual_addr];  // Fetch data from memory
            // On cache miss, load data into cache and set tag
            cache_mem[index] = memory[virtual_addr];
            tag[index] = virtual_addr[31:4];  // Store the tag in the cache
            valid[index] = 1;  // Mark the cache entry as valid
        end
    end

    // Handle memory write (simple write-back policy)
    always @(posedge mem_write) begin
        if (valid[index]) begin
            memory[virtual_addr] = data_in;  // Write data back to memory
            cache_mem[index] = data_in;      // Also update cache
        end
    end

endmodule
