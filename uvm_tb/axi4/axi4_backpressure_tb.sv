`timescale 1ns/1ps

module axi4_backpressure_tb;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam ID_WIDTH   = 4;

    logic clk;
    logic reset;

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

    logic [ID_WIDTH-1:0]   saved_bid;
    logic [1:0]            saved_bresp;

    logic [ID_WIDTH-1:0]   saved_rid;
    logic [DATA_WIDTH-1:0] saved_rdata;
    logic [1:0]            saved_rresp;
    logic                  saved_rlast;

    axi4_slave dut (
        .clk(clk),
        .reset(reset),

        .s_axi_awid(awid),
        .s_axi_awaddr(awaddr),
        .s_axi_awlen(awlen),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),

        .s_axi_wdata(wdata),
        .s_axi_wstrb(wstrb),
        .s_axi_wlast(wlast),
        .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),

        .s_axi_bid(bid),
        .s_axi_bresp(bresp),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(bready),

        .s_axi_arid(arid),
        .s_axi_araddr(araddr),
        .s_axi_arlen(arlen),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),

        .s_axi_rid(rid),
        .s_axi_rdata(rdata),
        .s_axi_rresp(rresp),
        .s_axi_rlast(rlast),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready)
    );

    axi4_protocol_sva sva (
        .clk(clk),
        .reset(reset),

        .awid(awid),
        .awaddr(awaddr),
        .awlen(awlen),
        .awvalid(awvalid),
        .awready(awready),

        .wdata(wdata),
        .wstrb(wstrb),
        .wlast(wlast),
        .wvalid(wvalid),
        .wready(wready),

        .bid(bid),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready),

        .arid(arid),
        .araddr(araddr),
        .arlen(arlen),
        .arvalid(arvalid),
        .arready(arready),

        .rid(rid),
        .rdata(rdata),
        .rresp(rresp),
        .rlast(rlast),
        .rvalid(rvalid),
        .rready(rready)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task automatic check(input bit condition, input string msg);
        if (condition)
            $display("[PASS] %s", msg);
        else begin
            $display("[FAIL] %s", msg);
            errors++;
        end
    endtask

    initial begin
        errors = 0;

        awid = '0;
        awaddr = '0;
        awlen = '0;
        awvalid = 0;

        wdata = '0;
        wstrb = '0;
        wlast = 0;
        wvalid = 0;

        bready = 0;

        arid = '0;
        araddr = '0;
        arlen = '0;
        arvalid = 0;

        rready = 0;

        reset = 1;
        repeat (3) @(posedge clk);
        reset = 0;

        // --------------------------------------------------------
        // WRITE: create BVALID and hold BREADY low
        // --------------------------------------------------------

        $display("");
        $display("=== WRITE BACKPRESSURE ===");

        @(negedge clk);

        awid = 4'hA;
        awaddr = 32'h00000040;
        awlen = 0;
        awvalid = 1;

        @(posedge clk);

        @(negedge clk);
        awvalid = 0;

        wdata = 32'hCAFE_BEEF;
        wstrb = 4'b1111;
        wlast = 1;
        wvalid = 1;

        @(posedge clk);

        @(negedge clk);
        wvalid = 0;

        // BVALID must now be asserted while BREADY remains low.
        @(posedge clk);

        check(bvalid, "BVALID asserted under backpressure");

        saved_bid = bid;
        saved_bresp = bresp;

        repeat (3) begin
            @(posedge clk);
            check(bvalid, "BVALID remains asserted while BREADY=0");
            check(bid == saved_bid, "BID remains stable while stalled");
            check(bresp == saved_bresp, "BRESP remains stable while stalled");
        end

        // Release response.
        @(negedge clk);
        bready = 1;

        @(posedge clk);

        @(negedge clk);
        bready = 0;

        // --------------------------------------------------------
        // READ: create RVALID and hold RREADY low
        // --------------------------------------------------------

        $display("");
        $display("=== READ BACKPRESSURE ===");

        @(negedge clk);

        arid = 4'hB;
        araddr = 32'h00000040;
        arlen = 0;
        arvalid = 1;

        @(posedge clk);

        @(negedge clk);
        arvalid = 0;

        // RVALID should be asserted.
        @(posedge clk);

        check(rvalid, "RVALID asserted under backpressure");

        saved_rid = rid;
        saved_rdata = rdata;
        saved_rresp = rresp;
        saved_rlast = rlast;

        repeat (3) begin
            @(posedge clk);
            check(rvalid, "RVALID remains asserted while RREADY=0");
            check(rid == saved_rid, "RID remains stable while stalled");
            check(rdata == saved_rdata, "RDATA remains stable while stalled");
            check(rresp == saved_rresp, "RRESP remains stable while stalled");
            check(rlast == saved_rlast, "RLAST remains stable while stalled");
        end

        // Release response.
        @(negedge clk);
        rready = 1;

        @(posedge clk);

        @(negedge clk);
        rready = 0;

        // --------------------------------------------------------
        // Result
        // --------------------------------------------------------

        $display("");
        $display("============================================================");

        if (errors == 0)
            $display("AXI4 BACKPRESSURE + SVA PASSED");
        else
            $display("AXI4 BACKPRESSURE + SVA FAILED: %0d errors", errors);

        $display("============================================================");

        $finish;
    end

endmodule
