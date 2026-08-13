module fp_div (
    input  [31:0] a,
    input  [31:0] b,
    output reg [31:0] result
);

    reg        sign_a, sign_b;
    reg [7:0]  exp_a, exp_b;
    reg [22:0] frac_a, frac_b;

    reg [23:0] sig_a, sig_b;
    reg signed [12:0] exp_a_unbiased, exp_b_unbiased;
    reg signed [14:0] exp_unbiased;

    localparam EXTRA  = 32;
    localparam QWIDTH = 24 + EXTRA;

    reg [QWIDTH-1:0] dividend;
    reg [QWIDTH-1:0] quotient;
    reg [QWIDTH-1:0] remainder;

    reg [23:0] sig_raw;
    reg        guard, round_bit, sticky;
    reg        round_up;
    reg [24:0] sig_rounded;

    integer shift_cnt;
    integer i;

    wire a_is_zero = (a[30:0] == 31'd0);
    wire b_is_zero = (b[30:0] == 31'd0);

    wire a_is_inf =
        (a[30:23] == 8'hFF) &&
        (a[22:0]  == 23'd0);

    wire b_is_inf =
        (b[30:23] == 8'hFF) &&
        (b[22:0]  == 23'd0);

    wire a_is_nan =
        (a[30:23] == 8'hFF) &&
        (a[22:0]  != 23'd0);

    wire b_is_nan =
        (b[30:23] == 8'hFF) &&
        (b[22:0]  != 23'd0);

    always @(*) begin

        sign_a = a[31];
        sign_b = b[31];

        exp_a  = a[30:23];
        exp_b  = b[30:23];

        frac_a = a[22:0];
        frac_b = b[22:0];

        result = 32'h00000000;

        // ----------------------------------------------------
        // Special cases
        // ----------------------------------------------------

        if (a_is_nan || b_is_nan) begin

            result = 32'h7FC00000;

        end
        else if ((a_is_inf && b_is_inf) ||
                 (a_is_zero && b_is_zero)) begin

            result = 32'h7FC00000;

        end
        else if (b_is_zero) begin

            result = {
                sign_a ^ sign_b,
                8'hFF,
                23'd0
            };

        end
        else if (a_is_inf) begin

            result = {
                sign_a ^ sign_b,
                8'hFF,
                23'd0
            };

        end
        else if (b_is_inf) begin

            result = {
                sign_a ^ sign_b,
                8'd0,
                23'd0
            };

        end
        else if (a_is_zero) begin
            // Architectural contract: zero numerator always returns +0
            result = 32'h00000000;
        end
        else begin

            // ------------------------------------------------
            // Decode A
            // ------------------------------------------------

            if (exp_a == 8'd0) begin

                sig_a = {1'b0, frac_a};
                exp_a_unbiased = -13'sd126;

                for (shift_cnt = 0;
                     shift_cnt < 23;
                     shift_cnt = shift_cnt + 1) begin

                    if (sig_a[23] == 1'b0) begin
                        sig_a = sig_a << 1;
                        exp_a_unbiased =
                            exp_a_unbiased - 13'sd1;
                    end

                end

            end
            else begin

                sig_a = {1'b1, frac_a};

                exp_a_unbiased =
                    $signed({5'b0, exp_a}) - 13'sd127;

            end

            // ------------------------------------------------
            // Decode B
            // ------------------------------------------------

            if (exp_b == 8'd0) begin

                sig_b = {1'b0, frac_b};
                exp_b_unbiased = -13'sd126;

                for (shift_cnt = 0;
                     shift_cnt < 23;
                     shift_cnt = shift_cnt + 1) begin

                    if (sig_b[23] == 1'b0) begin
                        sig_b = sig_b << 1;
                        exp_b_unbiased =
                            exp_b_unbiased - 13'sd1;
                    end

                end

            end
            else begin

                sig_b = {1'b1, frac_b};

                exp_b_unbiased =
                    $signed({5'b0, exp_b}) - 13'sd127;

            end

            // ------------------------------------------------
            // Integer division
            //
            // quotient = (sig_a / sig_b) * 2^32
            // ------------------------------------------------

            dividend = {sig_a, {EXTRA{1'b0}}};

            quotient = dividend / sig_b;

            remainder = dividend % sig_b;

            // ------------------------------------------------
            // Normalisation
            //
            // sig_a / sig_b is in [0.5, 2)
            //
            // Case 1:
            //   1.0 <= sig_a/sig_b < 2.0
            //   quotient[32] = 1
            //
            // Case 2:
            //   0.5 <= sig_a/sig_b < 1.0
            //   shift quotient left by one
            // ------------------------------------------------

            if (quotient[32]) begin

                exp_unbiased =
                    exp_a_unbiased - exp_b_unbiased;

            end
            else begin

                quotient = quotient << 1;

                remainder = remainder << 1;

                if (remainder >= sig_b) begin

                    quotient[0] = 1'b1;
                    remainder   = remainder - sig_b;

                end

                exp_unbiased =
                    exp_a_unbiased -
                    exp_b_unbiased -
                    14'sd1;

            end

            // ------------------------------------------------
            // Normal result
            // ------------------------------------------------

            if (exp_unbiased >= -14'sd126) begin

                sig_raw   = quotient[32:9];

                guard     = quotient[8];
                round_bit = quotient[7];

                sticky =
                    (|quotient[6:0]) ||
                    (remainder != 0);

                // Round-to-nearest-even

                round_up =
                    guard &&
                    (round_bit ||
                     sticky ||
                     sig_raw[0]);

                sig_rounded =
                    {1'b0, sig_raw} +
                    {24'd0, round_up};

                // ------------------------------------------------
                // Rounding carry / renormalisation
                //
                // Example:
                //   1.111... + 1 ULP
                //        ->
                //   10.000...
                //
                // sig_rounded[24] is the new leading 1.
                // ------------------------------------------------

                if (sig_rounded[24]) begin

                    sig_rounded = sig_rounded >> 1;

                    exp_unbiased = exp_unbiased + 1;

                end

                // ------------------------------------------------
                // Overflow
                // ------------------------------------------------

                if (exp_unbiased > 14'sd127) begin

                    result = {
                        sign_a ^ sign_b,
                        8'hFF,
                        23'd0
                    };

                end
                else begin

                    result = {
                        sign_a ^ sign_b,
                        exp_unbiased[7:0] + 8'd127,
                        sig_rounded[22:0]
                    };

                end

            end

            // ------------------------------------------------
            // Subnormal result
            // ------------------------------------------------

            else begin

                shift_cnt = 32 - 149 - exp_unbiased;

                if (shift_cnt >= QWIDTH) begin

                    sig_raw   = 24'd0;
                    guard     = 1'b0;
                    round_bit = 1'b0;

                    sticky =
                        (|quotient) ||
                        (remainder != 0);

                end
                else begin

                    sig_raw = quotient >> shift_cnt;
                    sig_raw = sig_raw[23:0];

                    guard =
                        (shift_cnt >= 1) ?
                        quotient[shift_cnt-1] :
                        1'b0;

                    round_bit =
                        (shift_cnt >= 2) ?
                        quotient[shift_cnt-2] :
                        1'b0;

                    sticky = (remainder != 0);

                    if (shift_cnt >= 3) begin

                        for (i = 0;
                             i <= shift_cnt-3;
                             i = i + 1) begin

                            if (i < QWIDTH)
                                sticky =
                                    sticky || quotient[i];

                        end

                    end

                end

                // ------------------------------------------------
                // Round-to-nearest-even
                // ------------------------------------------------

                round_up =
                    guard &&
                    (round_bit ||
                     sticky ||
                     sig_raw[0]);

                sig_rounded =
                    {1'b0, sig_raw} +
                    {24'd0, round_up};

                // ------------------------------------------------
                // Subnormal -> smallest normal
                // ------------------------------------------------

                if (sig_rounded[23]) begin

                    result = {
                        sign_a ^ sign_b,
                        8'd1,
                        23'd0
                    };

                end
                else begin

                    result = {
                        sign_a ^ sign_b,
                        8'd0,
                        sig_rounded[22:0]
                    };

                end

            end

        end

    end

endmodule