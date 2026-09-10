module axi4_interconnect #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
) (
    input  logic clk,
    input  logic reset,

    // =========================================================
    // AXI4 master-facing interface
    // =========================================================

    input  logic [ID_WIDTH-1:0]       m_axi_awid,
    input  logic [ADDR_WIDTH-1:0]     m_axi_awaddr,
    input  logic [7:0]                m_axi_awlen,
    input  logic                      m_axi_awvalid,
    output logic                      m_axi_awready,

    input  logic [DATA_WIDTH-1:0]     m_axi_wdata,
    input  logic [DATA_WIDTH/8-1:0]   m_axi_wstrb,
    input  logic                      m_axi_wlast,
    input  logic                      m_axi_wvalid,
    output logic                      m_axi_wready,

    output logic [ID_WIDTH-1:0]       m_axi_bid,
    output logic [1:0]                m_axi_bresp,
    output logic                      m_axi_bvalid,
    input  logic                      m_axi_bready,

    input  logic [ID_WIDTH-1:0]       m_axi_arid,
    input  logic [ADDR_WIDTH-1:0]     m_axi_araddr,
    input  logic [7:0]                m_axi_arlen,
    input  logic                      m_axi_arvalid,
    output logic                      m_axi_arready,

    output logic [ID_WIDTH-1:0]       m_axi_rid,
    output logic [DATA_WIDTH-1:0]     m_axi_rdata,
    output logic [1:0]                m_axi_rresp,
    output logic                      m_axi_rlast,
    output logic                      m_axi_rvalid,
    input  logic                      m_axi_rready,

    // =========================================================
    // AXI4 slave 0
    // =========================================================

    output logic [ID_WIDTH-1:0]       s0_axi_awid,
    output logic [ADDR_WIDTH-1:0]     s0_axi_awaddr,
    output logic [7:0]                s0_axi_awlen,
    output logic                      s0_axi_awvalid,
    input  logic                      s0_axi_awready,

    output logic [DATA_WIDTH-1:0]     s0_axi_wdata,
    output logic [DATA_WIDTH/8-1:0]   s0_axi_wstrb,
    output logic                      s0_axi_wlast,
    output logic                      s0_axi_wvalid,
    input  logic                      s0_axi_wready,

    input  logic [ID_WIDTH-1:0]       s0_axi_bid,
    input  logic [1:0]                s0_axi_bresp,
    input  logic                      s0_axi_bvalid,
    output logic                      s0_axi_bready,

    output logic [ID_WIDTH-1:0]       s0_axi_arid,
    output logic [ADDR_WIDTH-1:0]     s0_axi_araddr,
    output logic [7:0]                s0_axi_arlen,
    output logic                      s0_axi_arvalid,
    input  logic                      s0_axi_arready,

    input  logic [ID_WIDTH-1:0]       s0_axi_rid,
    input logic [DATA_WIDTH-1:0]     s0_axi_rdata,
    input logic [1:0]                s0_axi_rresp,
    input logic                      s0_axi_rlast,
    input logic                      s0_axi_rvalid,
    output logic                      s0_axi_rready,

    // =========================================================
    // AXI4 slave 1
    // =========================================================

    output logic [ID_WIDTH-1:0]       s1_axi_awid,
    output logic [ADDR_WIDTH-1:0]     s1_axi_awaddr,
    output logic [7:0]                s1_axi_awlen,
    output logic                      s1_axi_awvalid,
    input  logic                      s1_axi_awready,

    output logic [DATA_WIDTH-1:0]     s1_axi_wdata,
    output logic [DATA_WIDTH/8-1:0]   s1_axi_wstrb,
    output logic                      s1_axi_wlast,
    output logic                      s1_axi_wvalid,
    input  logic                      s1_axi_wready,

    input  logic [ID_WIDTH-1:0]       s1_axi_bid,
    input  logic [1:0]                s1_axi_bresp,
    input  logic                      s1_axi_bvalid,
    output logic                      s1_axi_bready,

    output logic [ID_WIDTH-1:0]       s1_axi_arid,
    output logic [ADDR_WIDTH-1:0]     s1_axi_araddr,
    output logic [7:0]                s1_axi_arlen,
    output logic                      s1_axi_arvalid,
    input  logic                      s1_axi_arready,

    input  logic [ID_WIDTH-1:0]       s1_axi_rid,
    input  logic [DATA_WIDTH-1:0]     s1_axi_rdata,
    input  logic [1:0]                s1_axi_rresp,
    input  logic                      s1_axi_rlast,
    input  logic                      s1_axi_rvalid,
    output logic                      s1_axi_rready
);

    localparam logic [1:0] RESP_OKAY  = 2'b00;
    localparam logic [1:0] RESP_DECERR = 2'b11;

    localparam logic [ADDR_WIDTH-1:0] S0_BASE = 32'h0000_0000;
    localparam logic [ADDR_WIDTH-1:0] S0_END  = 32'h0000_03FF;

    localparam logic [ADDR_WIDTH-1:0] S1_BASE = 32'h0000_0400;
    localparam logic [ADDR_WIDTH-1:0] S1_END  = 32'h0000_07FF;

    logic aw_pending;
    logic aw_target;
    logic aw_unmapped;

    logic ar_pending;
    logic ar_target;
    logic ar_unmapped;

    logic b_unmapped_valid;
    logic [ID_WIDTH-1:0] b_unmapped_id;

    logic r_unmapped_valid;
    logic [ID_WIDTH-1:0] r_unmapped_id;
    logic [DATA_WIDTH-1:0] r_unmapped_data;

    logic aw_hit_s0;
    logic aw_hit_s1;
    logic ar_hit_s0;
    logic ar_hit_s1;

    assign aw_hit_s0 = (m_axi_awaddr >= S0_BASE) &&
                       (m_axi_awaddr <= S0_END);

    assign aw_hit_s1 = (m_axi_awaddr >= S1_BASE) &&
                       (m_axi_awaddr <= S1_END);

    assign ar_hit_s0 = (m_axi_araddr >= S0_BASE) &&
                       (m_axi_araddr <= S0_END);

    assign ar_hit_s1 = (m_axi_araddr >= S1_BASE) &&
                       (m_axi_araddr <= S1_END);

    // =========================================================
    // Write address channel
    // =========================================================

    always_comb begin
        s0_axi_awid    = m_axi_awid;
        s0_axi_awaddr  = m_axi_awaddr;
        s0_axi_awlen   = m_axi_awlen;
        s0_axi_awvalid = 1'b0;

        s1_axi_awid    = m_axi_awid;
        s1_axi_awaddr  = m_axi_awaddr - S1_BASE;
        s1_axi_awlen   = m_axi_awlen;
        s1_axi_awvalid = 1'b0;

        m_axi_awready = 1'b0;

        if (!aw_pending && !b_unmapped_valid) begin
            if (aw_hit_s0) begin
                s0_axi_awvalid = m_axi_awvalid;
                m_axi_awready  = s0_axi_awready;
            end
            else if (aw_hit_s1) begin
                s1_axi_awvalid = m_axi_awvalid;
                m_axi_awready  = s1_axi_awready;
            end
            else begin
                m_axi_awready = 1'b1;
            end
        end
    end

    // =========================================================
    // Write data channel
    // =========================================================

    always_comb begin
        s0_axi_wdata  = m_axi_wdata;
        s0_axi_wstrb  = m_axi_wstrb;
        s0_axi_wlast  = m_axi_wlast;
        s0_axi_wvalid = 1'b0;

        s1_axi_wdata  = m_axi_wdata;
        s1_axi_wstrb  = m_axi_wstrb;
        s1_axi_wlast  = m_axi_wlast;
        s1_axi_wvalid = 1'b0;

        m_axi_wready = 1'b0;

        if (aw_pending && !b_unmapped_valid) begin
            if (!aw_unmapped && !aw_target) begin
                s0_axi_wvalid = m_axi_wvalid;
                m_axi_wready  = s0_axi_wready;
            end
            else if (!aw_unmapped && aw_target) begin
                s1_axi_wvalid = m_axi_wvalid;
                m_axi_wready  = s1_axi_wready;
            end
            else begin
                m_axi_wready = 1'b1;
            end
        end
    end

    // =========================================================
    // Write response channel
    // =========================================================

    always_comb begin
        s0_axi_bready = 1'b0;
        s1_axi_bready = 1'b0;

        m_axi_bid    = '0;
        m_axi_bresp  = RESP_DECERR;
        m_axi_bvalid = 1'b0;

        if (b_unmapped_valid) begin
            m_axi_bid    = b_unmapped_id;
            m_axi_bresp  = RESP_DECERR;
            m_axi_bvalid = 1'b1;
        end
        else if (aw_pending && !aw_unmapped && !aw_target) begin
            m_axi_bid    = s0_axi_bid;
            m_axi_bresp  = s0_axi_bresp;
            m_axi_bvalid = s0_axi_bvalid;
            s0_axi_bready = m_axi_bready;
        end
        else if (aw_pending && !aw_unmapped && aw_target) begin
            m_axi_bid    = s1_axi_bid;
            m_axi_bresp  = s1_axi_bresp;
            m_axi_bvalid = s1_axi_bvalid;
            s1_axi_bready = m_axi_bready;
        end
    end

    // =========================================================
    // Read address channel
    // =========================================================

    always_comb begin
        s0_axi_arid    = m_axi_arid;
        s0_axi_araddr  = m_axi_araddr;
        s0_axi_arlen   = m_axi_arlen;
        s0_axi_arvalid = 1'b0;

        s1_axi_arid    = m_axi_arid;
        s1_axi_araddr  = m_axi_araddr - S1_BASE;
        s1_axi_arlen   = m_axi_arlen;
        s1_axi_arvalid = 1'b0;

        m_axi_arready = 1'b0;

        if (!ar_pending && !r_unmapped_valid) begin
            if (ar_hit_s0) begin
                s0_axi_arvalid = m_axi_arvalid;
                m_axi_arready  = s0_axi_arready;
            end
            else if (ar_hit_s1) begin
                s1_axi_arvalid = m_axi_arvalid;
                m_axi_arready  = s1_axi_arready;
            end
            else begin
                m_axi_arready = 1'b1;
            end
        end
    end

    // =========================================================
    // Read response channel
    // =========================================================

    always_comb begin
        s0_axi_rready = 1'b0;
        s1_axi_rready = 1'b0;

        m_axi_rid    = '0;
        m_axi_rdata  = r_unmapped_data;
        m_axi_rresp  = RESP_DECERR;
        m_axi_rlast  = 1'b1;
        m_axi_rvalid = 1'b0;

        if (r_unmapped_valid) begin
            m_axi_rid    = r_unmapped_id;
            m_axi_rresp  = RESP_DECERR;
            m_axi_rvalid = 1'b1;
        end
        else if (ar_pending && !ar_unmapped && !ar_target) begin
            m_axi_rid    = s0_axi_rid;
            m_axi_rdata  = s0_axi_rdata;
            m_axi_rresp  = s0_axi_rresp;
            m_axi_rlast  = s0_axi_rlast;
            m_axi_rvalid = s0_axi_rvalid;
            s0_axi_rready = m_axi_rready;
        end
        else if (ar_pending && !ar_unmapped && ar_target) begin
            m_axi_rid    = s1_axi_rid;
            m_axi_rdata  = s1_axi_rdata;
            m_axi_rresp  = s1_axi_rresp;
            m_axi_rlast  = s1_axi_rlast;
            m_axi_rvalid = s1_axi_rvalid;
            s1_axi_rready = m_axi_rready;
        end
    end

    // =========================================================
    // Request tracking
    // =========================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            aw_pending       <= 1'b0;
            aw_target        <= 1'b0;
            aw_unmapped      <= 1'b0;
            b_unmapped_valid <= 1'b0;
            b_unmapped_id    <= '0;

            ar_pending       <= 1'b0;
            ar_target        <= 1'b0;
            ar_unmapped      <= 1'b0;
            r_unmapped_valid <= 1'b0;
            r_unmapped_id    <= '0;
            r_unmapped_data  <= '0;
        end
        else begin
            if (m_axi_awvalid && m_axi_awready) begin
                aw_pending  <= 1'b1;
                aw_target   <= aw_hit_s1;
                aw_unmapped <= !(aw_hit_s0 || aw_hit_s1);

                if (!(aw_hit_s0 || aw_hit_s1)) begin
                    b_unmapped_valid <= 1'b0;
                    b_unmapped_id    <= m_axi_awid;
                end
            end

            if (m_axi_wvalid && m_axi_wready) begin
                if (aw_unmapped) begin
                    b_unmapped_valid <= 1'b1;
                end
            end

            if (m_axi_bvalid && m_axi_bready) begin
                aw_pending       <= 1'b0;
                b_unmapped_valid <= 1'b0;
            end

            if (m_axi_arvalid && m_axi_arready) begin
                ar_pending  <= 1'b1;
                ar_target   <= ar_hit_s1;
                ar_unmapped <= !(ar_hit_s0 || ar_hit_s1);

                if (!(ar_hit_s0 || ar_hit_s1)) begin
                    r_unmapped_valid <= 1'b1;
                    r_unmapped_id    <= m_axi_arid;
                    r_unmapped_data  <= '0;
                end
            end

            if (m_axi_rvalid && m_axi_rready) begin
                ar_pending       <= 1'b0;
                r_unmapped_valid <= 1'b0;
            end
        end
    end

endmodule
