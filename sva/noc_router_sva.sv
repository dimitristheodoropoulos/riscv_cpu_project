module noc_router_sva #(
    parameter int N_INPUTS  = 5,
    parameter int N_OUTPUTS = 5
) (
    input logic clk,
    input logic rst,

    input logic [N_OUTPUTS-1:0] out_ready_vec,
    input logic [N_OUTPUTS-1:0] out_valid_vec,
    input noc_router_pkg::noc_packet_t out_packet_vec [N_OUTPUTS],
    input logic [N_OUTPUTS-1:0] out_transfer,

    input logic [N_INPUTS-1:0] request [N_OUTPUTS],
    input logic [N_INPUTS-1:0] grant [N_OUTPUTS],

    input logic [2:0] selected_input [N_OUTPUTS],
    input logic       grant_valid   [N_OUTPUTS],

    input noc_router_pkg::noc_dir_t rr_pointer [N_OUTPUTS]
);

    import noc_router_pkg::*;

    /*
     * Previous-cycle samples are used to check temporal contract
     * properties without duplicating the DUT's routing/arbitration
     * implementation.
     */
    logic       prev_out_valid   [N_OUTPUTS];
    logic       prev_out_ready   [N_OUTPUTS];
    logic       prev_out_transfer[N_OUTPUTS];
    noc_packet_t prev_out_packet  [N_OUTPUTS];
    noc_dir_t    prev_rr_pointer  [N_OUTPUTS];

    logic have_prev;

    integer o;
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            have_prev <= 1'b0;

            for (o = 0; o < N_OUTPUTS; o = o + 1) begin
                prev_out_valid[o]    <= 1'b0;
                prev_out_ready[o]    <= 1'b0;
                prev_out_transfer[o] <= 1'b0;
                prev_out_packet[o]   <= '0;
                prev_rr_pointer[o]   <= DIR_LOCAL;
            end
        end
        else begin
            if (have_prev) begin

                /*
                 * ----------------------------------------------------
                 * Arbitration legality
                 * ----------------------------------------------------
                 */

                for (o = 0; o < N_OUTPUTS; o = o + 1) begin

                    assert ($onehot0(grant[o]))
                        else $error(
                            "NoC SVA: output %0d has multiple grants",
                            o
                        );

                    assert (grant_valid[o] == (|grant[o]))
                        else $error(
                            "NoC SVA: output %0d grant_valid/grant mismatch",
                            o
                        );

                    if (grant_valid[o]) begin
                        assert (selected_input[o] < 3'd5)
                            else $error(
                                "NoC SVA: output %0d selected invalid input %0d",
                                o, selected_input[o]
                            );

                        assert (grant[o][selected_input[o]])
                            else $error(
                                "NoC SVA: output %0d selected input is not granted",
                                o
                            );

                        assert (request[o][selected_input[o]])
                            else $error(
                                "NoC SVA: output %0d granted a non-requesting input",
                                o
                            );
                    end

                    /*
                     * ------------------------------------------------
                     * Output transfer semantics
                     * ------------------------------------------------
                     */

                    assert (out_valid_vec[o] == grant_valid[o])
                        else $error(
                            "NoC SVA: output %0d valid/grant mismatch",
                            o
                        );

                    assert (
                        out_transfer[o] ==
                        (out_valid_vec[o] && out_ready_vec[o])
                    )
                        else $error(
                            "NoC SVA: output %0d transfer violates valid/ready",
                            o
                        );

                    /*
                     * ------------------------------------------------
                     * Backpressure stability
                     * ------------------------------------------------
                     *
                     * If the previous cycle had a valid packet stalled
                     * by ready=0, the packet must remain presented.
                     */

                    if (prev_out_valid[o] && !prev_out_ready[o]) begin
                        assert (out_valid_vec[o])
                            else $error(
                                "NoC SVA: output %0d dropped valid under backpressure",
                                o
                            );

                        assert (out_packet_vec[o] == prev_out_packet[o])
                            else $error(
                                "NoC SVA: output %0d packet changed under backpressure",
                                o
                            );
                    end

                end

                /*
                 * An input can have at most one route/output request,
                 * therefore it must not be granted by multiple outputs
                 * in the same cycle.
                 */
                for (i = 0; i < N_INPUTS; i = i + 1) begin
                    assert (
                        $onehot0({
                            grant[4][i],
                            grant[3][i],
                            grant[2][i],
                            grant[1][i],
                            grant[0][i]
                        })
                    )
                        else $error(
                            "NoC SVA: input %0d granted by multiple outputs",
                            i
                        );
                end
            end

            /*
             * Sample current cycle for the next temporal check.
             */
            have_prev <= 1'b1;

            for (o = 0; o < N_OUTPUTS; o = o + 1) begin
                prev_out_valid[o]    <= out_valid_vec[o];
                prev_out_ready[o]    <= out_ready_vec[o];
                prev_out_transfer[o] <= out_transfer[o];
                prev_out_packet[o]   <= out_packet_vec[o];
                prev_rr_pointer[o]   <= rr_pointer[o];
            end
        end
    end

    /*
     * ------------------------------------------------------------
     * RR pointer temporal contract
     * ------------------------------------------------------------
     *
     * Capture the pre-edge service condition and RR pointer at
     * posedge.  The DUT updates rr_pointer in the NBA region of
     * that same edge.  The delayed check therefore observes the
     * completed DUT state update.
     */

    function automatic noc_dir_t sva_index_to_dir(input logic [2:0] index);
        case (index)
            0: return DIR_LOCAL;
            1: return DIR_NORTH;
            2: return DIR_SOUTH;
            3: return DIR_EAST;
            4: return DIR_WEST;
            default: return DIR_LOCAL;
        endcase
    endfunction

    function automatic noc_dir_t sva_next_rr_dir(input noc_dir_t served);
        case (served)
            DIR_LOCAL: return DIR_NORTH;
            DIR_NORTH: return DIR_SOUTH;
            DIR_SOUTH: return DIR_EAST;
            DIR_EAST:  return DIR_WEST;
            DIR_WEST:  return DIR_LOCAL;
            default:   return DIR_LOCAL;
        endcase
    endfunction

    logic rr_prev_service[N_OUTPUTS];
    noc_dir_t rr_prev_pointer[N_OUTPUTS];
    noc_dir_t rr_expected_pointer[N_OUTPUTS];
    integer rr_o;

    always @(posedge clk) begin
        if (!rst) begin
            for (rr_o = 0; rr_o < N_OUTPUTS; rr_o = rr_o + 1) begin
                rr_prev_service[rr_o] <= out_transfer[rr_o];
                rr_prev_pointer[rr_o] <= rr_pointer[rr_o];

                if (out_transfer[rr_o])
                    rr_expected_pointer[rr_o] <=
                        sva_next_rr_dir(sva_index_to_dir(selected_input[rr_o]));
                else
                    rr_expected_pointer[rr_o] <= rr_pointer[rr_o];
            end

            #1;

            for (rr_o = 0; rr_o < N_OUTPUTS; rr_o = rr_o + 1) begin
                if (rr_prev_service[rr_o]) begin
                    assert (rr_pointer[rr_o] == rr_expected_pointer[rr_o])
                        else $error(
                            "NoC SVA: output %0d RR pointer did not reach expected post-service value",
                            rr_o
                        );
                end
                else begin
                    assert (rr_pointer[rr_o] == rr_prev_pointer[rr_o])
                        else $error(
                            "NoC SVA: output %0d RR pointer changed without service",
                            rr_o
                        );
                end
            end
        end
    end

endmodule


/*
 * Bind the assertion layer to every noc_router instance.
 *
 * No changes are made to rtl/noc_router.sv.
 */
bind noc_router noc_router_sva #(
    .N_INPUTS  (5),
    .N_OUTPUTS (5)
) noc_router_sva_i (
    .clk             (clk),
    .rst             (rst),

    .out_ready_vec   (out_ready_vec),
    .out_valid_vec   (out_valid_vec),
    .out_packet_vec  (out_packet_vec),
    .out_transfer    (out_transfer),

    .request         (request),
    .grant           (grant),

    .selected_input  (selected_input),
    .grant_valid     (grant_valid),

    .rr_pointer      (rr_pointer)
);
