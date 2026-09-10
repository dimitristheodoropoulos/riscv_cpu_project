`timescale 1ns/1ps

module cache_v2_tb;

    logic        clk;
    logic        rst;

    // CPU-side request
    logic        req_valid;
    logic        req_ready;
    logic        req_write;
    logic [31:0] req_addr;
    logic [31:0] req_wdata;
    logic [3:0]  req_wstrb;

    // CPU-side response
    logic        rsp_valid;
    logic        rsp_ready;
    logic [31:0] rsp_rdata;

    // Backing-memory interface
    logic        mem_valid;
    logic        mem_ready;
    logic        mem_write;
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [3:0]  mem_wstrb;
    logic [31:0] mem_rdata;

    logic [31:0] backing_mem [0:255];

    integer errors;
    integer mem_read_count;
    integer mem_write_count;

    cache_v2 dut (
        .clk        (clk),
        .rst        (rst),

        .req_valid  (req_valid),
        .req_ready  (req_ready),
        .req_write  (req_write),
        .req_addr   (req_addr),
        .req_wdata  (req_wdata),
        .req_wstrb  (req_wstrb),

        .rsp_valid  (rsp_valid),
        .rsp_ready  (rsp_ready),
        .rsp_rdata  (rsp_rdata),

        .mem_valid  (mem_valid),
        .mem_ready  (mem_ready),
        .mem_write  (mem_write),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wstrb  (mem_wstrb),
        .mem_rdata  (mem_rdata)
    );

    always #5 clk = ~clk;

    // Simple combinational backing-memory read response.
    always_comb begin
        mem_rdata = backing_mem[mem_addr[9:2]];
    end

    // Backing-memory transaction model.
    always @(posedge clk) begin
        if (!rst && mem_valid && mem_ready) begin
            if (mem_write) begin
                mem_write_count <= mem_write_count + 1;

                if (mem_wstrb[0])
                    backing_mem[mem_addr[9:2]][7:0] <= mem_wdata[7:0];
                if (mem_wstrb[1])
                    backing_mem[mem_addr[9:2]][15:8] <= mem_wdata[15:8];
                if (mem_wstrb[2])
                    backing_mem[mem_addr[9:2]][23:16] <= mem_wdata[23:16];
                if (mem_wstrb[3])
                    backing_mem[mem_addr[9:2]][31:24] <= mem_wdata[31:24];
            end
            else begin
                mem_read_count <= mem_read_count + 1;
            end
        end
    end

    task automatic check(
        input logic condition,
        input string message
    );
        begin
            if (!condition) begin
                $display("[FAIL] %s", message);
                errors = errors + 1;
            end
            else begin
                $display("[PASS] %s", message);
            end
        end
    endtask

    task automatic reset_dut;
        integer i;
        begin
            rst = 1'b1;
            req_valid = 1'b0;
            req_write = 1'b0;
            req_addr  = 32'b0;
            req_wdata = 32'b0;
            req_wstrb = 4'b0;
            rsp_ready = 1'b1;
            mem_ready = 1'b1;

            for (i = 0; i < 256; i = i + 1)
                backing_mem[i] = 32'b0;

            mem_read_count  = 0;
            mem_write_count = 0;

            repeat (2) @(posedge clk);
            rst = 1'b0;
            @(posedge clk);
        end
    endtask

    task automatic cpu_read(
        input logic [31:0] addr,
        output logic [31:0] data
    );
        begin
            while (!req_ready)
                @(posedge clk);

            @(negedge clk);
            req_valid = 1'b1;
            req_write = 1'b0;
            req_addr  = addr;
            req_wdata = 32'b0;
            req_wstrb = 4'b0;

            @(posedge clk);

            @(negedge clk);
            req_valid = 1'b0;

            while (!rsp_valid)
                @(posedge clk);

            data = rsp_rdata;

            @(posedge clk);
        end
    endtask

    task automatic cpu_write(
        input logic [31:0] addr,
        input logic [31:0] data,
        input logic [3:0]  strb
    );
        begin
            while (!req_ready)
                @(posedge clk);

            @(negedge clk);
            req_valid = 1'b1;
            req_write = 1'b1;
            req_addr  = addr;
            req_wdata = data;
            req_wstrb = strb;

            @(posedge clk);

            @(negedge clk);
            req_valid = 1'b0;

            while (!rsp_valid)
                @(posedge clk);

            @(posedge clk);
        end
    endtask

    logic [31:0] rdata;

    // CACHE-REQ-013
    // Every accepted CPU request must satisfy the declared
    // word-alignment contract. This is a protocol check; it does
    // not introduce unaligned-request rejection behavior into the DUT.
    always @(posedge clk) begin
        if (!rst && req_valid && req_ready) begin
            if (req_addr[1:0] !== 2'b00) begin
                $display("[FAIL] CACHE-REQ-013: accepted CPU request is not word-aligned (addr=%h)",
                         req_addr);
                errors = errors + 1;
            end
            else begin
                $display("[PASS] CACHE-REQ-013: accepted CPU request is word-aligned");
            end
        end
    end

    initial begin
        clk = 1'b0;
        errors = 0;
        mem_read_count = 0;
        mem_write_count = 0;

        reset_dut();

        // --------------------------------------------------------
        // CACHE-REQ-001 / 003 / 004 / 010
        // First access: miss + refill.
        // Second access: hit, no backing-memory read.
        // --------------------------------------------------------

        backing_mem[32'h100 >> 2] = 32'h1122_3344;

        cpu_read(32'h0000_0100, rdata);
        check(rdata == 32'h1122_3344,
              "read miss returns backing-memory data");

        check(mem_read_count == 1,
              "read miss generates exactly one backing-memory read");

        cpu_read(32'h0000_0100, rdata);
        check(rdata == 32'h1122_3344,
              "subsequent access is a read hit");

        check(mem_read_count == 1,
              "read hit generates no additional backing-memory read");

        // --------------------------------------------------------
        // CACHE-REQ-001
        // Reset an already valid cache line, then access the same
        // address again. The post-reset access must miss and refill.
        // --------------------------------------------------------

        begin : reset_invalidation_check
            integer reads_before_reset;

            reads_before_reset = mem_read_count;

            rst = 1'b1;
            req_valid = 1'b0;
            req_write = 1'b0;
            req_addr  = 32'b0;
            req_wdata = 32'b0;
            req_wstrb = 4'b0;
            rsp_ready = 1'b1;
            mem_ready = 1'b1;

            repeat (2) @(posedge clk);

            rst = 1'b0;
            @(posedge clk);

            check(mem_read_count == reads_before_reset,
                  "reset invalidates cache without generating a memory transaction");

            cpu_read(32'h0000_0100, rdata);

            check(rdata == 32'h1122_3344,
                  "post-reset access returns backing-memory data");

            check(mem_read_count == reads_before_reset + 1,
                  "post-reset access refills instead of using the pre-reset cache line");
        end

        // --------------------------------------------------------
        // CACHE-REQ-005
        // Same index, different tag -> replacement.
        //
        // 0x0100: index = 0, tag = 4
        // 0x0500: index = 0, tag = 20
        // --------------------------------------------------------

        backing_mem[8'h40] = 32'hAABB_CCDD;

        cpu_read(32'h0000_0500, rdata);
        check(rdata == 32'hAABB_CCDD,
              "different tag at same index causes replacement");

        check(mem_read_count == 3,
              "replacement access causes backing-memory refill");

        // --------------------------------------------------------
        // CACHE-REQ-006
        // Write hit updates cache and backing memory.
        // --------------------------------------------------------

        cpu_write(32'h0000_0500, 32'h5566_7788, 4'b1111);

        check(backing_mem[8'h40] == 32'h5566_7788,
              "write hit updates backing memory");

        cpu_read(32'h0000_0500, rdata);
        check(rdata == 32'h5566_7788,
              "write hit updates cached data");

        // --------------------------------------------------------
        // CACHE-REQ-008
        // Partial WSTRB on an existing cache line.
        //
        // Initial cached value: 0x55667788
        // Write data:            0xAABBCCDD
        // WSTRB:                 0101
        // Expected result:       0x55BB77DD
        //
        // Bytes 0 and 2 are updated; bytes 1 and 3 remain unchanged.
        // --------------------------------------------------------

        cpu_write(32'h0000_0500, 32'hAABB_CCDD, 4'b0101);

        check(backing_mem[8'h40] == 32'h55BB_77DD,
              "write-hit WSTRB updates only selected backing-memory bytes");

        cpu_read(32'h0000_0500, rdata);

        check(rdata == 32'h55BB_77DD,
              "write-hit WSTRB updates only selected cached bytes");

        // --------------------------------------------------------
        // CACHE-REQ-007
        // Write miss updates backing memory without allocation.
        // --------------------------------------------------------

        backing_mem[8'h80] = 32'hDEAD_BEEF;

        cpu_write(32'h0000_0600, 32'hCAFE_BABE, 4'b1111);

        check(backing_mem[8'h80] == 32'hCAFE_BABE,
              "write miss updates backing memory");

        begin : no_write_allocate_check
            integer reads_before;

            reads_before = mem_read_count;

            cpu_read(32'h0000_0600, rdata);

            check(rdata == 32'hCAFE_BABE,
                  "write miss followed by read returns backing-memory data");

            check(mem_read_count == reads_before + 1,
                  "write miss does not allocate a cache line");
        end

        // --------------------------------------------------------
        // CACHE-REQ-008
        // WSTRB partial-byte update.
        // --------------------------------------------------------

        cpu_write(32'h0000_0600, 32'h1122_3344, 4'b0011);

        check(backing_mem[8'h80] == 32'hCAFE_3344,
              "WSTRB updates only selected low bytes");

        // --------------------------------------------------------
        // CACHE-REQ-009
        // Response stability under backpressure.
        // --------------------------------------------------------

        rsp_ready = 1'b0;

        cpu_write(32'h0000_0700, 32'h1234_5678, 4'b1111);

        check(rsp_valid,
              "response remains valid while rsp_ready is low");

        check(rsp_rdata == 32'b0,
              "write response data remains defined");

        repeat (3) @(posedge clk);

        check(rsp_valid,
              "response remains valid during backpressure");

        check(rsp_rdata == 32'b0,
              "response payload remains stable during backpressure");

        rsp_ready = 1'b1;
        @(posedge clk);

        // --------------------------------------------------------
        // CACHE-REQ-012
        // Backing-memory valid/ready protocol under backpressure.
        // --------------------------------------------------------

        begin : memory_backpressure_check
            integer reads_before;

            // Use a fresh cache line so this test is independent
            // of the preceding directed tests.
            backing_mem[8'hA0] = 32'hBEEF_1234;

            while (!req_ready)
                @(posedge clk);

            reads_before = mem_read_count;

            // Stall the backing memory before issuing the request.
            mem_ready = 1'b0;

            @(negedge clk);
            req_valid = 1'b1;
            req_write = 1'b0;
            req_addr  = 32'h0000_0280;
            req_wdata = 32'b0;
            req_wstrb = 4'b0;

            @(posedge clk);

            @(negedge clk);
            req_valid = 1'b0;

            // The request must enter REFILL and remain asserted
            // while the memory side is not ready.
            @(negedge clk);

            check(mem_valid,
                  "memory request is asserted while mem_ready is low");

            check(!rsp_valid,
                  "response is not generated while memory request is stalled");

            check(mem_read_count == reads_before,
                  "stalled memory read does not complete before mem_ready");

            repeat (3) begin
                @(negedge clk);

                check(mem_valid,
                      "memory request remains valid during backpressure");

                check(mem_read_count == reads_before,
                      "memory read count remains unchanged during backpressure");
            end

            // Release the memory-side backpressure.
            mem_ready = 1'b1;

            // Allow the handshake and response state transition to occur.
            @(posedge clk);
            @(negedge clk);

            check(mem_read_count == reads_before + 1,
                  "memory read completes after mem_ready is asserted");

            check(rsp_valid,
                  "response is generated after memory handshake");

            check(rsp_rdata == 32'hBEEF_1234,
                  "stalled memory read completes with correct data");

            // Accept the response.
            @(posedge clk);
        end

        // --------------------------------------------------------
        // CACHE-REQ-011
        // Request interface blocked while transaction is active.
        // --------------------------------------------------------

        while (!req_ready)
            @(posedge clk);

        @(negedge clk);
        req_valid = 1'b1;
        req_write = 1'b0;
        req_addr  = 32'h0000_0100;

        @(posedge clk);

        @(negedge clk);
        req_valid = 1'b0;

        check(!req_ready,
              "cache does not accept a second request while outstanding");

        while (!rsp_valid)
            @(posedge clk);

        @(posedge clk);

        // --------------------------------------------------------
        // Final result.
        // --------------------------------------------------------

        if (errors == 0)
            $display("\nCACHE_V2 DIRECTED TEST: PASS");
        else
            $display("\nCACHE_V2 DIRECTED TEST: FAIL (%0d errors)", errors);

        $finish;
    end

endmodule