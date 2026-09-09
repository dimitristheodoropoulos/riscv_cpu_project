`timescale 1ns/1ps

module axi4_handshake_stress_tb;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam ID_WIDTH   = 4;

    logic clk, reset;

    logic [ID_WIDTH-1:0] awid;
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [7:0] awlen;
    logic awvalid, awready;

    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH/8-1:0] wstrb;
    logic wlast, wvalid, wready;

    logic [ID_WIDTH-1:0] bid;
    logic [1:0] bresp;
    logic bvalid, bready;

    logic [ID_WIDTH-1:0] arid;
    logic [ADDR_WIDTH-1:0] araddr;
    logic [7:0] arlen;
    logic arvalid, arready;

    logic [ID_WIDTH-1:0] rid;
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0] rresp;
    logic rlast, rvalid, rready;

    int errors;

    axi4_slave dut (
        .clk(clk), .reset(reset),

        .s_axi_awid(awid), .s_axi_awaddr(awaddr),
        .s_axi_awlen(awlen), .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),

        .s_axi_wdata(wdata), .s_axi_wstrb(wstrb),
        .s_axi_wlast(wlast), .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),

        .s_axi_bid(bid), .s_axi_bresp(bresp),
        .s_axi_bvalid(bvalid), .s_axi_bready(bready),

        .s_axi_arid(arid), .s_axi_araddr(araddr),
        .s_axi_arlen(arlen), .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),

        .s_axi_rid(rid), .s_axi_rdata(rdata),
        .s_axi_rresp(rresp), .s_axi_rlast(rlast),
        .s_axi_rvalid(rvalid), .s_axi_rready(rready)
    );

    axi4_protocol_sva sva (
        .clk(clk), .reset(reset),

        .awid(awid), .awaddr(awaddr), .awlen(awlen),
        .awvalid(awvalid), .awready(awready),

        .wdata(wdata), .wstrb(wstrb), .wlast(wlast),
        .wvalid(wvalid), .wready(wready),

        .bid(bid), .bresp(bresp),
        .bvalid(bvalid), .bready(bready),

        .arid(arid), .araddr(araddr), .arlen(arlen),
        .arvalid(arvalid), .arready(arready),

        .rid(rid), .rdata(rdata), .rresp(rresp),
        .rlast(rlast), .rvalid(rvalid), .rready(rready)
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

        awid = 0;
        awaddr = 0;
        awlen = 0;
        awvalid = 0;

        wdata = 0;
        wstrb = 0;
        wlast = 0;
        wvalid = 0;

        bready = 0;

        arid = 0;
        araddr = 0;
        arlen = 0;
        arvalid = 0;

        rready = 0;

        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        reset = 1;
        repeat (3) @(posedge clk);
        reset = 0;

        // --------------------------------------------------------
        // W CHANNEL: WVALID before AW handshake
        // --------------------------------------------------------

        $display("");
        $display("=== W CHANNEL STALL ===");

        @(negedge clk);

        wdata  = 32'h1111_AAAA;
        wstrb  = 4'hF;
        wlast  = 1'b1;
        wvalid = 1'b1;

        // AW has not arrived, therefore WREADY must be low.
        @(posedge clk);

        check(!wready, "WREADY low before AW acceptance");
        check(wvalid, "WVALID held while WREADY=0");

        // Keep WVALID/data stable for two cycles.
        repeat (2) begin
            @(posedge clk);
            check(wvalid, "WVALID remains asserted before W handshake");
            check(wdata == 32'h1111_AAAA,
                  "WDATA remains stable before W handshake");
        end

        // --------------------------------------------------------
        // AW CHANNEL
        // --------------------------------------------------------

        $display("");
        $display("=== AW CHANNEL ===");

        @(negedge clk);

        awid    = 4'h1;
        awaddr  = 32'h00000080;
        awlen   = 0;
        awvalid = 1'b1;

        @(posedge clk);

        check(awready, "AWREADY asserted");
        check(awvalid && awready, "AW handshake");

        @(negedge clk);
        awvalid = 1'b0;

        // W can now handshake.
        @(posedge clk);

        check(wready, "WREADY asserted after AW acceptance");

        @(negedge clk);
        wvalid = 1'b0;

        // --------------------------------------------------------
        // B CHANNEL STALL + AW READY STALL
        // --------------------------------------------------------

        $display("");
        $display("=== B CHANNEL + AW BACKPRESSURE ===");

        @(posedge clk);

        check(bvalid, "BVALID asserted");
        check(!awready, "AWREADY blocked while BVALID is pending");

        // Present a second AW while AWREADY is low.
        @(negedge clk);

        awid    = 4'h2;
        awaddr  = 32'h00000084;
        awlen   = 0;
        awvalid = 1'b1;

        repeat (2) begin
            @(posedge clk);
            check(awvalid, "AWVALID held while AWREADY=0");
            check(!awready, "AWREADY remains low during B backpressure");
            check(awid == 4'h2, "AWID remains stable while stalled");
            check(awaddr == 32'h00000084,
                  "AWADDR remains stable while stalled");
        end

        // Release B.
        @(negedge clk);
        bready = 1'b1;

        @(posedge clk);

        // B handshake has completed, but AWREADY becomes available
        // only after the DUT updates BVALID.
        @(negedge clk);

        check(awvalid, "AWVALID remains asserted after B release");
        check(awready, "AWREADY asserted after B release");

        @(posedge clk);

        check(awvalid && awready, "AW handshake after B backpressure release");

        @(negedge clk);
        bready  = 1'b0;
        awvalid = 1'b0;

        // --------------------------------------------------------
        // READ RESPONSE + AR BACKPRESSURE
        // --------------------------------------------------------

        $display("");
        $display("=== R CHANNEL + AR BACKPRESSURE ===");

        // First read.
        @(negedge clk);

        arid    = 4'h3;
        araddr  = 32'h00000080;
        arlen   = 0;
        arvalid = 1'b1;

        @(posedge clk);

        check(arready, "ARREADY asserted");
        check(arvalid && arready, "AR handshake");

        @(negedge clk);
        arvalid = 1'b0;

        @(posedge clk);

        check(rvalid, "RVALID asserted");
        check(!arready, "ARREADY blocked while RVALID is pending");

        // Present second AR while ARREADY is low.
        @(negedge clk);

        arid    = 4'h4;
        araddr  = 32'h00000084;
        arlen   = 0;
        arvalid = 1'b1;

        repeat (2) begin
            @(posedge clk);
            check(arvalid, "ARVALID held while ARREADY=0");
            check(!arready, "ARREADY remains low during R backpressure");
            check(arid == 4'h4, "ARID remains stable while stalled");
            check(araddr == 32'h00000084,
                  "ARADDR remains stable while stalled");
        end

        // Release R.
        @(negedge clk);
        rready = 1'b1;

        @(posedge clk);

        @(negedge clk);
        rready  = 1'b0;
        arvalid = 1'b0;

        // --------------------------------------------------------
        // FINAL RESULT
        // --------------------------------------------------------

        $display("");
        $display("============================================================");

        if (errors == 0)
            $display("AXI4 HANDSHAKE STRESS PASSED");
        else
            $display("AXI4 HANDSHAKE STRESS FAILED: %0d errors", errors);

        $display("============================================================");

        $finish;
    end

endmodule
