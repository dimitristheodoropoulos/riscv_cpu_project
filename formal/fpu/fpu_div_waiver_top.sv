module fpu_div_waiver_top;

    wire [31:0] a = $anyconst;
    wire [31:0] b = $anyconst;
    wire [31:0] result;

    fp_div dut (
        .a      (a),
        .b      (b),
        .result (result)
    );

    /*
     * RTL relation:
     *
     *   subnormal path:
     *       exp_unbiased < -126
     *
     *   shift count:
     *       shift_cnt = 32 - 149 - exp_unbiased
     *
     * Therefore:
     *
     *       exp_unbiased < -126
     *          =>
     *       shift_cnt >= 10
     */

    always @(*) begin
        if (dut.exp_unbiased < -15'sd126)
            assert(dut.shift_cnt >= 10);
    end

endmodule
