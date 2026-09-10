module axi4_interconnect_sva #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
) (
    input logic clk,
    input logic reset,

    input logic [ID_WIDTH-1:0]   m_axi_awid,
    input logic [ADDR_WIDTH-1:0] m_axi_awaddr,
    input logic [7:0]            m_axi_awlen,
    input logic                  m_axi_awvalid,
    input logic                  m_axi_awready,

    input logic [DATA_WIDTH-1:0] m_axi_wdata,
    input logic [DATA_WIDTH/8-1:0] m_axi_wstrb,
    input logic                  m_axi_wlast,
    input logic                  m_axi_wvalid,
    input logic                  m_axi_wready,

    input logic [ID_WIDTH-1:0]   m_axi_arid,
    input logic [ADDR_WIDTH-1:0] m_axi_araddr,
    input logic [7:0]            m_axi_arlen,
    input logic                  m_axi_arvalid,
    input logic                  m_axi_arready,

    input logic                  m_axi_bvalid,
    input logic                  m_axi_bready,
    input logic [ID_WIDTH-1:0]   m_axi_bid,
    input logic [1:0]            m_axi_bresp,

    input logic                  m_axi_rvalid,
    input logic                  m_axi_rready,
    input logic [ID_WIDTH-1:0]   m_axi_rid,
    input logic [DATA_WIDTH-1:0] m_axi_rdata,
    input logic [1:0]            m_axi_rresp,
    input logic                  m_axi_rlast,

    input logic                  s0_axi_awvalid,
    input logic                  s1_axi_awvalid,
    input logic                  s0_axi_arvalid,
    input logic                  s1_axi_arvalid
);

    // ---------------------------------------------------------
    // Single-beat contract
    // ---------------------------------------------------------

    property p_aw_single_beat;
        @(posedge clk) disable iff (reset)
        (m_axi_awvalid && m_axi_awready) |-> (m_axi_awlen == 8'd0);
    endproperty

    property p_ar_single_beat;
        @(posedge clk) disable iff (reset)
        (m_axi_arvalid && m_axi_arready) |-> (m_axi_arlen == 8'd0);
    endproperty

    property p_wlast;
        @(posedge clk) disable iff (reset)
        (m_axi_wvalid && m_axi_wready) |-> m_axi_wlast;
    endproperty

    // ---------------------------------------------------------
    // Target isolation
    // ---------------------------------------------------------

    property p_write_target_exclusive;
        @(posedge clk) disable iff (reset)
        (s0_axi_awvalid || s1_axi_awvalid) |->
        !(s0_axi_awvalid && s1_axi_awvalid);
    endproperty

    property p_read_target_exclusive;
        @(posedge clk) disable iff (reset)
        (s0_axi_arvalid || s1_axi_arvalid) |->
        !(s0_axi_arvalid && s1_axi_arvalid);
    endproperty

    // ---------------------------------------------------------
    // VALID/READY stability
    // ---------------------------------------------------------

    property p_aw_stable;
        @(posedge clk) disable iff (reset)
        (m_axi_awvalid && !m_axi_awready) |=>
        $stable({m_axi_awid, m_axi_awaddr, m_axi_awlen});
    endproperty

    property p_w_stable;
        @(posedge clk) disable iff (reset)
        (m_axi_wvalid && !m_axi_wready) |=>
        $stable({m_axi_wdata, m_axi_wstrb, m_axi_wlast});
    endproperty

    property p_ar_stable;
        @(posedge clk) disable iff (reset)
        (m_axi_arvalid && !m_axi_arready) |=>
        $stable({m_axi_arid, m_axi_araddr, m_axi_arlen});
    endproperty

    property p_b_stable;
        @(posedge clk) disable iff (reset)
        (m_axi_bvalid && !m_axi_bready) |=>
        $stable({m_axi_bid, m_axi_bresp});
    endproperty

    property p_r_stable;
        @(posedge clk) disable iff (reset)
        (m_axi_rvalid && !m_axi_rready) |=>
        $stable({m_axi_rid, m_axi_rdata, m_axi_rresp, m_axi_rlast});
    endproperty

    assert property (p_aw_single_beat);
    assert property (p_ar_single_beat);
    assert property (p_wlast);

    assert property (p_write_target_exclusive);
    assert property (p_read_target_exclusive);

    assert property (p_aw_stable);
    assert property (p_w_stable);
    assert property (p_ar_stable);
    assert property (p_b_stable);
    assert property (p_r_stable);

endmodule

bind axi4_interconnect
    axi4_interconnect_sva #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) u_axi4_interconnect_sva (
        .clk               (clk),
        .reset             (reset),

        .m_axi_awid       (m_axi_awid),
        .m_axi_awaddr     (m_axi_awaddr),
        .m_axi_awlen      (m_axi_awlen),
        .m_axi_awvalid    (m_axi_awvalid),
        .m_axi_awready    (m_axi_awready),

        .m_axi_wdata     (m_axi_wdata),
        .m_axi_wstrb     (m_axi_wstrb),
        .m_axi_wlast     (m_axi_wlast),
        .m_axi_wvalid    (m_axi_wvalid),
        .m_axi_wready    (m_axi_wready),

        .m_axi_arid      (m_axi_arid),
        .m_axi_araddr    (m_axi_araddr),
        .m_axi_arlen     (m_axi_arlen),
        .m_axi_arvalid   (m_axi_arvalid),
        .m_axi_arready   (m_axi_arready),

        .m_axi_bvalid   (m_axi_bvalid),
        .m_axi_bready   (m_axi_bready),
        .m_axi_bid      (m_axi_bid),
        .m_axi_bresp    (m_axi_bresp),

        .m_axi_rvalid   (m_axi_rvalid),
        .m_axi_rready   (m_axi_rready),
        .m_axi_rid      (m_axi_rid),
        .m_axi_rdata    (m_axi_rdata),
        .m_axi_rresp    (m_axi_rresp),
        .m_axi_rlast    (m_axi_rlast),

        .s0_axi_awvalid (s0_axi_awvalid),
        .s1_axi_awvalid (s1_axi_awvalid),
        .s0_axi_arvalid (s0_axi_arvalid),
        .s1_axi_arvalid (s1_axi_arvalid)
    );
