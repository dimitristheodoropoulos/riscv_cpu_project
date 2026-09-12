package noc_router_pkg;

    typedef struct packed {
        logic [2:0]  src_id;
        logic [2:0]  dst_id;
        logic [3:0]  txn_id;
        logic [31:0] payload;
    } noc_packet_t;

    typedef enum logic [2:0] {
        DIR_LOCAL = 3'b000,
        DIR_NORTH = 3'b001,
        DIR_SOUTH = 3'b010,
        DIR_EAST  = 3'b011,
        DIR_WEST  = 3'b100
    } noc_dir_t;

endpackage


module noc_router #(
    parameter logic ROUTER_X = 1'b0,
    parameter logic ROUTER_Y = 1'b0
) (
    input  logic clk,
    input  logic rst,

    input  logic                         north_in_valid,
    output logic                         north_in_ready,
    input  noc_router_pkg::noc_packet_t  north_in_packet,
    output logic                         north_out_valid,
    input  logic                         north_out_ready,
    output noc_router_pkg::noc_packet_t  north_out_packet,

    input  logic                         south_in_valid,
    output logic                         south_in_ready,
    input  noc_router_pkg::noc_packet_t  south_in_packet,
    output logic                         south_out_valid,
    input  logic                         south_out_ready,
    output noc_router_pkg::noc_packet_t  south_out_packet,

    input  logic                         east_in_valid,
    output logic                         east_in_ready,
    input  noc_router_pkg::noc_packet_t  east_in_packet,
    output logic                         east_out_valid,
    input  logic                         east_out_ready,
    output noc_router_pkg::noc_packet_t  east_out_packet,

    input  logic                         west_in_valid,
    output logic                         west_in_ready,
    input  noc_router_pkg::noc_packet_t  west_in_packet,
    output logic                         west_out_valid,
    input  logic                         west_out_ready,
    output noc_router_pkg::noc_packet_t  west_out_packet,

    input  logic                         local_in_valid,
    output logic                         local_in_ready,
    input  noc_router_pkg::noc_packet_t  local_in_packet,
    output logic                         local_out_valid,
    input  logic                         local_out_ready,
    output noc_router_pkg::noc_packet_t  local_out_packet,

    output logic                         north_error_valid,
    output logic [2:0]                   north_error_dst_id,
    output logic                         south_error_valid,
    output logic [2:0]                   south_error_dst_id,
    output logic                         east_error_valid,
    output logic [2:0]                   east_error_dst_id,
    output logic                         west_error_valid,
    output logic [2:0]                   west_error_dst_id,
    output logic                         local_error_valid,
    output logic [2:0]                   local_error_dst_id
);

    import noc_router_pkg::*;

    localparam int N_INPUTS  = 5;
    localparam int N_OUTPUTS = 5;

    localparam int I_LOCAL = 0;
    localparam int I_NORTH = 1;
    localparam int I_SOUTH = 2;
    localparam int I_EAST  = 3;
    localparam int I_WEST  = 4;

    localparam int O_LOCAL = 0;
    localparam int O_NORTH = 1;
    localparam int O_SOUTH = 2;
    localparam int O_EAST  = 3;
    localparam int O_WEST  = 4;

    logic [N_INPUTS-1:0] slot_valid;
    noc_packet_t         slot_packet [N_INPUTS];

    noc_dir_t route_dir [N_INPUTS];

    logic [N_INPUTS-1:0] request [N_OUTPUTS];
    logic [N_INPUTS-1:0] grant   [N_OUTPUTS];

    logic [2:0] selected_input [N_OUTPUTS];
    logic       grant_valid   [N_OUTPUTS];

    noc_dir_t rr_pointer [N_OUTPUTS];

    logic [N_OUTPUTS-1:0] out_ready_vec;
    logic [N_OUTPUTS-1:0] out_valid_vec;
    noc_packet_t          out_packet_vec [N_OUTPUTS];

    logic [N_INPUTS-1:0] in_valid_vec;
    logic [N_INPUTS-1:0] in_ready_vec;
    noc_packet_t         in_packet_vec [N_INPUTS];

    logic [N_INPUTS-1:0] in_transfer;
    logic [N_INPUTS-1:0] invalid_accept;

    logic [N_OUTPUTS-1:0] out_transfer;

    logic [N_INPUTS-1:0] served_input;

    function automatic logic valid_dst(input logic [2:0] dst_id);
        return (dst_id <= 3);
    endfunction

    function automatic logic [1:0] dst_x(input logic [2:0] dst_id);
        case (dst_id)
            3'b000: return 2'd0;
            3'b001: return 2'd1;
            3'b010: return 2'd0;
            3'b011: return 2'd1;
            default: return 2'd0;
        endcase
    endfunction

    function automatic logic [1:0] dst_y(input logic [2:0] dst_id);
        case (dst_id)
            3'b000: return 2'd0;
            3'b001: return 2'd0;
            3'b010: return 2'd1;
            3'b011: return 2'd1;
            default: return 2'd0;
        endcase
    endfunction

    function automatic noc_dir_t calc_route(
        input noc_packet_t packet
    );
        logic [1:0] dx;
        logic [1:0] dy;

        dx = dst_x(packet.dst_id);
        dy = dst_y(packet.dst_id);

        if (dx > ROUTER_X)
            return DIR_EAST;
        else if (dx < ROUTER_X)
            return DIR_WEST;
        else if (dy > ROUTER_Y)
            return DIR_SOUTH;
        else if (dy < ROUTER_Y)
            return DIR_NORTH;
        else
            return DIR_LOCAL;
    endfunction

    function automatic int dir_to_index(input noc_dir_t dir);
        case (dir)
            DIR_LOCAL: return I_LOCAL;
            DIR_NORTH: return I_NORTH;
            DIR_SOUTH: return I_SOUTH;
            DIR_EAST:  return I_EAST;
            DIR_WEST:  return I_WEST;
            default:   return I_LOCAL;
        endcase
    endfunction

    function automatic noc_dir_t index_to_dir(input int index);
        case (index)
            I_LOCAL: return DIR_LOCAL;
            I_NORTH: return DIR_NORTH;
            I_SOUTH: return DIR_SOUTH;
            I_EAST:  return DIR_EAST;
            I_WEST:  return DIR_WEST;
            default: return DIR_LOCAL;
        endcase
    endfunction

    function automatic noc_dir_t next_rr_dir(input noc_dir_t served);
        int idx;

        idx = dir_to_index(served);

        if (idx == I_WEST)
            return DIR_LOCAL;
        else
            return index_to_dir(idx + 1);
    endfunction

    always_comb begin
        in_valid_vec[I_NORTH] = north_in_valid;
        in_valid_vec[I_SOUTH] = south_in_valid;
        in_valid_vec[I_EAST]  = east_in_valid;
        in_valid_vec[I_WEST]  = west_in_valid;
        in_valid_vec[I_LOCAL] = local_in_valid;

        in_packet_vec[I_NORTH] = north_in_packet;
        in_packet_vec[I_SOUTH] = south_in_packet;
        in_packet_vec[I_EAST]  = east_in_packet;
        in_packet_vec[I_WEST]  = west_in_packet;
        in_packet_vec[I_LOCAL] = local_in_packet;

        in_ready_vec = ~slot_valid;

        north_in_ready = in_ready_vec[I_NORTH];
        south_in_ready = in_ready_vec[I_SOUTH];
        east_in_ready  = in_ready_vec[I_EAST];
        west_in_ready  = in_ready_vec[I_WEST];
        local_in_ready = in_ready_vec[I_LOCAL];

        in_transfer = in_valid_vec & in_ready_vec;

        invalid_accept = '0;

        invalid_accept[I_NORTH] =
            in_transfer[I_NORTH] &&
            !valid_dst(north_in_packet.dst_id);

        invalid_accept[I_SOUTH] =
            in_transfer[I_SOUTH] &&
            !valid_dst(south_in_packet.dst_id);

        invalid_accept[I_EAST] =
            in_transfer[I_EAST] &&
            !valid_dst(east_in_packet.dst_id);

        invalid_accept[I_WEST] =
            in_transfer[I_WEST] &&
            !valid_dst(west_in_packet.dst_id);

        invalid_accept[I_LOCAL] =
            in_transfer[I_LOCAL] &&
            !valid_dst(local_in_packet.dst_id);
    end

    always_comb begin
        north_error_valid = 1'b0;
        south_error_valid = 1'b0;
        east_error_valid  = 1'b0;
        west_error_valid  = 1'b0;
        local_error_valid = 1'b0;

        north_error_dst_id = '0;
        south_error_dst_id = '0;
        east_error_dst_id  = '0;
        west_error_dst_id  = '0;
        local_error_dst_id = '0;

        if (!rst) begin
            if (invalid_accept[I_NORTH]) begin
                north_error_valid = 1'b1;
                north_error_dst_id = north_in_packet.dst_id;
            end

            if (invalid_accept[I_SOUTH]) begin
                south_error_valid = 1'b1;
                south_error_dst_id = south_in_packet.dst_id;
            end

            if (invalid_accept[I_EAST]) begin
                east_error_valid = 1'b1;
                east_error_dst_id = east_in_packet.dst_id;
            end

            if (invalid_accept[I_WEST]) begin
                west_error_valid = 1'b1;
                west_error_dst_id = west_in_packet.dst_id;
            end

            if (invalid_accept[I_LOCAL]) begin
                local_error_valid = 1'b1;
                local_error_dst_id = local_in_packet.dst_id;
            end
        end
    end

    always_comb begin
        for (int i = 0; i < N_INPUTS; i++) begin
            route_dir[i] = DIR_LOCAL;

            if (slot_valid[i])
                route_dir[i] = calc_route(slot_packet[i]);
        end
    end

    always_comb begin
        for (int o = 0; o < N_OUTPUTS; o++) begin
            request[o] = '0;
            grant[o] = '0;
            selected_input[o] = I_LOCAL;
            grant_valid[o] = 1'b0;
            out_packet_vec[o] = '0;
        end

        for (int i = 0; i < N_INPUTS; i++) begin
            if (slot_valid[i]) begin
                case (route_dir[i])
                    DIR_LOCAL: request[O_LOCAL][i] = 1'b1;
                    DIR_NORTH: request[O_NORTH][i] = 1'b1;
                    DIR_SOUTH: request[O_SOUTH][i] = 1'b1;
                    DIR_EAST:  request[O_EAST][i]  = 1'b1;
                    DIR_WEST:  request[O_WEST][i]  = 1'b1;
                    default: ;
                endcase
            end
        end

        for (int o = 0; o < N_OUTPUTS; o++) begin
            int start_idx;
            int candidate_idx;

            start_idx = dir_to_index(rr_pointer[o]);

            for (int offset = 0; offset < N_INPUTS; offset++) begin
                candidate_idx = (start_idx + offset) % N_INPUTS;

                if (!grant_valid[o] && request[o][candidate_idx]) begin
                    grant[o][candidate_idx] = 1'b1;
                    selected_input[o] = candidate_idx;
                    grant_valid[o] = 1'b1;
                    out_packet_vec[o] = slot_packet[candidate_idx];
                end
            end
        end
    end

    always_comb begin
        out_ready_vec[O_NORTH] = north_out_ready;
        out_ready_vec[O_SOUTH] = south_out_ready;
        out_ready_vec[O_EAST]  = east_out_ready;
        out_ready_vec[O_WEST]  = west_out_ready;
        out_ready_vec[O_LOCAL] = local_out_ready;

        out_valid_vec = '0;

        for (int o = 0; o < N_OUTPUTS; o++)
            out_valid_vec[o] = grant_valid[o];

        north_out_valid = out_valid_vec[O_NORTH];
        south_out_valid = out_valid_vec[O_SOUTH];
        east_out_valid  = out_valid_vec[O_EAST];
        west_out_valid  = out_valid_vec[O_WEST];
        local_out_valid = out_valid_vec[O_LOCAL];

        north_out_packet = out_packet_vec[O_NORTH];
        south_out_packet = out_packet_vec[O_SOUTH];
        east_out_packet  = out_packet_vec[O_EAST];
        west_out_packet  = out_packet_vec[O_WEST];
        local_out_packet = out_packet_vec[O_LOCAL];

        out_transfer = out_valid_vec & out_ready_vec;
    end

    always_comb begin
        served_input = '0;

        for (int o = 0; o < N_OUTPUTS; o++) begin
            if (out_transfer[o])
                served_input[selected_input[o]] = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            slot_valid <= '0;

            for (int o = 0; o < N_OUTPUTS; o++)
                rr_pointer[o] <= DIR_LOCAL;
        end
        else begin
            for (int i = 0; i < N_INPUTS; i++) begin
                if (invalid_accept[i]) begin
                    slot_valid[i] <= 1'b0;
                end
                else if (served_input[i]) begin
                    slot_valid[i] <= 1'b0;
                end
                else if (in_transfer[i]) begin
                    slot_valid[i]  <= 1'b1;
                    slot_packet[i] <= in_packet_vec[i];
                end
            end

            for (int o = 0; o < N_OUTPUTS; o++) begin
                if (out_transfer[o])
                    rr_pointer[o] <= next_rr_dir(
                        index_to_dir(selected_input[o])
                    );
            end
        end
    end

endmodule
