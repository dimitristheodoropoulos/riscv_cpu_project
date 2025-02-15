module cpu_tb;

    reg clk, reset;
    wire [31:0] result;

    // Instantiate the CPU core
    cpu_core uut (
        .clk(clk),
        .reset(reset),
        .result(result)
    );

    // Simulate memory as an array
    reg [31:0] memory [0:255];  // Memory array (size: 256 words)

    // Clock generation
    always begin
        #5 clk = ~clk;  // Toggle clock every 5 time units
    end

    // Simulate cache module with read/write operations
    always @(posedge clk) begin
        if (uut.cache_hit) begin
            // If cache hit, read data from cache
            uut.mmu_data_in <= uut.cache_data_out;
        end
        else if (uut.cache_miss) begin
            // If cache miss, fetch data from memory
            uut.mmu_data_in <= memory[uut.mmu_virtual_addr];
            // Load data into cache on a miss
            uut.cache_unit.cache_mem[uut.cache_index] <= memory[uut.mmu_virtual_addr];
            uut.cache_unit.tag[uut.cache_index] <= uut.mmu_virtual_addr[31:4];  // Update tag
            uut.cache_unit.valid[uut.cache_index] <= 1;  // Mark as valid
        end
        
        if (uut.mmu_mem_write) begin
            // Simulate memory write (write-through policy for simplicity)
            memory[uut.mmu_virtual_addr] <= uut.mmu_data_in;
            // Write data to cache as well
            uut.cache_unit.cache_mem[uut.cache_index] <= uut.mmu_data_in;
        end
    end

    initial begin
        clk = 0;
        reset = 1;
        #10;
        reset = 0;

        // Initialize some memory data (for testing)
        memory[32] = 32'd100;  // Example: memory at address 32 contains 100
        memory[64] = 32'd200;  // Example: memory at address 64 contains 200

        // Test 1: Simulate a CPU operation that results in cache access
        // Example instruction that results in ALU producing address 32 for read
        uut.mmu_virtual_addr = 32; // Example: ALU produces this virtual address
        #10;  // Wait a few clock cycles for memory read to happen

        // Display the result after cache access (hit/miss)
        if (uut.cache_hit) begin
            $display("Cache Hit: Read from cache at address 32: %d", result);
        end else begin
            $display("Cache Miss: Read from memory at address 32: %d", result);
        end
        
        // Test 2: Simulate a CPU write operation (e.g., store value into memory)
        uut.mmu_virtual_addr = 64; // Example: ALU produces this address
        uut.mmu_data_in = 32'd500; // Write 500 into memory at address 64
        #10;  // Wait a few clock cycles for memory write to happen

        // Display the result after write
        $display("Memory write to address 64: %d", memory[64]);
        $display("Cache state at address 64: %d", uut.cache_unit.cache_mem[64]);

        // Final step
        $finish;
    end

endmodule