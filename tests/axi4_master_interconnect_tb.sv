`timescale 1ns/1ps

module axi4_master_interconnect_tb;

    localparam int ADDR_WIDTH = 32;
    localparam int DATA_WIDTH = 32;
    localparam int ID_WIDTH   = 4;
    localparam int STRB_WIDTH = DATA_WIDTH / 8;

    localparam logic [1:0] RESP_OKAY   = 2'b00;
    localparam logic [1:0] RESP_DECERR = 2'b11;

    logic clk;
    logic reset;

    integer errors;
    integer rsp_timeout;

    // ========================================================================
    // Master local command / response interface
    // ========================================================================

    logic                         cmd_valid;
    logic                         cmd_ready;
    logic                         cmd_write;
    logic [ID_WIDTH-1:0]          cmd_id;
    logic [ADDR_WIDTH-1:0]        cmd_addr;
    logic [DATA_WIDTH-1:0]        cmd_wdata;
    logic [STRB_WIDTH-1:0]        cmd_wstrb;

    logic                         rsp_valid;
    logic                         rsp_ready;
    logic [ID_WIDTH-1:0]          rsp_id;
    logic [DATA_WIDTH-1:0]        rsp_rdata;
    logic [1:0]                   rsp_resp;

    // ========================================================================
    // Master -> Interconnect AXI
    // ========================================================================

    logic [ID_WIDTH-1:0]       m_axi_awid;
    logic [ADDR_WIDTH-1:0]     m_axi_awaddr;
    logic [7:0]                m_axi_awlen;
    logic                      m_axi_awvalid;
    logic                      m_axi_awready;

    logic [DATA_WIDTH-1:0]     m_axi_wdata;
    logic [STRB_WIDTH-1:0]     m_axi_wstrb;
    logic                      m_axi_wlast;
    logic                      m_axi_wvalid;
    logic                      m_axi_wready;

    logic [ID_WIDTH-1:0]       m_axi_bid;
    logic [1:0]                m_axi_bresp;
    logic                      m_axi_bvalid;
    logic                      m_axi_bready;

    logic [ID_WIDTH-1:0]       m_axi_arid;
    logic [ADDR_WIDTH-1:0]     m_axi_araddr;
    logic [7:0]                m_axi_arlen;
    logic                      m_axi_arvalid;
    logic                      m_axi_arready;

    logic [ID_WIDTH-1:0]       m_axi_rid;
    logic [DATA_WIDTH-1:0]     m_axi_rdata;
    logic [1:0]                m_axi_rresp;
    logic                      m_axi_rlast;
    logic                      m_axi_rvalid;
    logic                      m_axi_rready;

    // ========================================================================
    // Interconnect -> Slave 0
    // ========================================================================

    logic [ID_WIDTH-1:0]       s0_axi_awid;
    logic [ADDR_WIDTH-1:0]     s0_axi_awaddr;
    logic [7:0]                s0_axi_awlen;
    logic                      s0_axi_awvalid;
    logic                      s0_axi_awready;

    logic [DATA_WIDTH-1:0]     s0_axi_wdata;
    logic [STRB_WIDTH-1:0]     s0_axi_wstrb;
    logic                      s0_axi_wlast;
    logic                      s0_axi_wvalid;
    logic                      s0_axi_wready;

    logic [ID_WIDTH-1:0]       s0_axi_bid;
    logic [1:0]                s0_axi_bresp;
    logic                      s0_axi_bvalid;
    logic                      s0_axi_bready;

    logic [ID_WIDTH-1:0]       s0_axi_arid;
    logic [ADDR_WIDTH-1:0]     s0_axi_araddr;
    logic [7:0]                s0_axi_arlen;
    logic                      s0_axi_arvalid;
    logic                      s0_axi_arready;

    logic [ID_WIDTH-1:0]       s0_axi_rid;
    logic [DATA_WIDTH-1:0]     s0_axi_rdata;
    logic [1:0]                s0_axi_rresp;
    logic                      s0_axi_rlast;
    logic                      s0_axi_rvalid;
    logic                      s0_axi_rready;

    // ========================================================================
    // Interconnect -> Slave 1
    // ========================================================================

    logic [ID_WIDTH-1:0]       s1_axi_awid;
    logic [ADDR_WIDTH-1:0]     s1_axi_awaddr;
    logic [7:0]                s1_axi_awlen;
    logic                      s1_axi_awvalid;
    logic                      s1_axi_awready;

    logic [DATA_WIDTH-1:0]     s1_axi_wdata;
    logic [STRB_WIDTH-1:0]     s1_axi_wstrb;
    logic                      s1_axi_wlast;
    logic                      s1_axi_wvalid;
    logic                      s1_axi_wready;

    logic [ID_WIDTH-1:0]       s1_axi_bid;
    logic [1:0]                s1_axi_bresp;
    logic                      s1_axi_bvalid;
    logic                      s1_axi_bready;

    logic [ID_WIDTH-1:0]       s1_axi_arid;
    logic [ADDR_WIDTH-1:0]     s1_axi_araddr;
    logic [7:0]                s1_axi_arlen;
    logic                      s1_axi_arvalid;
    logic                      s1_axi_arready;

    logic [ID_WIDTH-1:0]       s1_axi_rid;
    logic [DATA_WIDTH-1:0]     s1_axi_rdata;
    logic [1:0]                s1_axi_rresp;
    logic                      s1_axi_rlast;
    logic                      s1_axi_rvalid;
    logic                      s1_axi_rready;

    // ========================================================================
    // DUT: AXI4 Master
    // ========================================================================

    axi4_master #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) master (
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
        .rsp_id         (rsp_id),
        .rsp_rdata      (rsp_rdata),
        .rsp_resp       (rsp_resp),

        .m_axi_awid     (m_axi_awid),
        .m_axi_awaddr   (m_axi_awaddr),
        .m_axi_awlen    (m_axi_awlen),
        .m_axi_awvalid  (m_axi_awvalid),
        .m_axi_awready  (m_axi_awready),

        .m_axi_wdata    (m_axi_wdata),
        .m_axi_wstrb    (m_axi_wstrb),
        .m_axi_wlast    (m_axi_wlast),
        .m_axi_wvalid   (m_axi_wvalid),
        .m_axi_wready   (m_axi_wready),

        .m_axi_bid      (m_axi_bid),
        .m_axi_bresp    (m_axi_bresp),
        .m_axi_bvalid   (m_axi_bvalid),
        .m_axi_bready   (m_axi_bready),

        .m_axi_arid     (m_axi_arid),
        .m_axi_araddr   (m_axi_araddr),
        .m_axi_arlen    (m_axi_arlen),
        .m_axi_arvalid  (m_axi_arvalid),
        .m_axi_arready  (m_axi_arready),

        .m_axi_rid      (m_axi_rid),
        .m_axi_rdata    (m_axi_rdata),
        .m_axi_rresp    (m_axi_rresp),
        .m_axi_rlast    (m_axi_rlast),
        .m_axi_rvalid   (m_axi_rvalid),
        .m_axi_rready   (m_axi_rready)
    );

    // ========================================================================
    // DUT: AXI4 Interconnect
    // ========================================================================

    axi4_interconnect #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) u_interconnect (
        .clk            (clk),
        .reset          (reset),

        .m_axi_awid     (m_axi_awid),
        .m_axi_awaddr   (m_axi_awaddr),
        .m_axi_awlen    (m_axi_awlen),
        .m_axi_awvalid  (m_axi_awvalid),
        .m_axi_awready  (m_axi_awready),

        .m_axi_wdata    (m_axi_wdata),
        .m_axi_wstrb    (m_axi_wstrb),
        .m_axi_wlast    (m_axi_wlast),
        .m_axi_wvalid   (m_axi_wvalid),
        .m_axi_wready   (m_axi_wready),

        .m_axi_bid      (m_axi_bid),
        .m_axi_bresp    (m_axi_bresp),
        .m_axi_bvalid   (m_axi_bvalid),
        .m_axi_bready   (m_axi_bready),

        .m_axi_arid     (m_axi_arid),
        .m_axi_araddr   (m_axi_araddr),
        .m_axi_arlen    (m_axi_arlen),
        .m_axi_arvalid  (m_axi_arvalid),
        .m_axi_arready  (m_axi_arready),

        .m_axi_rid      (m_axi_rid),
        .m_axi_rdata    (m_axi_rdata),
        .m_axi_rresp    (m_axi_rresp),
        .m_axi_rlast    (m_axi_rlast),
        .m_axi_rvalid   (m_axi_rvalid),
        .m_axi_rready   (m_axi_rready),

        .s0_axi_awid    (s0_axi_awid),
        .s0_axi_awaddr  (s0_axi_awaddr),
        .s0_axi_awlen   (s0_axi_awlen),
        .s0_axi_awvalid (s0_axi_awvalid),
        .s0_axi_awready (s0_axi_awready),

        .s0_axi_wdata   (s0_axi_wdata),
        .s0_axi_wstrb   (s0_axi_wstrb),
        .s0_axi_wlast   (s0_axi_wlast),
        .s0_axi_wvalid  (s0_axi_wvalid),
        .s0_axi_wready  (s0_axi_wready),

        .s0_axi_bid     (s0_axi_bid),
        .s0_axi_bresp   (s0_axi_bresp),
        .s0_axi_bvalid  (s0_axi_bvalid),
        .s0_axi_bready  (s0_axi_bready),

        .s0_axi_arid    (s0_axi_arid),
        .s0_axi_araddr  (s0_axi_araddr),
        .s0_axi_arlen   (s0_axi_arlen),
        .s0_axi_arvalid (s0_axi_arvalid),
        .s0_axi_arready (s0_axi_arready),

        .s0_axi_rid     (s0_axi_rid),
        .s0_axi_rdata   (s0_axi_rdata),
        .s0_axi_rresp   (s0_axi_rresp),
        .s0_axi_rlast   (s0_axi_rlast),
        .s0_axi_rvalid  (s0_axi_rvalid),
        .s0_axi_rready  (s0_axi_rready),

        .s1_axi_awid    (s1_axi_awid),
        .s1_axi_awaddr  (s1_axi_awaddr),
        .s1_axi_awlen   (s1_axi_awlen),
        .s1_axi_awvalid (s1_axi_awvalid),
        .s1_axi_awready (s1_axi_awready),

        .s1_axi_wdata   (s1_axi_wdata),
        .s1_axi_wstrb   (s1_axi_wstrb),
        .s1_axi_wlast   (s1_axi_wlast),
        .s1_axi_wvalid  (s1_axi_wvalid),
        .s1_axi_wready  (s1_axi_wready),

        .s1_axi_bid     (s1_axi_bid),
        .s1_axi_bresp   (s1_axi_bresp),
        .s1_axi_bvalid  (s1_axi_bvalid),
        .s1_axi_bready  (s1_axi_bready),

        .s1_axi_arid    (s1_axi_arid),
        .s1_axi_araddr  (s1_axi_araddr),
        .s1_axi_arlen   (s1_axi_arlen),
        .s1_axi_arvalid (s1_axi_arvalid),
        .s1_axi_arready (s1_axi_arready),

        .s1_axi_rid     (s1_axi_rid),
        .s1_axi_rdata   (s1_axi_rdata),
        .s1_axi_rresp   (s1_axi_rresp),
        .s1_axi_rlast   (s1_axi_rlast),
        .s1_axi_rvalid  (s1_axi_rvalid),
        .s1_axi_rready  (s1_axi_rready)
    );

    // ========================================================================
    // Existing AXI4 Slave 0
    // ========================================================================

    axi4_slave #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .MEM_DEPTH  (256)
    ) slave0 (
        .clk            (clk),
        .reset          (reset),

        .s_axi_awid     (s0_axi_awid),
        .s_axi_awaddr   (s0_axi_awaddr),
        .s_axi_awlen    (s0_axi_awlen),
        .s_axi_awvalid  (s0_axi_awvalid),
        .s_axi_awready  (s0_axi_awready),

        .s_axi_wdata    (s0_axi_wdata),
        .s_axi_wstrb    (s0_axi_wstrb),
        .s_axi_wlast    (s0_axi_wlast),
        .s_axi_wvalid   (s0_axi_wvalid),
        .s_axi_wready   (s0_axi_wready),

        .s_axi_bid      (s0_axi_bid),
        .s_axi_bresp    (s0_axi_bresp),
        .s_axi_bvalid   (s0_axi_bvalid),
        .s_axi_bready   (s0_axi_bready),

        .s_axi_arid     (s0_axi_arid),
        .s_axi_araddr   (s0_axi_araddr),
        .s_axi_arlen    (s0_axi_arlen),
        .s_axi_arvalid  (s0_axi_arvalid),
        .s_axi_arready  (s0_axi_arready),

        .s_axi_rid      (s0_axi_rid),
        .s_axi_rdata    (s0_axi_rdata),
        .s_axi_rresp    (s0_axi_rresp),
        .s_axi_rlast    (s0_axi_rlast),
        .s_axi_rvalid   (s0_axi_rvalid),
        .s_axi_rready   (s0_axi_rready)
    );

    // ========================================================================
    // Existing AXI4 Slave 1
    // ========================================================================

    axi4_slave #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .MEM_DEPTH  (256)
    ) slave1 (
        .clk            (clk),
        .reset          (reset),

        .s_axi_awid     (s1_axi_awid),
        .s_axi_awaddr   (s1_axi_awaddr),
        .s_axi_awlen    (s1_axi_awlen),
        .s_axi_awvalid  (s1_axi_awvalid),
        .s_axi_awready  (s1_axi_awready),

        .s_axi_wdata    (s1_axi_wdata),
        .s_axi_wstrb    (s1_axi_wstrb),
        .s_axi_wlast    (s1_axi_wlast),
        .s_axi_wvalid   (s1_axi_wvalid),
        .s_axi_wready   (s1_axi_wready),

        .s_axi_bid      (s1_axi_bid),
        .s_axi_bresp    (s1_axi_bresp),
        .s_axi_bvalid   (s1_axi_bvalid),
        .s_axi_bready   (s1_axi_bready),

        .s_axi_arid     (s1_axi_arid),
        .s_axi_araddr   (s1_axi_araddr),
        .s_axi_arlen    (s1_axi_arlen),
        .s_axi_arvalid  (s1_axi_arvalid),
        .s_axi_arready  (s1_axi_arready),

        .s_axi_rid      (s1_axi_rid),
        .s_axi_rdata    (s1_axi_rdata),
        .s_axi_rresp    (s1_axi_rresp),
        .s_axi_rlast    (s1_axi_rlast),
        .s_axi_rvalid   (s1_axi_rvalid),
        .s_axi_rready   (s1_axi_rready)
    );

    // ========================================================================
    // Clock
    // ========================================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ========================================================================
    // Helpers
    // ========================================================================

    task automatic send_command(
        input logic                  write,
        input logic [ID_WIDTH-1:0]   id,
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input logic [STRB_WIDTH-1:0] strb
    );
        begin
            @(negedge clk);

            cmd_write = write;
            cmd_id    = id;
            cmd_addr  = addr;
            cmd_wdata = data;
            cmd_wstrb = strb;
            cmd_valid = 1'b1;

            while (!cmd_ready)
                @(posedge clk);

            @(posedge clk);
            #1;

            cmd_valid = 1'b0;
        end
    endtask

    task automatic wait_response(
        input logic [ID_WIDTH-1:0]   expected_id,
        input logic [DATA_WIDTH-1:0] expected_data,
        input logic [1:0]            expected_resp,
        input string                 test_name
    );
        integer timeout;
        begin
            timeout = 0;

            while (!rsp_valid && timeout < 50) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 50) begin
                $display("[ERROR] %s: response timeout", test_name);
                errors = errors + 1;
            end
            else begin
                if (rsp_id !== expected_id) begin
                    $display("[ERROR] %s: response ID mismatch: got %h expected %h",
                             test_name, rsp_id, expected_id);
                    errors = errors + 1;
                end

                if (rsp_resp !== expected_resp) begin
                    $display("[ERROR] %s: response code mismatch: got %b expected %b",
                             test_name, rsp_resp, expected_resp);
                    errors = errors + 1;
                end

                if (expected_resp == RESP_OKAY &&
                    rsp_rdata !== expected_data) begin
                    $display("[ERROR] %s: read data mismatch: got %h expected %h",
                             test_name, rsp_rdata, expected_data);
                    errors = errors + 1;
                end

                @(posedge clk);
                #1;

                if (!rsp_valid) begin
                    // Response consumed because rsp_ready is normally high.
                end
            end
        end
    endtask

    // ========================================================================
    // Main integration test
    // ========================================================================

    initial begin
        errors = 0;

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

        // ====================================================================
        // TEST 1: RESET / MASTER READY
        // ====================================================================

        if (!cmd_ready) begin
            $display("[ERROR] TEST 1: master cmd_ready not asserted");
            errors = errors + 1;
        end

        // ====================================================================
        // TEST 2: WRITE TO SLAVE 0
        // Global address 0x20 remains 0x20 at S0.
        // ====================================================================

        send_command(
            1'b1,
            4'h1,
            32'h0000_0020,
            32'h1122_3344,
            4'b1111
        );

        wait_response(
            4'h1,
            32'h0000_0000,
            RESP_OKAY,
            "TEST 2 WRITE S0"
        );

        // ====================================================================
        // TEST 3: READ FROM SLAVE 0
        // ====================================================================

        send_command(
            1'b0,
            4'h2,
            32'h0000_0020,
            32'h0000_0000,
            4'b0000
        );

        wait_response(
            4'h2,
            32'h1122_3344,
            RESP_OKAY,
            "TEST 3 READ S0"
        );

        // ====================================================================
        // TEST 4: WRITE TO SLAVE 1
        // Global 0x420 becomes local 0x20 at S1.
        // ====================================================================

        send_command(
            1'b1,
            4'h3,
            32'h0000_0420,
            32'hAABB_CCDD,
            4'b1111
        );

        wait_response(
            4'h3,
            32'h0000_0000,
            RESP_OKAY,
            "TEST 4 WRITE S1"
        );

        // ====================================================================
        // TEST 5: READ FROM SLAVE 1
        // ====================================================================

        send_command(
            1'b0,
            4'h4,
            32'h0000_0420,
            32'h0000_0000,
            4'b0000
        );

        wait_response(
            4'h4,
            32'hAABB_CCDD,
            RESP_OKAY,
            "TEST 5 READ S1"
        );

        // ====================================================================
        // TEST 6: WSTRB THROUGH MASTER -> INTERCONNECT -> SLAVE
        //
        // Existing S0 location 0x24 is initialized fully first.
        // Then only bytes [1:0] are overwritten.
        // Expected final value = AABB_5678.
        // ====================================================================

        send_command(
            1'b1,
            4'h5,
            32'h0000_0024,
            32'h1122_3344,
            4'b1111
        );

        wait_response(
            4'h5,
            32'h0000_0000,
            RESP_OKAY,
            "TEST 6A INITIAL WRITE"
        );

        send_command(
            1'b1,
            4'h6,
            32'h0000_0024,
            32'h0000_5678,
            4'b0011
        );

        wait_response(
            4'h6,
            32'h0000_0000,
            RESP_OKAY,
            "TEST 6B PARTIAL WRITE"
        );

        send_command(
            1'b0,
            4'h7,
            32'h0000_0024,
            32'h0000_0000,
            4'b0000
        );

        wait_response(
            4'h7,
            32'h1122_5678,
            RESP_OKAY,
            "TEST 6C WSTRB READBACK"
        );

        // ====================================================================
        // TEST 7: UNMAPPED WRITE -> DECERR
        // ====================================================================

        send_command(
            1'b1,
            4'h8,
            32'h0000_1000,
            32'hDEAD_BEEF,
            4'b1111
        );

        wait_response(
            4'h8,
            32'h0000_0000,
            RESP_DECERR,
            "TEST 7 UNMAPPED WRITE"
        );

        // ====================================================================
        // TEST 8: UNMAPPED READ -> DECERR
        // ====================================================================

        send_command(
            1'b0,
            4'h9,
            32'h0000_1000,
            32'h0000_0000,
            4'b0000
        );

        wait_response(
            4'h9,
            32'h0000_0000,
            RESP_DECERR,
            "TEST 8 UNMAPPED READ"
        );

        // ====================================================================
        // TEST 9: RESPONSE BACKPRESSURE AT MASTER LOCAL INTERFACE
        //
        // The Master must hold rsp_valid/id/data/resp while rsp_ready=0.
        // ====================================================================

        rsp_ready = 1'b0;

        send_command(
            1'b1,
            4'hA,
            32'h0000_0030,
            32'hCAFEBABE,
            4'b1111
        );

        // Wait for the response to become valid while backpressured.
        rsp_timeout = 0;

        while (!rsp_valid && rsp_timeout < 50) begin
            @(posedge clk);
            #1;
            rsp_timeout = rsp_timeout + 1;
        end

        if (!rsp_valid) begin
            $display("[ERROR] TEST 9: response timeout under backpressure");
            errors = errors + 1;
        end
        else begin
            if (rsp_id !== 4'hA) begin
                $display("[ERROR] TEST 9: initial response ID mismatch: got %h expected %h",
                         rsp_id, 4'hA);
                errors = errors + 1;
            end

            if (rsp_resp !== RESP_OKAY) begin
                $display("[ERROR] TEST 9: initial response code mismatch: got %b expected %b",
                         rsp_resp, RESP_OKAY);
                errors = errors + 1;
            end

            // Once rsp_valid is observed, verify that all response fields
            // remain stable while rsp_ready is held low.
            repeat (3) begin
                @(posedge clk);
                #1;

                if (!rsp_valid) begin
                    $display("[ERROR] TEST 9: rsp_valid dropped under backpressure");
                    errors = errors + 1;
                end

                if (rsp_id !== 4'hA) begin
                    $display("[ERROR] TEST 9: rsp_id changed under backpressure");
                    errors = errors + 1;
                end

                if (rsp_resp !== RESP_OKAY) begin
                    $display("[ERROR] TEST 9: rsp_resp changed under backpressure");
                    errors = errors + 1;
                end
            end
        end

        rsp_ready = 1'b1;

        @(posedge clk);
        #1;

        @(posedge clk);
        #1;

        // ====================================================================
        // TEST 10: SINGLE OUTSTANDING COMMAND / BUSY BEHAVIOR
        // ====================================================================

        send_command(
            1'b0,
            4'hB,
            32'h0000_0030,
            32'h0000_0000,
            4'b0000
        );

        if (cmd_ready) begin
            $display("[ERROR] TEST 10: cmd_ready asserted while command active");
            errors = errors + 1;
        end

        wait_response(
            4'hB,
            32'hCAFEBABE,
            RESP_OKAY,
            "TEST 10 READBACK"
        );

        // ====================================================================
        // RESULT
        // ====================================================================

        if (errors == 0)
            $display("AXI4 MASTER -> INTERCONNECT -> SLAVES: PASS");
        else
            $display("AXI4 MASTER -> INTERCONNECT -> SLAVES: FAIL (%0d errors)",
                     errors);

        $finish;
    end

endmodule
