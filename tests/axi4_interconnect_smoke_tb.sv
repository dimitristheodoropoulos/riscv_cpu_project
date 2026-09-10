`timescale 1ns/1ps

module axi4_interconnect_smoke_tb;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam ID_WIDTH   = 4;

    localparam logic [1:0] RESP_OKAY   = 2'b00;
    localparam logic [1:0] RESP_DECERR = 2'b11;

    localparam logic [1:0] TARGET_NONE = 2'b00;
    localparam logic [1:0] TARGET_S0   = 2'b01;
    localparam logic [1:0] TARGET_S1   = 2'b10;

    logic clk;
    logic reset;

    // =========================================================
    // Master-facing signals
    // =========================================================

    logic [ID_WIDTH-1:0]     m_axi_awid;
    logic [ADDR_WIDTH-1:0]   m_axi_awaddr;
    logic [7:0]              m_axi_awlen;
    logic                    m_axi_awvalid;
    logic                    m_axi_awready;

    logic [DATA_WIDTH-1:0]   m_axi_wdata;
    logic [DATA_WIDTH/8-1:0] m_axi_wstrb;
    logic                    m_axi_wlast;
    logic                    m_axi_wvalid;
    logic                    m_axi_wready;

    logic [ID_WIDTH-1:0]     m_axi_bid;
    logic [1:0]              m_axi_bresp;
    logic                    m_axi_bvalid;
    logic                    m_axi_bready;

    logic [ID_WIDTH-1:0]     m_axi_arid;
    logic [ADDR_WIDTH-1:0]   m_axi_araddr;
    logic [7:0]              m_axi_arlen;
    logic                    m_axi_arvalid;
    logic                    m_axi_arready;

    logic [ID_WIDTH-1:0]     m_axi_rid;
    logic [DATA_WIDTH-1:0]   m_axi_rdata;
    logic [1:0]              m_axi_rresp;
    logic                    m_axi_rlast;
    logic                    m_axi_rvalid;
    logic                    m_axi_rready;

    // =========================================================
    // Slave 0 signals
    // =========================================================

    logic [ID_WIDTH-1:0]     s0_axi_awid;
    logic [ADDR_WIDTH-1:0]   s0_axi_awaddr;
    logic [7:0]              s0_axi_awlen;
    logic                    s0_axi_awvalid;
    logic                    s0_axi_awready;

    logic [DATA_WIDTH-1:0]   s0_axi_wdata;
    logic [DATA_WIDTH/8-1:0] s0_axi_wstrb;
    logic                    s0_axi_wlast;
    logic                    s0_axi_wvalid;
    logic                    s0_axi_wready;

    logic [ID_WIDTH-1:0]     s0_axi_bid;
    logic [1:0]              s0_axi_bresp;
    logic                    s0_axi_bvalid;
    logic                    s0_axi_bready;

    logic [ID_WIDTH-1:0]     s0_axi_arid;
    logic [ADDR_WIDTH-1:0]   s0_axi_araddr;
    logic [7:0]              s0_axi_arlen;
    logic                    s0_axi_arvalid;
    logic                    s0_axi_arready;

    logic [ID_WIDTH-1:0]     s0_axi_rid;
    logic [DATA_WIDTH-1:0]   s0_axi_rdata;
    logic [1:0]              s0_axi_rresp;
    logic                    s0_axi_rlast;
    logic                    s0_axi_rvalid;
    logic                    s0_axi_rready;

    // =========================================================
    // Slave 1 signals
    // =========================================================

    logic [ID_WIDTH-1:0]     s1_axi_awid;
    logic [ADDR_WIDTH-1:0]   s1_axi_awaddr;
    logic [7:0]              s1_axi_awlen;
    logic                    s1_axi_awvalid;
    logic                    s1_axi_awready;

    logic [DATA_WIDTH-1:0]   s1_axi_wdata;
    logic [DATA_WIDTH/8-1:0] s1_axi_wstrb;
    logic                    s1_axi_wlast;
    logic                    s1_axi_wvalid;
    logic                    s1_axi_wready;

    logic [ID_WIDTH-1:0]     s1_axi_bid;
    logic [1:0]              s1_axi_bresp;
    logic                    s1_axi_bvalid;
    logic                    s1_axi_bready;

    logic [ID_WIDTH-1:0]     s1_axi_arid;
    logic [ADDR_WIDTH-1:0]   s1_axi_araddr;
    logic [7:0]              s1_axi_arlen;
    logic                    s1_axi_arvalid;
    logic                    s1_axi_arready;

    logic [ID_WIDTH-1:0]     s1_axi_rid;
    logic [DATA_WIDTH-1:0]   s1_axi_rdata;
    logic [1:0]              s1_axi_rresp;
    logic                    s1_axi_rlast;
    logic                    s1_axi_rvalid;
    logic                    s1_axi_rready;

    integer errors;

    // =========================================================
    // Clock
    // =========================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // =========================================================
    // DUT: AXI4 Interconnect
    // =========================================================

    axi4_interconnect #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),

        .m_axi_awid(m_axi_awid),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awlen(m_axi_awlen),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),

        .m_axi_wdata(m_axi_wdata),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),

        .m_axi_bid(m_axi_bid),
        .m_axi_bresp(m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready),

        .m_axi_arid(m_axi_arid),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),

        .m_axi_rid(m_axi_rid),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready),

        .s0_axi_awid(s0_axi_awid),
        .s0_axi_awaddr(s0_axi_awaddr),
        .s0_axi_awlen(s0_axi_awlen),
        .s0_axi_awvalid(s0_axi_awvalid),
        .s0_axi_awready(s0_axi_awready),

        .s0_axi_wdata(s0_axi_wdata),
        .s0_axi_wstrb(s0_axi_wstrb),
        .s0_axi_wlast(s0_axi_wlast),
        .s0_axi_wvalid(s0_axi_wvalid),
        .s0_axi_wready(s0_axi_wready),

        .s0_axi_bid(s0_axi_bid),
        .s0_axi_bresp(s0_axi_bresp),
        .s0_axi_bvalid(s0_axi_bvalid),
        .s0_axi_bready(s0_axi_bready),

        .s0_axi_arid(s0_axi_arid),
        .s0_axi_araddr(s0_axi_araddr),
        .s0_axi_arlen(s0_axi_arlen),
        .s0_axi_arvalid(s0_axi_arvalid),
        .s0_axi_arready(s0_axi_arready),

        .s0_axi_rid(s0_axi_rid),
        .s0_axi_rdata(s0_axi_rdata),
        .s0_axi_rresp(s0_axi_rresp),
        .s0_axi_rlast(s0_axi_rlast),
        .s0_axi_rvalid(s0_axi_rvalid),
        .s0_axi_rready(s0_axi_rready),

        .s1_axi_awid(s1_axi_awid),
        .s1_axi_awaddr(s1_axi_awaddr),
        .s1_axi_awlen(s1_axi_awlen),
        .s1_axi_awvalid(s1_axi_awvalid),
        .s1_axi_awready(s1_axi_awready),

        .s1_axi_wdata(s1_axi_wdata),
        .s1_axi_wstrb(s1_axi_wstrb),
        .s1_axi_wlast(s1_axi_wlast),
        .s1_axi_wvalid(s1_axi_wvalid),
        .s1_axi_wready(s1_axi_wready),

        .s1_axi_bid(s1_axi_bid),
        .s1_axi_bresp(s1_axi_bresp),
        .s1_axi_bvalid(s1_axi_bvalid),
        .s1_axi_bready(s1_axi_bready),

        .s1_axi_arid(s1_axi_arid),
        .s1_axi_araddr(s1_axi_araddr),
        .s1_axi_arlen(s1_axi_arlen),
        .s1_axi_arvalid(s1_axi_arvalid),
        .s1_axi_arready(s1_axi_arready),

        .s1_axi_rid(s1_axi_rid),
        .s1_axi_rdata(s1_axi_rdata),
        .s1_axi_rresp(s1_axi_rresp),
        .s1_axi_rlast(s1_axi_rlast),
        .s1_axi_rvalid(s1_axi_rvalid),
        .s1_axi_rready(s1_axi_rready)
    );

    // =========================================================
    // Real AXI4 slave 0
    // =========================================================

    axi4_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) slave0 (
        .clk(clk),
        .reset(reset),

        .s_axi_awid(s0_axi_awid),
        .s_axi_awaddr(s0_axi_awaddr),
        .s_axi_awlen(s0_axi_awlen),
        .s_axi_awvalid(s0_axi_awvalid),
        .s_axi_awready(s0_axi_awready),

        .s_axi_wdata(s0_axi_wdata),
        .s_axi_wstrb(s0_axi_wstrb),
        .s_axi_wlast(s0_axi_wlast),
        .s_axi_wvalid(s0_axi_wvalid),
        .s_axi_wready(s0_axi_wready),

        .s_axi_bid(s0_axi_bid),
        .s_axi_bresp(s0_axi_bresp),
        .s_axi_bvalid(s0_axi_bvalid),
        .s_axi_bready(s0_axi_bready),

        .s_axi_arid(s0_axi_arid),
        .s_axi_araddr(s0_axi_araddr),
        .s_axi_arlen(s0_axi_arlen),
        .s_axi_arvalid(s0_axi_arvalid),
        .s_axi_arready(s0_axi_arready),

        .s_axi_rid(s0_axi_rid),
        .s_axi_rdata(s0_axi_rdata),
        .s_axi_rresp(s0_axi_rresp),
        .s_axi_rlast(s0_axi_rlast),
        .s_axi_rvalid(s0_axi_rvalid),
        .s_axi_rready(s0_axi_rready)
    );

    // =========================================================
    // Real AXI4 slave 1
    // =========================================================

    axi4_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) slave1 (
        .clk(clk),
        .reset(reset),

        .s_axi_awid(s1_axi_awid),
        .s_axi_awaddr(s1_axi_awaddr),
        .s_axi_awlen(s1_axi_awlen),
        .s_axi_awvalid(s1_axi_awvalid),
        .s_axi_awready(s1_axi_awready),

        .s_axi_wdata(s1_axi_wdata),
        .s_axi_wstrb(s1_axi_wstrb),
        .s_axi_wlast(s1_axi_wlast),
        .s_axi_wvalid(s1_axi_wvalid),
        .s_axi_wready(s1_axi_wready),

        .s_axi_bid(s1_axi_bid),
        .s_axi_bresp(s1_axi_bresp),
        .s_axi_bvalid(s1_axi_bvalid),
        .s_axi_bready(s1_axi_bready),

        .s_axi_arid(s1_axi_arid),
        .s_axi_araddr(s1_axi_araddr),
        .s_axi_arlen(s1_axi_arlen),
        .s_axi_arvalid(s1_axi_arvalid),
        .s_axi_arready(s1_axi_arready),

        .s_axi_rid(s1_axi_rid),
        .s_axi_rdata(s1_axi_rdata),
        .s_axi_rresp(s1_axi_rresp),
        .s_axi_rlast(s1_axi_rlast),
        .s_axi_rvalid(s1_axi_rvalid),
        .s_axi_rready(s1_axi_rready)
    );

    // =========================================================
    // Helpers
    // =========================================================

    task automatic reset_dut;
        begin
            reset = 1'b1;

            m_axi_awvalid = 1'b0;
            m_axi_wvalid  = 1'b0;
            m_axi_bready  = 1'b0;

            m_axi_arvalid = 1'b0;
            m_axi_rready  = 1'b0;

            m_axi_awid   = '0;
            m_axi_awaddr = '0;
            m_axi_awlen  = '0;

            m_axi_wdata = '0;
            m_axi_wstrb = '0;
            m_axi_wlast = 1'b0;

            m_axi_arid   = '0;
            m_axi_araddr = '0;
            m_axi_arlen  = '0;

            repeat (3) @(posedge clk);
            reset = 1'b0;
            repeat (2) @(posedge clk);
        end
    endtask

    task automatic axi_write(
        input logic [ID_WIDTH-1:0] id,
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input logic [DATA_WIDTH/8-1:0] strb,
        input logic expected_error,
        input logic [1:0] expected_target,
        input logic [ADDR_WIDTH-1:0] expected_local_addr
    );
        begin
            // -----------------------------------------------------
            // AW channel: drive away from sampling edge
            // -----------------------------------------------------
            @(negedge clk);

            m_axi_awid    = id;
            m_axi_awaddr  = addr;
            m_axi_awlen   = 8'd0;
            m_axi_awvalid = 1'b1;

            // -----------------------------------------------------
            // Verify address decode and local-address translation
            // before the AW handshake changes the interconnect state.
            // -----------------------------------------------------
            #1;

            case (expected_target)
                TARGET_S0: begin
                    if (s0_axi_awvalid !== 1'b1 ||
                        s1_axi_awvalid !== 1'b0 ||
                        s0_axi_awaddr !== expected_local_addr) begin
                        $display("[ERROR] WRITE S0 routing mismatch: addr=%08h local=%08h s0_valid=%0b s0_addr=%08h s1_valid=%0b",
                                 addr, expected_local_addr,
                                 s0_axi_awvalid, s0_axi_awaddr, s1_axi_awvalid);
                        errors = errors + 1;
                    end
                end
                TARGET_S1: begin
                    if (s0_axi_awvalid !== 1'b0 ||
                        s1_axi_awvalid !== 1'b1 ||
                        s1_axi_awaddr !== expected_local_addr) begin
                        $display("[ERROR] WRITE S1 routing mismatch: addr=%08h local=%08h s0_valid=%0b s1_valid=%0b s1_addr=%08h",
                                 addr, expected_local_addr,
                                 s0_axi_awvalid, s1_axi_awvalid, s1_axi_awaddr);
                        errors = errors + 1;
                    end
                end
                TARGET_NONE: begin
                    if (s0_axi_awvalid !== 1'b0 ||
                        s1_axi_awvalid !== 1'b0) begin
                        $display("[ERROR] WRITE unmapped address was routed: addr=%08h s0_valid=%0b s1_valid=%0b",
                                 addr, s0_axi_awvalid, s1_axi_awvalid);
                        errors = errors + 1;
                    end
                end
                default: begin
                    $display("[ERROR] WRITE invalid expected target: %0b", expected_target);
                    errors = errors + 1;
                end
            endcase

            // -----------------------------------------------------
            // Complete the actual AW handshake.
            // -----------------------------------------------------
            while (!m_axi_awready)
                @(negedge clk);

            @(posedge clk);
              #1;

            m_axi_awvalid = 1'b0;

            // -----------------------------------------------------
            // W channel
            // -----------------------------------------------------
            @(negedge clk);

            m_axi_wdata  = data;
            m_axi_wstrb  = strb;
            m_axi_wlast  = 1'b1;
            m_axi_wvalid = 1'b1;

            while (!m_axi_wready)
                @(negedge clk);

            @(posedge clk);
              #1;
            m_axi_wvalid = 1'b0;
            m_axi_wlast  = 1'b0;

            // -----------------------------------------------------
            // B channel
            // -----------------------------------------------------
            @(negedge clk);
            m_axi_bready = 1'b1;

            while (!m_axi_bvalid)
                @(negedge clk);

            if (m_axi_bid !== id) begin
                $display("[ERROR] WRITE ID mismatch: expected=%0h actual=%0h",
                         id, m_axi_bid);
                errors = errors + 1;
            end

            if (expected_error) begin
                if (m_axi_bresp !== RESP_DECERR) begin
                    $display("[ERROR] WRITE DECERR expected, got=%0b",
                             m_axi_bresp);
                    errors = errors + 1;
                end
            end
            else begin
                if (m_axi_bresp !== RESP_OKAY) begin
                    $display("[ERROR] WRITE OKAY expected, got=%0b",
                             m_axi_bresp);
                    errors = errors + 1;
                end
            end

            // Complete B handshake on the same sampled clock edge.
            @(negedge clk);
            m_axi_bready = 1'b0;
        end
    endtask


    task automatic axi_read(
        input logic [ID_WIDTH-1:0] id,
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] expected_data,
        input logic expected_error,
        input logic [1:0] expected_target,
        input logic [ADDR_WIDTH-1:0] expected_local_addr
    );
        begin
            // -----------------------------------------------------
            // AR channel: drive away from sampling edge
            // -----------------------------------------------------
            @(negedge clk);

            m_axi_arid    = id;
            m_axi_araddr  = addr;
            m_axi_arlen   = 8'd0;
            m_axi_arvalid = 1'b1;

            // -----------------------------------------------------
            // Verify address decode and local-address translation
            // before the AR handshake changes the interconnect state.
            // -----------------------------------------------------
            #1;

            case (expected_target)
                TARGET_S0: begin
                    if (s0_axi_arvalid !== 1'b1 ||
                        s1_axi_arvalid !== 1'b0 ||
                        s0_axi_araddr !== expected_local_addr) begin
                        $display("[ERROR] READ S0 routing mismatch: addr=%08h local=%08h s0_valid=%0b s0_addr=%08h s1_valid=%0b",
                                 addr, expected_local_addr,
                                 s0_axi_arvalid, s0_axi_araddr, s1_axi_arvalid);
                        errors = errors + 1;
                    end
                end
                TARGET_S1: begin
                    if (s0_axi_arvalid !== 1'b0 ||
                        s1_axi_arvalid !== 1'b1 ||
                        s1_axi_araddr !== expected_local_addr) begin
                        $display("[ERROR] READ S1 routing mismatch: addr=%08h local=%08h s0_valid=%0b s1_valid=%0b s1_addr=%08h",
                                 addr, expected_local_addr,
                                 s0_axi_arvalid, s1_axi_arvalid, s1_axi_araddr);
                        errors = errors + 1;
                    end
                end
                TARGET_NONE: begin
                    if (s0_axi_arvalid !== 1'b0 ||
                        s1_axi_arvalid !== 1'b0) begin
                        $display("[ERROR] READ unmapped address was routed: addr=%08h s0_valid=%0b s1_valid=%0b",
                                 addr, s0_axi_arvalid, s1_axi_arvalid);
                        errors = errors + 1;
                    end
                end
                default: begin
                    $display("[ERROR] READ invalid expected target: %0b", expected_target);
                    errors = errors + 1;
                end
            endcase

            // -----------------------------------------------------
            // Complete the actual AR handshake.
            // -----------------------------------------------------
            while (!m_axi_arready)
                @(negedge clk);

            @(posedge clk);
              #1;

            m_axi_arvalid = 1'b0;

            // -----------------------------------------------------
            // R channel
            // -----------------------------------------------------
            @(negedge clk);
            m_axi_rready = 1'b1;

            while (!m_axi_rvalid)
                @(negedge clk);

            if (m_axi_rid !== id) begin
                $display("[ERROR] READ ID mismatch: expected=%0h actual=%0h",
                         id, m_axi_rid);
                errors = errors + 1;
            end

            if (expected_error) begin
                if (m_axi_rresp !== RESP_DECERR) begin
                    $display("[ERROR] READ DECERR expected, got=%0b",
                             m_axi_rresp);
                    errors = errors + 1;
                end
            end
            else begin
                if (m_axi_rresp !== RESP_OKAY) begin
                    $display("[ERROR] READ OKAY expected, got=%0b",
                             m_axi_rresp);
                    errors = errors + 1;
                end

                if (m_axi_rdata !== expected_data) begin
                    $display("[ERROR] READ DATA mismatch: expected=%08h actual=%08h",
                             expected_data, m_axi_rdata);
                    errors = errors + 1;
                end
            end

            if (m_axi_rlast !== 1'b1) begin
                $display("[ERROR] READ RLAST not asserted");
                errors = errors + 1;
            end

            // Complete R handshake on the sampled clock edge.
            @(negedge clk);
            m_axi_rready = 1'b0;
        end
    endtask


    // =========================================================
    // Test sequence
    // =========================================================

    initial begin
        errors = 0;

        $display("");
        $display("============================================================");
        $display("=== AXI4 INTERCONNECT INTEGRATION SMOKE ===");
        $display("============================================================");

        reset_dut();

        // -----------------------------------------------------
        // 1. Slave 0 write/read
        // -----------------------------------------------------

        $display("[TEST] S0 write/read");

        axi_write(
            4'h3,
            32'h0000_0020,
            32'hA5A5_1234,
            4'b1111,
            1'b0,
            TARGET_S0,
            32'h0000_0020
        );

        axi_read(
            4'h4,
            32'h0000_0020,
            32'hA5A5_1234,
            1'b0,
            TARGET_S0,
            32'h0000_0020
        );

        // -----------------------------------------------------
        // 2. Slave 1 write/read
        // -----------------------------------------------------

        $display("[TEST] S1 write/read");

        axi_write(
            4'h7,
            32'h0000_0420,
            32'h5A5A_5678,
            4'b1111,
            1'b0,
            TARGET_S1,
            32'h0000_0020
        );

        axi_read(
            4'h8,
            32'h0000_0420,
            32'h5A5A_5678,
            1'b0,
            TARGET_S1,
            32'h0000_0020
        );

        // -----------------------------------------------------
        // 3. Target isolation
        // -----------------------------------------------------

        $display("[TEST] Target isolation");

        axi_read(
            4'h9,
            32'h0000_0020,
            32'hA5A5_1234,
            1'b0,
            TARGET_S0,
            32'h0000_0020
        );

        axi_read(
            4'hA,
            32'h0000_0420,
            32'h5A5A_5678,
            1'b0,
            TARGET_S1,
            32'h0000_0020
        );

        // -----------------------------------------------------
        // 4. Unmapped write
        // -----------------------------------------------------

        $display("[TEST] Unmapped write -> DECERR");

        axi_write(
            4'hB,
            32'h0000_0800,
            32'hDEAD_BEEF,
            4'b1111,
            1'b1,
            TARGET_NONE,
            32'h0000_0000
        );

        // -----------------------------------------------------
        // 5. Unmapped read
        // -----------------------------------------------------

        $display("[TEST] Unmapped read -> DECERR");

        axi_read(
            4'hC,
            32'h0000_0800,
            32'h0000_0000,
            1'b1,
            TARGET_NONE,
            32'h0000_0000
        );

        // -----------------------------------------------------
        // 6. Partial write to Slave 0
        // -----------------------------------------------------

        $display("[TEST] Partial write / WSTRB routing");

        axi_write(
            4'hD,
            32'h0000_0024,
            32'h1122_3344,
            4'b0011,
            1'b0,
            TARGET_S0,
            32'h0000_0024
        );

        // -----------------------------------------------------
        // 7. Address-map boundary coverage
        // -----------------------------------------------------

        $display("[TEST] Address-map boundaries");

        // S0 lower boundary: 0x0000_0000 -> S0 local 0x0000_0000
        axi_write(
            4'h1,
            32'h0000_0000,
            32'h1111_0000,
            4'b1111,
            1'b0,
            TARGET_S0,
            32'h0000_0000
        );

        axi_read(
            4'h2,
            32'h0000_0000,
            32'h1111_0000,
            1'b0,
            TARGET_S0,
            32'h0000_0000
        );

        // S0 upper boundary: 0x0000_03FF -> S0 local 0x0000_03FF
        axi_write(
            4'h5,
            32'h0000_03FF,
            32'h2222_0000,
            4'b1111,
            1'b0,
            TARGET_S0,
            32'h0000_03FF
        );

        axi_read(
            4'h6,
            32'h0000_03FF,
            32'h2222_0000,
            1'b0,
            TARGET_S0,
            32'h0000_03FF
        );

        // S1 lower boundary: 0x0000_0400 -> S1 local 0x0000_0000
        axi_write(
            4'hE,
            32'h0000_0400,
            32'h3333_0000,
            4'b1111,
            1'b0,
            TARGET_S1,
            32'h0000_0000
        );

        axi_read(
            4'hF,
            32'h0000_0400,
            32'h3333_0000,
            1'b0,
            TARGET_S1,
            32'h0000_0000
        );

        // S1 upper boundary: 0x0000_07FF -> S1 local 0x0000_03FF
        axi_write(
            4'h0,
            32'h0000_07FF,
            32'h4444_0000,
            4'b1111,
            1'b0,
            TARGET_S1,
            32'h0000_03FF
        );

        axi_read(
            4'h0,
            32'h0000_07FF,
            32'h4444_0000,
            1'b0,
            TARGET_S1,
            32'h0000_03FF
        );

        // -----------------------------------------------------
        // Final result
        // -----------------------------------------------------

        repeat (2) @(posedge clk);

        $display("");
        $display("============================================================");

        if (errors == 0) begin
            $display("AXI4 INTERCONNECT SMOKE: PASS");
        end
        else begin
            $display("AXI4 INTERCONNECT SMOKE: FAIL (%0d errors)", errors);
        end

        $display("============================================================");
        $display("");

        $finish;
    end

endmodule
