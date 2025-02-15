module mmu_tb;

    reg [31:0] virtual_addr, data_in;
    reg mem_read, mem_write;
    wire [31:0] data_out, physical_addr;
    wire mem_ready;

    // Instantiate the MMU module
    mmu uut (
        .virtual_addr(virtual_addr),
        .data_in(data_in),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .data_out(data_out),
        .physical_addr(physical_addr),
        .mem_ready(mem_ready)
    );

    initial begin
        // Initialize signals
        virtual_addr = 32'd0;
        data_in = 32'd0;
        mem_read = 0;
        mem_write = 0;

        // Test Memory Write
        #10;
        virtual_addr = 32'd10;        // Set address
        data_in = 32'd42;             // Set data to write
        mem_write = 1;                // Enable memory write
        #10;
        mem_write = 0;                // Disable memory write

        // Test Memory Read
        #10;
        mem_read = 1;                 // Enable memory read
        #10;
        $display("Memory Read Result: %d", data_out);  // Display the read data

        // Test another write and read
        #10;
        virtual_addr = 32'd20;        // Set another address
        data_in = 32'd84;             // Set data to write
        mem_write = 1;                // Enable memory write
        #10;
        mem_write = 0;                // Disable memory write

        // Read data from the new address
        #10;
        mem_read = 1;                 // Enable memory read
        #10;
        $display("Memory Read Result: %d", data_out);  // Display the read data

        $finish;
    end

endmodule
