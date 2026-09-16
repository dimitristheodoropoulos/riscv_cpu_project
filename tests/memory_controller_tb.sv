`timescale 1ns/1ps

module memory_controller_tb;

    logic        clk;
    logic        rst;
    logic        mem_valid;
    logic        mem_ready;
    logic        mem_write;
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [3:0]  mem_wstrb;
    logic [31:0] mem_rdata;

    integer pass_count;
    integer fail_count;

    logic [31:0] ref_mem [0:255];

    memory_controller dut (
        .clk       (clk),
        .rst       (rst),
        .mem_valid (mem_valid),
        .mem_ready  (mem_ready),
        .mem_write  (mem_write),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb  (mem_wstrb),
        .mem_rdata (mem_rdata)
    );

    always #5 clk = ~clk;

    task automatic check;
        input condition;
        input [255:0] message;
        begin
            if (condition) begin
                pass_count = pass_count + 1;
                $display("PASS: %s", message);
            end
            else begin
                fail_count = fail_count + 1;
                $display("FAIL: %s", message);
            end
        end
    endtask

    task automatic update_ref_write;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  strb;
        begin
            if (strb[0])
                ref_mem[addr[9:2]][7:0] = data[7:0];

            if (strb[1])
                ref_mem[addr[9:2]][15:8] = data[15:8];

            if (strb[2])
                ref_mem[addr[9:2]][23:16] = data[23:16];

            if (strb[3])
                ref_mem[addr[9:2]][31:24] = data[31:24];
        end
    endtask

    task automatic drive_write;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  strb;
        begin
            @(negedge clk);

            mem_valid = 1'b1;
            mem_write = 1'b1;
            mem_addr  = addr;
            mem_wdata = data;
            mem_wstrb = strb;

            #1;

            check(
                mem_ready === 1'b1,
                "write accepted when controller is ready"
            );

            @(posedge clk);
            #1;

            update_ref_write(addr, data, strb);

            mem_valid = 1'b0;
            mem_write = 1'b0;
            mem_wdata = 32'b0;
            mem_wstrb = 4'b0;
        end
    endtask

    task automatic drive_read;
        input [31:0] addr;
        begin
            @(negedge clk);

            mem_valid = 1'b1;
            mem_write = 1'b0;
            mem_addr  = addr;
            mem_wdata = 32'b0;
            mem_wstrb = 4'b0;

            #1;

            check(
                mem_ready === 1'b1,
                "read accepted when controller is ready"
            );

            check(
                mem_rdata === ref_mem[addr[9:2]],
                "read data matches reference model"
            );

            @(posedge clk);
            #1;

            mem_valid = 1'b0;
        end
    endtask

    initial begin
        clk        = 1'b0;
        rst        = 1'b1;
        mem_valid  = 1'b0;
        mem_write  = 1'b0;
        mem_addr   = 32'b0;
        mem_wdata  = 32'b0;
        mem_wstrb  = 4'b0;
        pass_count = 0;
        fail_count = 0;

        for (integer i = 0; i < 256; i = i + 1)
            ref_mem[i] = 32'bx;

        /*
         * MC-REQ-013:
         * Request acceptance is synchronous: it can occur only on a
         * clock edge when mem_valid && mem_ready is true.
         * mem_ready itself is combinationally deasserted while rst
         * is high and becomes asserted after reset release.
         */
        mem_valid = 1'b1;
        mem_write = 1'b1;
        mem_addr  = 32'h00000000;
        mem_wdata = 32'hDEADBEEF;
        mem_wstrb = 4'hF;

        @(posedge clk);
        #1;

        check(
            mem_ready === 1'b0,
            "reset prevents request acceptance"
        );

        /*
         * Release reset between clock edges.
         */
        @(negedge clk);
        rst = 1'b0;

        #1;

        check(
            mem_ready === 1'b1,
            "controller ready after reset release"
        );

        mem_valid = 1'b0;
        mem_write = 1'b0;
        mem_wdata = 32'b0;
        mem_wstrb = 4'b0;

        /*
         * MC-REQ-007 / MC-REQ-009 / MC-REQ-010
         * Lowest supported word address.
         */
        drive_write(
            32'h00000000,
            32'h11223344,
            4'hF
        );

        drive_read(32'h00000000);

        /*
         * MC-REQ-005 / MC-REQ-006
         * Partial write must preserve disabled bytes.
         */
        drive_write(
            32'h00000000,
            32'hAABBCCDD,
            4'b0101
        );

        drive_read(32'h00000000);

        /*
         * WSTRB = 0000: no byte may change.
         */
        drive_write(
            32'h00000000,
            32'hFFFFFFFF,
            4'b0000
        );

        drive_read(32'h00000000);

        /*
         * Representative multi-byte write.
         */
        drive_write(
            32'h00000004,
            32'hCAFEBABE,
            4'b0011
        );

        drive_read(32'h00000004);

        /*
         * Middle supported word address.
         */
        drive_write(
            32'h00000200,
            32'h55667788,
            4'hF
        );

        drive_read(32'h00000200);

        /*
         * Highest supported word address:
         * word index 255 -> byte address 0x000003FC.
         */
        drive_write(
            32'h000003FC,
            32'h89ABCDEF,
            4'hF
        );

        drive_read(32'h000003FC);

        /*
         * MC-REQ-012:
         * No write without mem_valid.
         */
        @(negedge clk);

        mem_valid = 1'b0;
        mem_write = 1'b1;
        mem_addr  = 32'h00000000;
        mem_wdata = 32'hFFFFFFFF;
        mem_wstrb = 4'hF;

        @(posedge clk);
        #1;

        mem_valid = 1'b0;
        mem_write = 1'b0;
        mem_wstrb = 4'b0;

        drive_read(32'h00000000);

        /*
         * MC-REQ-001:
         * Sequential single-cycle transactions.
         */
        drive_write(
            32'h00000008,
            32'h01020304,
            4'hF
        );

        drive_write(
            32'h0000000C,
            32'hA1A2A3A4,
            4'hF
        );

        drive_read(32'h00000008);
        drive_read(32'h0000000C);

        $display("");
        $display("========================================");
        $display("Memory Controller Verification Summary");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");

        $finish;
    end

endmodule
