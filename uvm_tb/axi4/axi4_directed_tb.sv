`timescale 1ns/1ps

module axi4_directed_tb;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam ID_WIDTH   = 4;

    logic clk;
    logic reset;

    // ------------------------------------------------------------
    // AXI4 signals
    // ------------------------------------------------------------

    logic [ID_WIDTH-1:0]     awid;
    logic [ADDR_WIDTH-1:0]   awaddr;
    logic [7:0]              awlen;
    logic                    awvalid;
    logic                    awready;

    logic [DATA_WIDTH-1:0]   wdata;
    logic [DATA_WIDTH/8-1:0] wstrb;
    logic                    wlast;
    logic                    wvalid;
    logic                    wready;

    logic [ID_WIDTH-1:0]     bid;
    logic [1:0]              bresp;
    logic                    bvalid;
    logic                    bready;

    logic [ID_WIDTH-1:0]     arid;
    logic [ADDR_WIDTH-1:0]   araddr;
    logic [7:0]              arlen;
    logic                    arvalid;
    logic                    arready;

    logic [ID_WIDTH-1:0]     rid;
    logic [DATA_WIDTH-1:0]   rdata;
    logic [1:0]              rresp;
    logic                    rlast;
    logic                    rvalid;
    logic                    rready;

    int errors;

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    axi4_slave dut (
        .clk        (clk),
        .reset      (reset),

        .s_axi_awid   (awid),
        .s_axi_awaddr (awaddr),
        .s_axi_awlen  (awlen),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),

        .s_axi_wdata  (wdata),
        .s_axi_wstrb  (wstrb),
        .s_axi_wlast  (wlast),
        .s_axi_wvalid (wvalid),
        .s_axi_wready (wready),

        .s_axi_bid    (bid),
        .s_axi_bresp  (bresp),
        .s_axi_bvalid (bvalid),
        .s_axi_bready (bready),

        .s_axi_arid   (arid),
        .s_axi_araddr (araddr),
        .s_axi_arlen  (arlen),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),

        .s_axi_rid    (rid),
        .s_axi_rdata  (rdata),
        .s_axi_rresp  (rresp),
        .s_axi_rlast  (rlast),
        .s_axi_rvalid (rvalid),
        .s_axi_rready (rready)
    );

    // ------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------

    task automatic check(
        input bit condition,
        input string message
    );
        if (condition) begin
            $display("[PASS] %s", message);
        end else begin
            $display("[FAIL] %s", message);
            errors++;
        end
    endtask

    task automatic axi_write(
        input logic [ID_WIDTH-1:0]   id,
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data
    );
        begin
            // ----------------------------------------------------
            // Write address
            // ----------------------------------------------------

            @(negedge clk);

            awid    = id;
            awaddr  = addr;
            awlen   = 8'd0;
            awvalid = 1'b1;

            do @(posedge clk);
            while (!awready);

            @(negedge clk);
            awvalid = 1'b0;

            // ----------------------------------------------------
            // Write data
            // ----------------------------------------------------

            wdata  = data;
            wstrb  = 4'b1111;
            wlast  = 1'b1;
            wvalid = 1'b1;

            do @(posedge clk);
            while (!wready);

            @(negedge clk);
            wvalid = 1'b0;

            // ----------------------------------------------------
            // Write response
            // ----------------------------------------------------

            bready = 1'b1;

            do @(posedge clk);
            while (!bvalid);

            check(bid == id, "Write response ID");
            check(bresp == 2'b00, "Write response OKAY");

            @(negedge clk);
            bready = 1'b0;
        end
    endtask

    task automatic axi_read(
        input logic [ID_WIDTH-1:0]   id,
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] expected_data
    );
        begin
            // ----------------------------------------------------
            // Read address
            // ----------------------------------------------------

            @(negedge clk);

            arid    = id;
            araddr  = addr;
            arlen   = 8'd0;
            arvalid = 1'b1;

            do @(posedge clk);
            while (!arready);

            @(negedge clk);
            arvalid = 1'b0;

            // ----------------------------------------------------
            // Read response
            // ----------------------------------------------------

            rready = 1'b1;

            do @(posedge clk);
            while (!rvalid);

            check(rid   == id,           "Read response ID");
            check(rdata == expected_data, "Read data");
            check(rresp == 2'b00,        "Read response OKAY");
            check(rlast == 1'b1,         "Read RLAST");

            @(negedge clk);
            rready = 1'b0;
        end
    endtask

    // ------------------------------------------------------------
    // Test
    // ------------------------------------------------------------

    initial begin
        errors = 0;

        awid    = '0;
        awaddr  = '0;
        awlen   = '0;
        awvalid = 1'b0;

        wdata   = '0;
        wstrb   = '0;
        wlast   = 1'b0;
        wvalid  = 1'b0;

        bready  = 1'b0;

        arid    = '0;
        araddr  = '0;
        arlen   = '0;
        arvalid = 1'b0;

        rready  = 1'b0;

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        reset = 1'b1;

        repeat (3) @(posedge clk);

        reset = 1'b0;

        @(posedge clk);

        check(
            !bvalid && !rvalid,
            "Reset clears response channels"
        );

        // --------------------------------------------------------
        // Single-beat write
        // --------------------------------------------------------

        $display("");
        $display("=== SINGLE-BEAT WRITE ===");

        axi_write(
            4'h5,
            32'h00000020,
            32'hA5A5_1234
        );

        // --------------------------------------------------------
        // Single-beat read
        // --------------------------------------------------------

        $display("");
        $display("=== SINGLE-BEAT READ ===");

        axi_read(
            4'h7,
            32'h00000020,
            32'hA5A5_1234
        );

        // --------------------------------------------------------
        // Result
        // --------------------------------------------------------

        $display("");
        $display("============================================================");

        if (errors == 0) begin
            $display("AXI4 DIRECTED SMOKE PASSED");
        end else begin
            $display(
                "AXI4 DIRECTED SMOKE FAILED: %0d errors",
                errors
            );
        end

        $display("============================================================");

        $finish;
    end

endmodule
