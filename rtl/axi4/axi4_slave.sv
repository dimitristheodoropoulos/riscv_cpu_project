`ifndef AXI4_SLAVE_SV
`define AXI4_SLAVE_SV

module axi4_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter MEM_DEPTH  = 256
) (
    input  logic                     clk,
    input  logic                     reset,

    // ------------------------------------------------------------
    // AXI4 Write Address Channel
    // ------------------------------------------------------------
    input  logic [ID_WIDTH-1:0]      s_axi_awid,
    input  logic [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  logic [7:0]               s_axi_awlen,
    input  logic                     s_axi_awvalid,
    output logic                     s_axi_awready,

    // ------------------------------------------------------------
    // AXI4 Write Data Channel
    // ------------------------------------------------------------
    input  logic [DATA_WIDTH-1:0]    s_axi_wdata,
    input  logic [DATA_WIDTH/8-1:0]  s_axi_wstrb,
    input  logic                     s_axi_wlast,
    input  logic                     s_axi_wvalid,
    output logic                     s_axi_wready,

    // ------------------------------------------------------------
    // AXI4 Write Response Channel
    // ------------------------------------------------------------
    output logic [ID_WIDTH-1:0]      s_axi_bid,
    output logic [1:0]               s_axi_bresp,
    output logic                     s_axi_bvalid,
    input  logic                     s_axi_bready,

    // ------------------------------------------------------------
    // AXI4 Read Address Channel
    // ------------------------------------------------------------
    input  logic [ID_WIDTH-1:0]      s_axi_arid,
    input  logic [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  logic [7:0]               s_axi_arlen,
    input  logic                     s_axi_arvalid,
    output logic                     s_axi_arready,

    // ------------------------------------------------------------
    // AXI4 Read Data Channel
    // ------------------------------------------------------------
    output logic [ID_WIDTH-1:0]      s_axi_rid,
    output logic [DATA_WIDTH-1:0]    s_axi_rdata,
    output logic [1:0]               s_axi_rresp,
    output logic                     s_axi_rlast,
    output logic                     s_axi_rvalid,
    input  logic                     s_axi_rready
);

    localparam STRB_WIDTH = DATA_WIDTH / 8;

    // ------------------------------------------------------------
    // Simple internal memory
    // ------------------------------------------------------------

    logic [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    // ------------------------------------------------------------
    // Write state
    // ------------------------------------------------------------

    logic                  aw_pending;
    logic [ID_WIDTH-1:0]   awid_reg;
    logic [ADDR_WIDTH-1:0] awaddr_reg;

    // ------------------------------------------------------------
    // Read state
    // ------------------------------------------------------------

    logic                  ar_pending;
    logic [ID_WIDTH-1:0]   arid_reg;
    logic [ADDR_WIDTH-1:0] araddr_reg;

    // ------------------------------------------------------------
    // Basic single-beat AXI4 endpoint
    //
    // AXI4-1 scope:
    //   - single beat only
    //   - AWLEN must be zero
    //   - ARLEN must be zero
    //   - no outstanding transactions
    //   - one write and one read response at a time
    // ------------------------------------------------------------

    always_comb begin
        s_axi_awready = !aw_pending && !s_axi_bvalid;
        s_axi_wready  = aw_pending && !s_axi_bvalid;
        s_axi_arready = !ar_pending && !s_axi_rvalid;
    end

    // ------------------------------------------------------------
    // Sequential protocol/state handling
    // ------------------------------------------------------------

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin

            aw_pending   <= 1'b0;
            awid_reg     <= '0;
            awaddr_reg   <= '0;

            ar_pending   <= 1'b0;
            arid_reg     <= '0;
            araddr_reg   <= '0;

            s_axi_bid    <= '0;
            s_axi_bresp  <= 2'b00;
            s_axi_bvalid <= 1'b0;

            s_axi_rid    <= '0;
            s_axi_rdata  <= '0;
            s_axi_rresp  <= 2'b00;
            s_axi_rlast  <= 1'b0;
            s_axi_rvalid <= 1'b0;

        end else begin

            // --------------------------------------------------------
            // Write response completion
            // --------------------------------------------------------

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            // --------------------------------------------------------
            // Read response completion
            // --------------------------------------------------------

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
                s_axi_rlast  <= 1'b0;
            end

            // --------------------------------------------------------
            // Capture write address
            // --------------------------------------------------------

            if (s_axi_awvalid && s_axi_awready) begin
                aw_pending <= 1'b1;
                awid_reg   <= s_axi_awid;
                awaddr_reg <= s_axi_awaddr;
            end

            // --------------------------------------------------------
            // Accept write data and generate response
            // --------------------------------------------------------

            if (s_axi_wvalid && s_axi_wready) begin

                if (s_axi_wstrb[0])
                    mem[awaddr_reg[ADDR_WIDTH-1:2]]
                        [7:0] <= s_axi_wdata[7:0];

                if (STRB_WIDTH > 1 && s_axi_wstrb[1])
                    mem[awaddr_reg[ADDR_WIDTH-1:2]]
                        [15:8] <= s_axi_wdata[15:8];

                if (STRB_WIDTH > 2 && s_axi_wstrb[2])
                    mem[awaddr_reg[ADDR_WIDTH-1:2]]
                        [23:16] <= s_axi_wdata[23:16];

                if (STRB_WIDTH > 3 && s_axi_wstrb[3])
                    mem[awaddr_reg[ADDR_WIDTH-1:2]]
                        [31:24] <= s_axi_wdata[31:24];

                aw_pending  <= 1'b0;

                s_axi_bid   <= awid_reg;
                s_axi_bresp <= 2'b00;       // OKAY
                s_axi_bvalid <= 1'b1;
            end

            // --------------------------------------------------------
            // Capture read address
            // --------------------------------------------------------

            if (s_axi_arvalid && s_axi_arready) begin

                ar_pending <= 1'b1;
                arid_reg   <= s_axi_arid;
                araddr_reg <= s_axi_araddr;

                s_axi_rid   <= s_axi_arid;
                s_axi_rdata <= mem[s_axi_araddr[ADDR_WIDTH-1:2]];
                s_axi_rresp <= 2'b00;        // OKAY
                s_axi_rlast <= 1'b1;
                s_axi_rvalid <= 1'b1;

            end

            // --------------------------------------------------------
            // Read request has been converted into a response
            // --------------------------------------------------------

            if (s_axi_rvalid && s_axi_rready) begin
                ar_pending <= 1'b0;
            end

        end
    end

endmodule

`endif
