`ifndef AXI4_IF_SV
`define AXI4_IF_SV

interface axi4_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
) (
    input logic clk,
    input logic reset
);

    localparam STRB_WIDTH = DATA_WIDTH / 8;

    // ------------------------------------------------------------
    // Write Address Channel
    // ------------------------------------------------------------

    logic [ID_WIDTH-1:0]     awid;
    logic [ADDR_WIDTH-1:0]   awaddr;
    logic [7:0]              awlen;
    logic                    awvalid;
    logic                    awready;

    // ------------------------------------------------------------
    // Write Data Channel
    // ------------------------------------------------------------

    logic [DATA_WIDTH-1:0]   wdata;
    logic [STRB_WIDTH-1:0]   wstrb;
    logic                    wlast;
    logic                    wvalid;
    logic                    wready;

    // ------------------------------------------------------------
    // Write Response Channel
    // ------------------------------------------------------------

    logic [ID_WIDTH-1:0]     bid;
    logic [1:0]              bresp;
    logic                    bvalid;
    logic                    bready;

    // ------------------------------------------------------------
    // Read Address Channel
    // ------------------------------------------------------------

    logic [ID_WIDTH-1:0]     arid;
    logic [ADDR_WIDTH-1:0]   araddr;
    logic [7:0]              arlen;
    logic                    arvalid;
    logic                    arready;

    // ------------------------------------------------------------
    // Read Data Channel
    // ------------------------------------------------------------

    logic [ID_WIDTH-1:0]     rid;
    logic [DATA_WIDTH-1:0]   rdata;
    logic [1:0]              rresp;
    logic                    rlast;
    logic                    rvalid;
    logic                    rready;

endinterface

`endif
