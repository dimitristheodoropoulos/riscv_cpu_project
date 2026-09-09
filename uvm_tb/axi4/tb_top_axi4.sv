`timescale 1ns/1ps

`include "uvm_macros.svh"

import uvm_pkg::*;
import axi4_test_pkg::*;

module tb_top_axi4;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam ID_WIDTH   = 4;

    logic clk;
    logic reset;

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Reset
    // ------------------------------------------------------------

    initial begin
        reset = 1'b1;
        repeat (4) @(posedge clk);
        reset = 1'b0;
    end

    // ------------------------------------------------------------
    // AXI4 interface
    // ------------------------------------------------------------

    axi4_if #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    ) axi_if (
        .clk   (clk),
        .reset (reset)
    );

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    axi4_slave #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .MEM_DEPTH  (256)
    ) dut (
        .clk        (clk),
        .reset      (reset),

        .s_axi_awid    (axi_if.awid),
        .s_axi_awaddr  (axi_if.awaddr),
        .s_axi_awlen   (axi_if.awlen),
        .s_axi_awvalid (axi_if.awvalid),
        .s_axi_awready (axi_if.awready),

        .s_axi_wdata   (axi_if.wdata),
        .s_axi_wstrb   (axi_if.wstrb),
        .s_axi_wlast   (axi_if.wlast),
        .s_axi_wvalid  (axi_if.wvalid),
        .s_axi_wready  (axi_if.wready),

        .s_axi_bid     (axi_if.bid),
        .s_axi_bresp   (axi_if.bresp),
        .s_axi_bready  (axi_if.bready),
        .s_axi_bvalid  (axi_if.bvalid),

        .s_axi_arid    (axi_if.arid),
        .s_axi_araddr  (axi_if.araddr),
        .s_axi_arlen   (axi_if.arlen),
        .s_axi_arvalid (axi_if.arvalid),
        .s_axi_arready (axi_if.arready),

        .s_axi_rid     (axi_if.rid),
        .s_axi_rdata   (axi_if.rdata),
        .s_axi_rresp   (axi_if.rresp),
        .s_axi_rlast   (axi_if.rlast),
        .s_axi_rready  (axi_if.rready),
        .s_axi_rvalid  (axi_if.rvalid)
    );

    // ------------------------------------------------------------
    // UVM virtual interface
    // ------------------------------------------------------------

    initial begin
        uvm_config_db#(virtual axi4_if)::set(
            null,
            "*",
            "vif",
            axi_if
        );

        run_test("axi4_test");
    end

endmodule
