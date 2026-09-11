`timescale 1ns/1ps

module axi4_master_tb;

    localparam int ADDR_WIDTH = 32;
    localparam int DATA_WIDTH = 32;
    localparam int ID_WIDTH   = 4;
    localparam int STRB_WIDTH = DATA_WIDTH / 8;

    logic clk;
    logic reset;

    // ------------------------------------------------------------------------
    // Local command interface
    // ------------------------------------------------------------------------

    logic                         cmd_valid;
    logic                         cmd_ready;
    logic                         cmd_write;
    logic [ID_WIDTH-1:0]         cmd_id;
    logic [ADDR_WIDTH-1:0]       cmd_addr;
    logic [DATA_WIDTH-1:0]       cmd_wdata;
    logic [STRB_WIDTH-1:0]       cmd_wstrb;

    // ------------------------------------------------------------------------
    // Local response interface
    // ------------------------------------------------------------------------

    logic                         rsp_valid;
    logic                         rsp_ready;
    logic [ID_WIDTH-1:0]         rsp_id;
    logic [DATA_WIDTH-1:0]       rsp_rdata;
    logic [1:0]                  rsp_resp;

    // ------------------------------------------------------------------------
    // AXI interface
    // ------------------------------------------------------------------------

    logic [ID_WIDTH-1:0]         m_axi_awid;
    logic [ADDR_WIDTH-1:0]       m_axi_awaddr;
    logic [7:0]                  m_axi_awlen;
    logic                         m_axi_awvalid;
    logic                         m_axi_awready;

    logic [DATA_WIDTH-1:0]       m_axi_wdata;
    logic [STRB_WIDTH-1:0]       m_axi_wstrb;
    logic                         m_axi_wlast;
    logic                         m_axi_wvalid;
    logic                         m_axi_wready;

    logic [ID_WIDTH-1:0]         m_axi_bid;
    logic [1:0]                  m_axi_bresp;
    logic                         m_axi_bvalid;
    logic                         m_axi_bready;

    logic [ID_WIDTH-1:0]         m_axi_arid;
    logic [ADDR_WIDTH-1:0]       m_axi_araddr;
    logic [7:0]                  m_axi_arlen;
    logic                         m_axi_arvalid;
    logic                         m_axi_arready;

    logic [ID_WIDTH-1:0]         m_axi_rid;
    logic [DATA_WIDTH-1:0]       m_axi_rdata;
    logic [1:0]                  m_axi_rresp;
    logic                         m_axi_rlast;
    logic                         m_axi_rvalid;
    logic                         m_axi_rready;

    integer errors;

    // ------------------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------------------

    axi4_master #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) dut (
        .clk            (clk),
        .reset          (reset),

        .cmd_valid      (cmd_valid),
        .cmd_ready      (cmd_ready),
        .cmd_write      (cmd_write),
        .cmd_id         (cmd_id),
        .cmd_addr       (cmd_addr),
        .cmd_wdata      (cmd_wdata),
        .cmd_wstrb      (cmd_wstrb),

        .rsp_valid      (rsp_valid),
        .rsp_ready      (rsp_ready),
        .rsp_id        (rsp_id),
        .rsp_rdata      (rsp_rdata),
        .rsp_resp       (rsp_resp),

        .m_axi_awid     (m_axi_awid),
        .m_axi_awaddr   (m_axi_awaddr),
        .m_axi_awlen    (m_axi_awlen),
        .m_axi_awvalid  (m_axi_awvalid),
        .m_axi_awready  (m_axi_awready),

        .m_axi_wdata   (m_axi_wdata),
        .m_axi_wstrb   (m_axi_wstrb),
        .m_axi_wlast   (m_axi_wlast),
        .m_axi_wvalid  (m_axi_wvalid),
        .m_axi_wready  (m_axi_wready),

        .m_axi_bid     (m_axi_bid),
        .m_axi_bresp   (m_axi_bresp),
        .m_axi_bvalid  (m_axi_bvalid),
        .m_axi_bready  (m_axi_bready),

        .m_axi_arid    (m_axi_arid),
        .m_axi_araddr  (m_axi_araddr),
        .m_axi_arlen   (m_axi_arlen),
        .m_axi_arvalid (m_axi_arvalid),
        .m_axi_arready (m_axi_arready),

        .m_axi_rid     (m_axi_rid),
        .m_axi_rdata   (m_axi_rdata),
        .m_axi_rresp   (m_axi_rresp),
        .m_axi_rlast   (m_axi_rlast),
        .m_axi_rvalid  (m_axi_rvalid),
        .m_axi_rready  (m_axi_rready)
    );

    // ------------------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------------------
    // Default AXI slave-side signals
    // ------------------------------------------------------------------------

    initial begin
        m_axi_awready = 1'b0;
        m_axi_wready  = 1'b0;

        m_axi_bid     = '0;
        m_axi_bresp   = 2'b00;
        m_axi_bvalid  = 1'b0;

        m_axi_arready = 1'b0;

        m_axi_rid     = '0;
        m_axi_rdata   = '0;
        m_axi_rresp   = 2'b00;
        m_axi_rlast   = 1'b1;
        m_axi_rvalid  = 1'b0;
    end

    // ------------------------------------------------------------------------
    // Reset
    // ------------------------------------------------------------------------

    task automatic reset_dut;
        begin
            reset      = 1'b1;

            cmd_valid  = 1'b0;
            cmd_write  = 1'b0;
            cmd_id     = '0;
            cmd_addr   = '0;
            cmd_wdata  = '0;
            cmd_wstrb  = '0;

            rsp_ready  = 1'b1;

            repeat (3) @(posedge clk);
            reset = 1'b0;
            repeat (1) @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------------------
    // Main smoke test
    // ------------------------------------------------------------------------

    initial begin
        errors = 0;

        reset = 1'b1;

        cmd_valid = 1'b0;
        cmd_write = 1'b0;
        cmd_id    = '0;
        cmd_addr  = '0;
        cmd_wdata = '0;
        cmd_wstrb = '0;

        rsp_ready = 1'b1;

        repeat (3) @(posedge clk);
        reset = 1'b0;

        // ================================================================
        // TEST 1: RESET / IDLE
        // ================================================================

        @(posedge clk);
        #1;

        if (!cmd_ready) begin
            $display("[ERROR] TEST 1: cmd_ready not asserted in IDLE");
            errors = errors + 1;
        end

        // ================================================================
        // TEST 2: WRITE COMMAND ACCEPTANCE
        // ================================================================

        @(negedge clk);

        cmd_id    = 4'h5;
        cmd_addr  = 32'h0000_0020;
        cmd_wdata = 32'hA5A5_1234;
        cmd_wstrb = 4'b1101;
        cmd_write = 1'b1;
        cmd_valid = 1'b1;

        @(posedge clk);
        #1;

        cmd_valid = 1'b0;

        // AW must now be valid.
        if (!m_axi_awvalid) begin
            $display("[ERROR] TEST 2: AWVALID not asserted");
            errors = errors + 1;
        end

        if (m_axi_awid !== 4'h5 ||
            m_axi_awaddr !== 32'h0000_0020 ||
            m_axi_awlen !== 8'd0) begin
            $display("[ERROR] TEST 2: AW payload mismatch");
            errors = errors + 1;
        end

        // ================================================================
        // TEST 3: AW BACKPRESSURE / STABILITY
        // ================================================================

        m_axi_awready = 1'b0;

        repeat (2) begin
            @(posedge clk);
            #1;

            if (!m_axi_awvalid) begin
                $display("[ERROR] TEST 3: AWVALID dropped under backpressure");
                errors = errors + 1;
            end

            if (m_axi_awid !== 4'h5 ||
                m_axi_awaddr !== 32'h0000_0020 ||
                m_axi_awlen !== 8'd0) begin
                $display("[ERROR] TEST 3: AW payload changed under backpressure");
                errors = errors + 1;
            end
        end

        // Accept AW.
        @(negedge clk);
        m_axi_awready = 1'b1;

        @(posedge clk);
        #1;

        m_axi_awready = 1'b0;

        // ================================================================
        // TEST 4: W CHANNEL / WSTRB / WLAST
        // ================================================================

        if (!m_axi_wvalid) begin
            $display("[ERROR] TEST 4: WVALID not asserted");
            errors = errors + 1;
        end

        if (m_axi_wdata !== 32'hA5A5_1234 ||
            m_axi_wstrb !== 4'b1101 ||
            m_axi_wlast !== 1'b1) begin
            $display("[ERROR] TEST 4: W payload mismatch");
            errors = errors + 1;
        end

        // Accept W.
        @(negedge clk);
        m_axi_wready = 1'b1;

        @(posedge clk);
        #1;

        m_axi_wready = 1'b0;

        // ================================================================
        // TEST 5: B RESPONSE
        // ================================================================

        if (!m_axi_bready) begin
            $display("[ERROR] TEST 5: BREADY not asserted");
            errors = errors + 1;
        end

        m_axi_bid    = 4'h5;
        m_axi_bresp  = 2'b00;
        m_axi_bvalid = 1'b1;

        @(posedge clk);
        #1;

        m_axi_bvalid = 1'b0;

        if (!rsp_valid) begin
            $display("[ERROR] TEST 5: local response not asserted");
            errors = errors + 1;
        end

        if (rsp_id !== 4'h5 ||
            rsp_resp !== 2'b00) begin
            $display("[ERROR] TEST 5: response mismatch");
            errors = errors + 1;
        end

        @(posedge clk);
        #1;

        // ================================================================
        // TEST 6: READ COMMAND
        // ================================================================

        @(negedge clk);

        cmd_id    = 4'hA;
        cmd_addr  = 32'h0000_0420;
        cmd_write = 1'b0;
        cmd_valid = 1'b1;

        @(posedge clk);
        #1;

        cmd_valid = 1'b0;

        if (!m_axi_arvalid) begin
            $display("[ERROR] TEST 6: ARVALID not asserted");
            errors = errors + 1;
        end

        if (m_axi_arid !== 4'hA ||
            m_axi_araddr !== 32'h0000_0420 ||
            m_axi_arlen !== 8'd0) begin
            $display("[ERROR] TEST 6: AR payload mismatch");
            errors = errors + 1;
        end

        // ================================================================
        // TEST 7: AR BACKPRESSURE / STABILITY
        // ================================================================

        m_axi_arready = 1'b0;

        repeat (2) begin
            @(posedge clk);
            #1;

            if (!m_axi_arvalid) begin
                $display("[ERROR] TEST 7: ARVALID dropped under backpressure");
                errors = errors + 1;
            end

            if (m_axi_arid !== 4'hA ||
                m_axi_araddr !== 32'h0000_0420 ||
                m_axi_arlen !== 8'd0) begin
                $display("[ERROR] TEST 7: AR payload changed under backpressure");
                errors = errors + 1;
            end
        end

        // Accept AR.
        @(negedge clk);
        m_axi_arready = 1'b1;

        @(posedge clk);
        #1;

        m_axi_arready = 1'b0;

        // ================================================================
        // TEST 8: R RESPONSE
        // ================================================================

        if (!m_axi_rready) begin
            $display("[ERROR] TEST 8: RREADY not asserted");
            errors = errors + 1;
        end

        m_axi_rid    = 4'hA;
        m_axi_rdata  = 32'hDEAD_BEEF;
        m_axi_rresp  = 2'b00;
        m_axi_rlast  = 1'b1;
        m_axi_rvalid = 1'b1;

        @(posedge clk);
        #1;

        m_axi_rvalid = 1'b0;

        if (!rsp_valid) begin
            $display("[ERROR] TEST 8: local response not asserted");
            errors = errors + 1;
        end

        if (rsp_id !== 4'hA ||
            rsp_rdata !== 32'hDEAD_BEEF ||
            rsp_resp !== 2'b00) begin
            $display("[ERROR] TEST 8: read response mismatch");
            errors = errors + 1;
        end

        @(posedge clk);
        #1;

        // ================================================================
        // RESULT
        // ================================================================

        if (errors == 0)
            $display("AXI4 MASTER V1: PASS");
        else
            $display("AXI4 MASTER V1: FAIL (%0d errors)", errors);

        $finish;
    end

endmodule
