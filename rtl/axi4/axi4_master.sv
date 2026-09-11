`timescale 1ns/1ps

// ============================================================================
// AXI4 Master v1
//
// Scope:
//   - Single-beat reads and writes only
//   - 32-bit address/data by default
//   - 4-bit transaction ID by default
//   - One command outstanding at a time
//   - AWLEN/ARLEN = 0
//   - WLAST = 1
//
// Non-goals for v1:
//   - Bursts
//   - Multiple outstanding transactions
//   - QoS / cache coherency / ACE / CHI
// ============================================================================

module axi4_master #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 4
) (
    input  logic                         clk,
    input  logic                         reset,

    // ------------------------------------------------------------------------
    // Local command interface
    // ------------------------------------------------------------------------
    input  logic                         cmd_valid,
    output logic                         cmd_ready,

    input  logic                         cmd_write,
    input  logic [ID_WIDTH-1:0]          cmd_id,
    input  logic [ADDR_WIDTH-1:0]        cmd_addr,
    input  logic [DATA_WIDTH-1:0]        cmd_wdata,
    input  logic [DATA_WIDTH/8-1:0]      cmd_wstrb,

    // ------------------------------------------------------------------------
    // Local completion interface
    // ------------------------------------------------------------------------
    output logic                         rsp_valid,
    input  logic                         rsp_ready,

    output logic [ID_WIDTH-1:0]          rsp_id,
    output logic [DATA_WIDTH-1:0]        rsp_rdata,
    output logic [1:0]                   rsp_resp,

    // ------------------------------------------------------------------------
    // AXI4 Master interface
    // ------------------------------------------------------------------------

    // Write address channel
    output logic [ID_WIDTH-1:0]          m_axi_awid,
    output logic [ADDR_WIDTH-1:0]        m_axi_awaddr,
    output logic [7:0]                   m_axi_awlen,
    output logic                         m_axi_awvalid,
    input  logic                         m_axi_awready,

    // Write data channel
    output logic [DATA_WIDTH-1:0]        m_axi_wdata,
    output logic [DATA_WIDTH/8-1:0]      m_axi_wstrb,
    output logic                         m_axi_wlast,
    output logic                         m_axi_wvalid,
    input  logic                         m_axi_wready,

    // Write response channel
    input  logic [ID_WIDTH-1:0]          m_axi_bid,
    input  logic [1:0]                   m_axi_bresp,
    input  logic                         m_axi_bvalid,
    output logic                         m_axi_bready,

    // Read address channel
    output logic [ID_WIDTH-1:0]          m_axi_arid,
    output logic [ADDR_WIDTH-1:0]        m_axi_araddr,
    output logic [7:0]                   m_axi_arlen,
    output logic                         m_axi_arvalid,
    input  logic                         m_axi_arready,

    // Read data channel
    input  logic [ID_WIDTH-1:0]          m_axi_rid,
    input  logic [DATA_WIDTH-1:0]        m_axi_rdata,
    input  logic [1:0]                   m_axi_rresp,
    input  logic                         m_axi_rlast,
    input  logic                         m_axi_rvalid,
    output logic                         m_axi_rready
);

    localparam int STRB_WIDTH = DATA_WIDTH / 8;

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_SEND_AW,
        ST_SEND_W,
        ST_WAIT_B,
        ST_SEND_AR,
        ST_WAIT_R,
        ST_RESP
    } state_t;

    state_t state;

    // ------------------------------------------------------------------------
    // Latched command
    // ------------------------------------------------------------------------

    logic [ID_WIDTH-1:0]     cmd_id_reg;
    logic [ADDR_WIDTH-1:0]   cmd_addr_reg;
    logic [DATA_WIDTH-1:0]   cmd_wdata_reg;
    logic [STRB_WIDTH-1:0]  cmd_wstrb_reg;
    logic                    cmd_write_reg;

    // ------------------------------------------------------------------------
    // Latched response
    // ------------------------------------------------------------------------

    logic [ID_WIDTH-1:0]     rsp_id_reg;
    logic [DATA_WIDTH-1:0]   rsp_rdata_reg;
    logic [1:0]              rsp_resp_reg;

    // ------------------------------------------------------------------------
    // Local interface
    // ------------------------------------------------------------------------

    assign cmd_ready = (state == ST_IDLE);

    assign rsp_valid = (state == ST_RESP);
    assign rsp_id    = rsp_id_reg;
    assign rsp_rdata = rsp_rdata_reg;
    assign rsp_resp  = rsp_resp_reg;

    // ------------------------------------------------------------------------
    // AXI outputs
    //
    // Payload remains driven from registered command state while VALID is
    // asserted, so it remains stable until the corresponding READY handshake.
    // ------------------------------------------------------------------------

    assign m_axi_awid    = cmd_id_reg;
    assign m_axi_awaddr  = cmd_addr_reg;
    assign m_axi_awlen   = 8'd0;
    assign m_axi_awvalid = (state == ST_SEND_AW);

    assign m_axi_wdata   = cmd_wdata_reg;
    assign m_axi_wstrb   = cmd_wstrb_reg;
    assign m_axi_wlast   = 1'b1;
    assign m_axi_wvalid  = (state == ST_SEND_W);

    assign m_axi_bready  = (state == ST_WAIT_B);

    assign m_axi_arid    = cmd_id_reg;
    assign m_axi_araddr  = cmd_addr_reg;
    assign m_axi_arlen   = 8'd0;
    assign m_axi_arvalid = (state == ST_SEND_AR);

    assign m_axi_rready  = (state == ST_WAIT_R);

    // ------------------------------------------------------------------------
    // State machine
    // ------------------------------------------------------------------------

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state          <= ST_IDLE;

            cmd_id_reg     <= '0;
            cmd_addr_reg   <= '0;
            cmd_wdata_reg  <= '0;
            cmd_wstrb_reg  <= '0;
            cmd_write_reg  <= 1'b0;

            rsp_id_reg     <= '0;
            rsp_rdata_reg  <= '0;
            rsp_resp_reg   <= 2'b00;
        end
        else begin
            case (state)

                ST_IDLE: begin
                    if (cmd_valid) begin
                        cmd_id_reg    <= cmd_id;
                        cmd_addr_reg  <= cmd_addr;
                        cmd_wdata_reg <= cmd_wdata;
                        cmd_wstrb_reg <= cmd_wstrb;
                        cmd_write_reg <= cmd_write;

                        if (cmd_write)
                            state <= ST_SEND_AW;
                        else
                            state <= ST_SEND_AR;
                    end
                end

                ST_SEND_AW: begin
                    if (m_axi_awvalid && m_axi_awready)
                        state <= ST_SEND_W;
                end

                ST_SEND_W: begin
                    if (m_axi_wvalid && m_axi_wready)
                        state <= ST_WAIT_B;
                end

                ST_WAIT_B: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        rsp_id_reg    <= m_axi_bid;
                        rsp_rdata_reg <= '0;
                        rsp_resp_reg  <= m_axi_bresp;
                        state          <= ST_RESP;
                    end
                end

                ST_SEND_AR: begin
                    if (m_axi_arvalid && m_axi_arready)
                        state <= ST_WAIT_R;
                end

                ST_WAIT_R: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        rsp_id_reg    <= m_axi_rid;
                        rsp_rdata_reg <= m_axi_rdata;
                        rsp_resp_reg  <= m_axi_rresp;
                        state          <= ST_RESP;
                    end
                end

                ST_RESP: begin
                    if (rsp_valid && rsp_ready)
                        state <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                end

            endcase
        end
    end

endmodule
