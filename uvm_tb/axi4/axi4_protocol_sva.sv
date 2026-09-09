`timescale 1ns/1ps

module axi4_protocol_sva #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
) (
    input logic clk,
    input logic reset,

    input logic [ID_WIDTH-1:0]     awid,
    input logic [ADDR_WIDTH-1:0]   awaddr,
    input logic [7:0]              awlen,
    input logic                    awvalid,
    input logic                    awready,

    input logic [DATA_WIDTH-1:0]   wdata,
    input logic [DATA_WIDTH/8-1:0] wstrb,
    input logic                    wlast,
    input logic                    wvalid,
    input logic                    wready,

    input logic [ID_WIDTH-1:0]     bid,
    input logic [1:0]              bresp,
    input logic                    bvalid,
    input logic                    bready,

    input logic [ID_WIDTH-1:0]     arid,
    input logic [ADDR_WIDTH-1:0]   araddr,
    input logic [7:0]              arlen,
    input logic                    arvalid,
    input logic                    arready,

    input logic [ID_WIDTH-1:0]     rid,
    input logic [DATA_WIDTH-1:0]   rdata,
    input logic [1:0]              rresp,
    input logic                    rlast,
    input logic                    rvalid,
    input logic                    rready
);

    default clocking cb @(posedge clk); endclocking

    // ------------------------------------------------------------
    // VALID must remain asserted while READY is low.
    // Payload must remain stable as well.
    // ------------------------------------------------------------

    property p_aw_stable;
        disable iff (reset)
        awvalid && !awready |=> awvalid &&
            $stable(awid) &&
            $stable(awaddr) &&
            $stable(awlen);
    endproperty

    property p_w_stable;
        disable iff (reset)
        wvalid && !wready |=> wvalid &&
            $stable(wdata) &&
            $stable(wstrb) &&
            $stable(wlast);
    endproperty

    property p_b_stable;
        disable iff (reset)
        bvalid && !bready |=> bvalid &&
            $stable(bid) &&
            $stable(bresp);
    endproperty

    property p_ar_stable;
        disable iff (reset)
        arvalid && !arready |=> arvalid &&
            $stable(arid) &&
            $stable(araddr) &&
            $stable(arlen);
    endproperty

    property p_r_stable;
        disable iff (reset)
        rvalid && !rready |=> rvalid &&
            $stable(rid) &&
            $stable(rdata) &&
            $stable(rresp) &&
            $stable(rlast);
    endproperty

    // ------------------------------------------------------------
    // AXI4 single-beat scope
    // ------------------------------------------------------------

    property p_aw_single_beat;
        disable iff (reset)
        awvalid && awready |-> awlen == 8'd0;
    endproperty

    property p_ar_single_beat;
        disable iff (reset)
        arvalid && arready |-> arlen == 8'd0;
    endproperty

    // ------------------------------------------------------------
    // Write data must terminate the single-beat transfer.
    // ------------------------------------------------------------

    property p_wlast_on_handshake;
        disable iff (reset)
        wvalid && wready |-> wlast;
    endproperty

    // ------------------------------------------------------------
    // Response channels may only complete on VALID && READY.
    // ------------------------------------------------------------

    property p_bvalid_holds;
        disable iff (reset)
        bvalid && !bready |=> bvalid;
    endproperty

    property p_rvalid_holds;
        disable iff (reset)
        rvalid && !rready |=> rvalid;
    endproperty

    // ------------------------------------------------------------
    // Assertions
    // ------------------------------------------------------------

    a_aw_stable:
        assert property (p_aw_stable)
        else $error("AXI4 AW channel changed while VALID && !READY");

    a_w_stable:
        assert property (p_w_stable)
        else $error("AXI4 W channel changed while VALID && !READY");

    a_b_stable:
        assert property (p_b_stable)
        else $error("AXI4 B channel changed while VALID && !READY");

    a_ar_stable:
        assert property (p_ar_stable)
        else $error("AXI4 AR channel changed while VALID && !READY");

    a_r_stable:
        assert property (p_r_stable)
        else $error("AXI4 R channel changed while VALID && !READY");

    a_aw_single_beat:
        assert property (p_aw_single_beat)
        else $error("AXI4 AWLEN is non-zero in single-beat scope");

    a_ar_single_beat:
        assert property (p_ar_single_beat)
        else $error("AXI4 ARLEN is non-zero in single-beat scope");

    a_wlast_on_handshake:
        assert property (p_wlast_on_handshake)
        else $error("AXI4 WLAST missing on single-beat W handshake");

    a_bvalid_holds:
        assert property (p_bvalid_holds)
        else $error("AXI4 BVALID dropped while BREADY was low");

    a_rvalid_holds:
        assert property (p_rvalid_holds)
        else $error("AXI4 RVALID dropped while RREADY was low");

endmodule
