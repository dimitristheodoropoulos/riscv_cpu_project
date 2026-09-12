module noc_mesh_2x2 (
    input  logic clk,
    input  logic rst,

    // EP0 <-> R00
    input  logic                        ep0_in_valid,
    output logic                        ep0_in_ready,
    input  noc_router_pkg::noc_packet_t ep0_in_packet,
    output logic                        ep0_out_valid,
    input  logic                        ep0_out_ready,
    output noc_router_pkg::noc_packet_t ep0_out_packet,

    // EP1 <-> R01
    input  logic                        ep1_in_valid,
    output logic                        ep1_in_ready,
    input  noc_router_pkg::noc_packet_t ep1_in_packet,
    output logic                        ep1_out_valid,
    input  logic                        ep1_out_ready,
    output noc_router_pkg::noc_packet_t ep1_out_packet,

    // EP2 <-> R10
    input  logic                        ep2_in_valid,
    output logic                        ep2_in_ready,
    input  noc_router_pkg::noc_packet_t ep2_in_packet,
    output logic                        ep2_out_valid,
    input  logic                        ep2_out_ready,
    output noc_router_pkg::noc_packet_t ep2_out_packet,

    // EP3 <-> R11
    input  logic                        ep3_in_valid,
    output logic                        ep3_in_ready,
    input  noc_router_pkg::noc_packet_t ep3_in_packet,
    output logic                        ep3_out_valid,
    input  logic                        ep3_out_ready,
    output noc_router_pkg::noc_packet_t ep3_out_packet
);

    import noc_router_pkg::*;

    // ------------------------------------------------------------
    // R00 = (0,0)
    // R01 = (1,0)
    // R10 = (0,1)
    // R11 = (1,1)
    // ------------------------------------------------------------

    // R00
    logic r00_north_in_valid;
    logic r00_north_in_ready;
    noc_packet_t r00_north_in_packet;
    logic r00_north_out_valid;
    logic r00_north_out_ready;
    noc_packet_t r00_north_out_packet;

    logic r00_south_in_valid;
    logic r00_south_in_ready;
    noc_packet_t r00_south_in_packet;
    logic r00_south_out_valid;
    logic r00_south_out_ready;
    noc_packet_t r00_south_out_packet;

    logic r00_east_in_valid;
    logic r00_east_in_ready;
    noc_packet_t r00_east_in_packet;
    logic r00_east_out_valid;
    logic r00_east_out_ready;
    noc_packet_t r00_east_out_packet;

    logic r00_west_in_valid;
    logic r00_west_in_ready;
    noc_packet_t r00_west_in_packet;
    logic r00_west_out_valid;
    logic r00_west_out_ready;
    noc_packet_t r00_west_out_packet;

    // R01
    logic r01_north_in_valid;
    logic r01_north_in_ready;
    noc_packet_t r01_north_in_packet;
    logic r01_north_out_valid;
    logic r01_north_out_ready;
    noc_packet_t r01_north_out_packet;

    logic r01_south_in_valid;
    logic r01_south_in_ready;
    noc_packet_t r01_south_in_packet;
    logic r01_south_out_valid;
    logic r01_south_out_ready;
    noc_packet_t r01_south_out_packet;

    logic r01_east_in_valid;
    logic r01_east_in_ready;
    noc_packet_t r01_east_in_packet;
    logic r01_east_out_valid;
    logic r01_east_out_ready;
    noc_packet_t r01_east_out_packet;

    logic r01_west_in_valid;
    logic r01_west_in_ready;
    noc_packet_t r01_west_in_packet;
    logic r01_west_out_valid;
    logic r01_west_out_ready;
    noc_packet_t r01_west_out_packet;

    // R10
    logic r10_north_in_valid;
    logic r10_north_in_ready;
    noc_packet_t r10_north_in_packet;
    logic r10_north_out_valid;
    logic r10_north_out_ready;
    noc_packet_t r10_north_out_packet;

    logic r10_south_in_valid;
    logic r10_south_in_ready;
    noc_packet_t r10_south_in_packet;
    logic r10_south_out_valid;
    logic r10_south_out_ready;
    noc_packet_t r10_south_out_packet;

    logic r10_east_in_valid;
    logic r10_east_in_ready;
    noc_packet_t r10_east_in_packet;
    logic r10_east_out_valid;
    logic r10_east_out_ready;
    noc_packet_t r10_east_out_packet;

    logic r10_west_in_valid;
    logic r10_west_in_ready;
    noc_packet_t r10_west_in_packet;
    logic r10_west_out_valid;
    logic r10_west_out_ready;
    noc_packet_t r10_west_out_packet;

    // R11
    logic r11_north_in_valid;
    logic r11_north_in_ready;
    noc_packet_t r11_north_in_packet;
    logic r11_north_out_valid;
    logic r11_north_out_ready;
    noc_packet_t r11_north_out_packet;

    logic r11_south_in_valid;
    logic r11_south_in_ready;
    noc_packet_t r11_south_in_packet;
    logic r11_south_out_valid;
    logic r11_south_out_ready;
    noc_packet_t r11_south_out_packet;

    logic r11_east_in_valid;
    logic r11_east_in_ready;
    noc_packet_t r11_east_in_packet;
    logic r11_east_out_valid;
    logic r11_east_out_ready;
    noc_packet_t r11_east_out_packet;

    logic r11_west_in_valid;
    logic r11_west_in_ready;
    noc_packet_t r11_west_in_packet;
    logic r11_west_out_valid;
    logic r11_west_out_ready;
    noc_packet_t r11_west_out_packet;

    // ------------------------------------------------------------
    // Boundary directions: no neighboring router.
    // Inputs are tied inactive; outputs are never accepted.
    // ------------------------------------------------------------

    assign r00_north_in_valid = 1'b0;
    assign r00_north_in_packet = '0;
    assign r00_north_out_ready = 1'b0;

    assign r00_west_in_valid = 1'b0;
    assign r00_west_in_packet = '0;
    assign r00_west_out_ready = 1'b0;

    assign r01_north_in_valid = 1'b0;
    assign r01_north_in_packet = '0;
    assign r01_north_out_ready = 1'b0;

    assign r01_east_in_valid = 1'b0;
    assign r01_east_in_packet = '0;
    assign r01_east_out_ready = 1'b0;

    assign r10_west_in_valid = 1'b0;
    assign r10_west_in_packet = '0;
    assign r10_west_out_ready = 1'b0;

    assign r10_south_in_valid = 1'b0;
    assign r10_south_in_packet = '0;
    assign r10_south_out_ready = 1'b0;

    assign r11_east_in_valid = 1'b0;
    assign r11_east_in_packet = '0;
    assign r11_east_out_ready = 1'b0;

    assign r11_south_in_valid = 1'b0;
    assign r11_south_in_packet = '0;
    assign r11_south_out_ready = 1'b0;

    // ------------------------------------------------------------
    // Internal links: R00 <-> R01
    // ------------------------------------------------------------

    assign r01_west_in_valid  = r00_east_out_valid;
    assign r01_west_in_packet = r00_east_out_packet;
    assign r00_east_out_ready = r01_west_in_ready;

    assign r00_east_in_valid  = r01_west_out_valid;
    assign r00_east_in_packet = r01_west_out_packet;
    assign r01_west_out_ready = r00_east_in_ready;

    // ------------------------------------------------------------
    // Internal links: R00 <-> R10
    // ------------------------------------------------------------

    assign r10_north_in_valid  = r00_south_out_valid;
    assign r10_north_in_packet = r00_south_out_packet;
    assign r00_south_out_ready = r10_north_in_ready;

    assign r00_south_in_valid  = r10_north_out_valid;
    assign r00_south_in_packet = r10_north_out_packet;
    assign r10_north_out_ready = r00_south_in_ready;

    // ------------------------------------------------------------
    // Internal links: R10 <-> R11
    // ------------------------------------------------------------

    assign r11_west_in_valid  = r10_east_out_valid;
    assign r11_west_in_packet = r10_east_out_packet;
    assign r10_east_out_ready = r11_west_in_ready;

    assign r10_east_in_valid  = r11_west_out_valid;
    assign r10_east_in_packet = r11_west_out_packet;
    assign r11_west_out_ready = r10_east_in_ready;

    // ------------------------------------------------------------
    // Internal links: R01 <-> R11
    // ------------------------------------------------------------

    assign r11_north_in_valid  = r01_south_out_valid;
    assign r11_north_in_packet = r01_south_out_packet;
    assign r01_south_out_ready = r11_north_in_ready;

    assign r01_south_in_valid  = r11_north_out_valid;
    assign r01_south_in_packet = r11_north_out_packet;
    assign r11_north_out_ready = r01_south_in_ready;

    // ------------------------------------------------------------
    // Local endpoints
    // ------------------------------------------------------------
    // Internal router-local output packets
    noc_packet_t r00_local_out_packet;
    noc_packet_t r01_local_out_packet;
    noc_packet_t r10_local_out_packet;
    noc_packet_t r11_local_out_packet;

    // Router-local endpoint interface signals
    logic r00_local_in_valid;
    logic r00_local_in_ready;
    noc_packet_t r00_local_in_packet;
    logic r00_local_out_valid;
    logic r00_local_out_ready;

    logic r01_local_in_valid;
    logic r01_local_in_ready;
    noc_packet_t r01_local_in_packet;
    logic r01_local_out_valid;
    logic r01_local_out_ready;

    logic r10_local_in_valid;
    logic r10_local_in_ready;
    noc_packet_t r10_local_in_packet;
    logic r10_local_out_valid;
    logic r10_local_out_ready;

    logic r11_local_in_valid;
    logic r11_local_in_ready;
    noc_packet_t r11_local_in_packet;
    logic r11_local_out_valid;
    logic r11_local_out_ready;


    assign ep0_in_ready  = r00_local_in_ready;
    assign r00_local_in_valid  = ep0_in_valid;
    assign r00_local_in_packet = ep0_in_packet;
    assign ep0_out_valid  = r00_local_out_valid;
    assign ep0_out_packet = r00_local_out_packet;
    assign r00_local_out_ready = ep0_out_ready;

    assign ep1_in_ready  = r01_local_in_ready;
    assign r01_local_in_valid  = ep1_in_valid;
    assign r01_local_in_packet = ep1_in_packet;
    assign ep1_out_valid  = r01_local_out_valid;
    assign ep1_out_packet = r01_local_out_packet;
    assign r01_local_out_ready = ep1_out_ready;

    assign ep2_in_ready  = r10_local_in_ready;
    assign r10_local_in_valid  = ep2_in_valid;
    assign r10_local_in_packet = ep2_in_packet;
    assign ep2_out_valid  = r10_local_out_valid;
    assign ep2_out_packet = r10_local_out_packet;
    assign r10_local_out_ready = ep2_out_ready;

    assign ep3_in_ready  = r11_local_in_ready;
    assign r11_local_in_valid  = ep3_in_valid;
    assign r11_local_in_packet = ep3_in_packet;
    assign ep3_out_valid  = r11_local_out_valid;
    assign ep3_out_packet = r11_local_out_packet;
    assign r11_local_out_ready = ep3_out_ready;

    // ------------------------------------------------------------
    // Router instances
    // ------------------------------------------------------------

    noc_router #(
        .ROUTER_X(1'b0),
        .ROUTER_Y(1'b0)
    ) r00 (
        .clk(clk),
        .rst(rst),

        .north_in_valid(r00_north_in_valid),
        .north_in_ready(r00_north_in_ready),
        .north_in_packet(r00_north_in_packet),
        .north_out_valid(r00_north_out_valid),
        .north_out_ready(r00_north_out_ready),
        .north_out_packet(r00_north_out_packet),

        .south_in_valid(r00_south_in_valid),
        .south_in_ready(r00_south_in_ready),
        .south_in_packet(r00_south_in_packet),
        .south_out_valid(r00_south_out_valid),
        .south_out_ready(r00_south_out_ready),
        .south_out_packet(r00_south_out_packet),

        .east_in_valid(r00_east_in_valid),
        .east_in_ready(r00_east_in_ready),
        .east_in_packet(r00_east_in_packet),
        .east_out_valid(r00_east_out_valid),
        .east_out_ready(r00_east_out_ready),
        .east_out_packet(r00_east_out_packet),

        .west_in_valid(r00_west_in_valid),
        .west_in_ready(r00_west_in_ready),
        .west_in_packet(r00_west_in_packet),
        .west_out_valid(r00_west_out_valid),
        .west_out_ready(r00_west_out_ready),
        .west_out_packet(r00_west_out_packet),

        .local_in_valid(ep0_in_valid),
        .local_in_ready(r00_local_in_ready),
        .local_in_packet(ep0_in_packet),
        .local_out_valid(r00_local_out_valid),
        .local_out_ready(ep0_out_ready),
        .local_out_packet(r00_local_out_packet),

        .north_error_valid(),
        .north_error_dst_id(),
        .south_error_valid(),
        .south_error_dst_id(),
        .east_error_valid(),
        .east_error_dst_id(),
        .west_error_valid(),
        .west_error_dst_id(),
        .local_error_valid(),
        .local_error_dst_id()
    );

    noc_router #(
        .ROUTER_X(1'b1),
        .ROUTER_Y(1'b0)
    ) r01 (
        .clk(clk),
        .rst(rst),

        .north_in_valid(r01_north_in_valid),
        .north_in_ready(r01_north_in_ready),
        .north_in_packet(r01_north_in_packet),
        .north_out_valid(r01_north_out_valid),
        .north_out_ready(r01_north_out_ready),
        .north_out_packet(r01_north_out_packet),

        .south_in_valid(r01_south_in_valid),
        .south_in_ready(r01_south_in_ready),
        .south_in_packet(r01_south_in_packet),
        .south_out_valid(r01_south_out_valid),
        .south_out_ready(r01_south_out_ready),
        .south_out_packet(r01_south_out_packet),

        .east_in_valid(r01_east_in_valid),
        .east_in_ready(r01_east_in_ready),
        .east_in_packet(r01_east_in_packet),
        .east_out_valid(r01_east_out_valid),
        .east_out_ready(r01_east_out_ready),
        .east_out_packet(r01_east_out_packet),

        .west_in_valid(r01_west_in_valid),
        .west_in_ready(r01_west_in_ready),
        .west_in_packet(r01_west_in_packet),
        .west_out_valid(r01_west_out_valid),
        .west_out_ready(r01_west_out_ready),
        .west_out_packet(r01_west_out_packet),

        .local_in_valid(ep1_in_valid),
        .local_in_ready(r01_local_in_ready),
        .local_in_packet(ep1_in_packet),
        .local_out_valid(r01_local_out_valid),
        .local_out_ready(ep1_out_ready),
        .local_out_packet(r01_local_out_packet),

        .north_error_valid(),
        .north_error_dst_id(),
        .south_error_valid(),
        .south_error_dst_id(),
        .east_error_valid(),
        .east_error_dst_id(),
        .west_error_valid(),
        .west_error_dst_id(),
        .local_error_valid(),
        .local_error_dst_id()
    );

    noc_router #(
        .ROUTER_X(1'b0),
        .ROUTER_Y(1'b1)
    ) r10 (
        .clk(clk),
        .rst(rst),

        .north_in_valid(r10_north_in_valid),
        .north_in_ready(r10_north_in_ready),
        .north_in_packet(r10_north_in_packet),
        .north_out_valid(r10_north_out_valid),
        .north_out_ready(r10_north_out_ready),
        .north_out_packet(r10_north_out_packet),

        .south_in_valid(r10_south_in_valid),
        .south_in_ready(r10_south_in_ready),
        .south_in_packet(r10_south_in_packet),
        .south_out_valid(r10_south_out_valid),
        .south_out_ready(r10_south_out_ready),
        .south_out_packet(r10_south_out_packet),

        .east_in_valid(r10_east_in_valid),
        .east_in_ready(r10_east_in_ready),
        .east_in_packet(r10_east_in_packet),
        .east_out_valid(r10_east_out_valid),
        .east_out_ready(r10_east_out_ready),
        .east_out_packet(r10_east_out_packet),

        .west_in_valid(r10_west_in_valid),
        .west_in_ready(r10_west_in_ready),
        .west_in_packet(r10_west_in_packet),
        .west_out_valid(r10_west_out_valid),
        .west_out_ready(r10_west_out_ready),
        .west_out_packet(r10_west_out_packet),

        .local_in_valid(ep2_in_valid),
        .local_in_ready(r10_local_in_ready),
        .local_in_packet(ep2_in_packet),
        .local_out_valid(r10_local_out_valid),
        .local_out_ready(ep2_out_ready),
        .local_out_packet(r10_local_out_packet),

        .north_error_valid(),
        .north_error_dst_id(),
        .south_error_valid(),
        .south_error_dst_id(),
        .east_error_valid(),
        .east_error_dst_id(),
        .west_error_valid(),
        .west_error_dst_id(),
        .local_error_valid(),
        .local_error_dst_id()
    );

    noc_router #(
        .ROUTER_X(1'b1),
        .ROUTER_Y(1'b1)
    ) r11 (
        .clk(clk),
        .rst(rst),

        .north_in_valid(r11_north_in_valid),
        .north_in_ready(r11_north_in_ready),
        .north_in_packet(r11_north_in_packet),
        .north_out_valid(r11_north_out_valid),
        .north_out_ready(r11_north_out_ready),
        .north_out_packet(r11_north_out_packet),

        .south_in_valid(r11_south_in_valid),
        .south_in_ready(r11_south_in_ready),
        .south_in_packet(r11_south_in_packet),
        .south_out_valid(r11_south_out_valid),
        .south_out_ready(r11_south_out_ready),
        .south_out_packet(r11_south_out_packet),

        .east_in_valid(r11_east_in_valid),
        .east_in_ready(r11_east_in_ready),
        .east_in_packet(r11_east_in_packet),
        .east_out_valid(r11_east_out_valid),
        .east_out_ready(r11_east_out_ready),
        .east_out_packet(r11_east_out_packet),

        .west_in_valid(r11_west_in_valid),
        .west_in_ready(r11_west_in_ready),
        .west_in_packet(r11_west_in_packet),
        .west_out_valid(r11_west_out_valid),
        .west_out_ready(r11_west_out_ready),
        .west_out_packet(r11_west_out_packet),

        .local_in_valid(ep3_in_valid),
        .local_in_ready(r11_local_in_ready),
        .local_in_packet(ep3_in_packet),
        .local_out_valid(r11_local_out_valid),
        .local_out_ready(ep3_out_ready),
        .local_out_packet(r11_local_out_packet),

        .north_error_valid(),
        .north_error_dst_id(),
        .south_error_valid(),
        .south_error_dst_id(),
        .east_error_valid(),
        .east_error_dst_id(),
        .west_error_valid(),
        .west_error_dst_id(),
        .local_error_valid(),
        .local_error_dst_id()
    );

endmodule
