module pa_switchable_block (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       domain_on,
    input  logic       save_req,
    input  logic       restore_req,
    input  logic [7:0] data_in,
    output logic [7:0] data_out,
    output logic [7:0] retained_state
);

    logic [7:0] state_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg     <= 8'h00;
            retained_state <= 8'h00;
        end
        else if (domain_on) begin
            if (save_req)
                retained_state <= state_reg;

            if (restore_req)
                state_reg <= retained_state;
            else
                state_reg <= data_in;
        end
    end

    always_comb begin
        if (domain_on)
            data_out = state_reg;
        else
            data_out = 8'h00;
    end

endmodule
