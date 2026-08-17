module fpu_div_shift_waiver_top;

    // Model the RTL's exp_unbiased range.
    reg signed [14:0] exp_unbiased;

    // Exact RTL arithmetic:
    // shift_cnt = 32 - 149 - exp_unbiased
    integer shift_cnt;

    always @(*) begin
        shift_cnt = 32 - 149 - exp_unbiased;

        if (exp_unbiased < -15'sd126)
            assert(shift_cnt >= 10);
    end

endmodule
