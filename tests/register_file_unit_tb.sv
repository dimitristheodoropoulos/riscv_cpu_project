`timescale 1ns/1ps

module register_file_unit_tb;

    logic        clk;
    logic        reset;

    logic [4:0]  read_addr1;
    logic [4:0]  read_addr2;

    logic [4:0]  write_addr;
    logic [31:0] write_data;
    logic        write_enable;

    logic        is_fp;

    logic [31:0] read_data1;
    logic [31:0] read_data2;

    integer errors;

    register_file dut (
        .clk         (clk),
        .reset       (reset),

        .read_addr1  (read_addr1),
        .read_addr2  (read_addr2),

        .write_addr  (write_addr),
        .write_data  (write_data),
        .write_enable(write_enable),

        .is_fp       (is_fp),

        .read_data1  (read_data1),
        .read_data2  (read_data2)
    );

    always #5 clk = ~clk;

    // --------------------------------------------------------
    // Check tasks
    // --------------------------------------------------------

    task automatic check_read1;
        input [4:0]  addr;
        input [31:0] expected;
        input string name;

        begin
            read_addr1 = addr;
            #1;

            if (read_data1 !== expected) begin
                $display(
                    "FAIL: %s: read_data1 = %h, expected %h",
                    name,
                    read_data1,
                    expected
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: %s: read_data1 = %h",
                    name,
                    read_data1
                );
            end
        end
    endtask

    task automatic check_read2;
        input [4:0]  addr;
        input [31:0] expected;
        input string name;

        begin
            read_addr2 = addr;
            #1;

            if (read_data2 !== expected) begin
                $display(
                    "FAIL: %s: read_data2 = %h, expected %h",
                    name,
                    read_data2,
                    expected
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: %s: read_data2 = %h",
                    name,
                    read_data2
                );
            end
        end
    endtask

    task automatic write_int;
        input [4:0]  addr;
        input [31:0] data;

        begin
            is_fp        = 1'b0;
            write_enable = 1'b1;
            write_addr   = addr;
            write_data   = data;

            @(posedge clk);
            #1;

            write_enable = 1'b0;
        end
    endtask

    task automatic write_fp;
        input [4:0]  addr;
        input [31:0] data;

        begin
            is_fp        = 1'b1;
            write_enable = 1'b1;
            write_addr   = addr;
            write_data   = data;

            @(posedge clk);
            #1;

            write_enable = 1'b0;
        end
    endtask

    // --------------------------------------------------------
    // Test
    // --------------------------------------------------------

    initial begin

        clk          = 1'b0;
        reset        = 1'b1;

        read_addr1   = 5'd0;
        read_addr2   = 5'd0;

        write_addr   = 5'd0;
        write_data   = 32'd0;
        write_enable = 1'b0;
        is_fp        = 1'b0;

        errors       = 0;

        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (2) @(posedge clk);
        #1;

        reset = 1'b0;

        @(posedge clk);
        #1;

        // ----------------------------------------------------
        // Integer register file after reset
        // ----------------------------------------------------

        is_fp = 1'b0;
        check_read1(5'd0, 32'd0, "int x0 after reset");
        check_read1(5'd1, 32'd0, "int x1 after reset");
        check_read2(5'd2, 32'd0, "int x2 after reset");

        // ----------------------------------------------------
        // FP register file after reset
        // ----------------------------------------------------

        is_fp = 1'b1;
        check_read1(5'd1, 32'd0, "fp f1 after reset");
        check_read2(5'd2, 32'd0, "fp f2 after reset");

        // ----------------------------------------------------
        // Integer write / read
        // ----------------------------------------------------

        write_int(5'd3, 32'hDEAD_BEEF);
        is_fp = 1'b0;
        check_read1(5'd3, 32'hDEAD_BEEF, "int write/read x3");
        check_read2(5'd3, 32'hDEAD_BEEF, "int read x3 port2");

        // ----------------------------------------------------
        // x0 integer write protection
        // ----------------------------------------------------

        write_int(5'd0, 32'hFFFF_FFFF);
        is_fp = 1'b0;
        check_read1(5'd0, 32'd0, "x0 remains zero after write attempt");
        check_read2(5'd0, 32'd0, "x0 port2 remains zero");

        // ----------------------------------------------------
        // FP write / read
        // ----------------------------------------------------

        write_fp(5'd5, 32'h1234_5678);
        is_fp = 1'b1;
        check_read1(5'd5, 32'h1234_5678, "fp write/read f5");
        check_read2(5'd5, 32'h1234_5678, "fp read f5 port2");

        // ----------------------------------------------------
        // FP x0 is writable
        // ----------------------------------------------------

        write_fp(5'd0, 32'hA5A5_A5A5);
        is_fp = 1'b1;
        check_read1(5'd0, 32'hA5A5_A5A5, "fp f0 writeable");
        check_read2(5'd0, 32'hA5A5_A5A5, "fp f0 writeable port2");

        // ----------------------------------------------------
        // Final status
        // ----------------------------------------------------

        if (errors == 0) begin
            $display("");
            $display("REGISTER FILE UNIT VERIFICATION PASSED");
        end
        else begin
            $display("");
            $display(
                "REGISTER FILE UNIT VERIFICATION FAILED: %0d errors",
                errors
            );
        end

        $finish;
    end

endmodule