module pa_power_controller (
    input  logic clk,
    input  logic rst_n,
    input  logic power_down_req,
    input  logic wake_req,
    output logic domain_on,
    output logic isolation_en,
    output logic save_req,
    output logic restore_req
);

    typedef enum logic [2:0] {
        ST_ON        = 3'b000,
        ST_SAVE      = 3'b001,
        ST_ISOLATED  = 3'b010,
        ST_OFF       = 3'b011,
        ST_RESTORE   = 3'b100
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= ST_ON;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;

        case (state)
            ST_ON: begin
                if (power_down_req)
                    next_state = ST_SAVE;
            end

            ST_SAVE: begin
                next_state = ST_ISOLATED;
            end

            ST_ISOLATED: begin
                next_state = ST_OFF;
            end

            ST_OFF: begin
                if (wake_req)
                    next_state = ST_RESTORE;
            end

            ST_RESTORE: begin
                next_state = ST_ON;
            end

            default: begin
                next_state = ST_ON;
            end
        endcase
    end

    always_comb begin
        domain_on   = 1'b0;
        isolation_en = 1'b1;
        save_req    = 1'b0;
        restore_req = 1'b0;

        case (state)
            ST_ON: begin
                domain_on    = 1'b1;
                isolation_en = 1'b0;
            end

            ST_SAVE: begin
                domain_on    = 1'b1;
                isolation_en = 1'b0;
                save_req     = 1'b1;
            end

            ST_ISOLATED: begin
                domain_on    = 1'b1;
                isolation_en = 1'b1;
            end

            ST_OFF: begin
                domain_on    = 1'b0;
                isolation_en = 1'b1;
            end

            ST_RESTORE: begin
                domain_on    = 1'b1;
                isolation_en = 1'b1;
                restore_req  = 1'b1;
            end

            default: begin
                domain_on    = 1'b1;
                isolation_en = 1'b0;
            end
        endcase
    end

endmodule
