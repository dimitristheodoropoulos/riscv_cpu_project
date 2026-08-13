
module fp_mul (
    input  [31:0] a,
    input  [31:0] b,
    output reg [31:0] result
);

    /*
     * IEEE-754 binary32 multiplier
     *
     * Rounding mode:
     *     Round to Nearest, Ties to Even (RNE)
     *
     * Supported:
     *     - normal numbers
     *     - subnormal numbers
     *     - signed zero
     *     - infinity
     *     - NaN
     *     - overflow
     *     - underflow
     *
     * No exception flags are exposed by this block.
     */

    reg        sign_a;
    reg        sign_b;
    reg        sign_result;

    reg [7:0]  exp_a;
    reg [7:0]  exp_b;

    reg [22:0] frac_a;
    reg [22:0] frac_b;

    reg [23:0] sig_a;
    reg [23:0] sig_b;

    reg [47:0] product;

    /*
     * Normalized product.
     *
     * After normalization:
     *
     *     norm_product[47] = 1
     *
     * and the binary point is immediately below bit 47.
     */
    reg [47:0] norm_product;

    reg signed [12:0] exp_a_unbiased;
    reg signed [12:0] exp_b_unbiased;
    reg signed [13:0] exp_product;

    /*
     * 24-bit significand plus one extra carry bit.
     *
     * This avoids assigning 25-bit values into a 24-bit register.
     */
    reg [23:0] rounded_sig;
    reg [24:0] rounded_sig_ext;

    reg guard_bit;
    reg round_bit;
    reg sticky_bit;

    reg increment;

    reg [63:0] shifted_product;

    integer shift_count;
    integer subnormal_shift;

    /*
     * ---
     * Classification helpers
     * ---
     */

    wire a_is_zero =
        (a[30:0] == 31'h00000000);

    wire b_is_zero =
        (b[30:0] == 31'h00000000);

    wire a_is_inf =
        (a[30:23] == 8'hFF) &&
        (a[22:0] == 23'h000000);

    wire b_is_inf =
        (b[30:23] == 8'hFF) &&
        (b[22:0] == 23'h000000);

    wire a_is_nan =
        (a[30:23] == 8'hFF) &&
        (a[22:0] != 23'h000000);

    wire b_is_nan =
        (b[30:23] == 8'hFF) &&
        (b[22:0] != 23'h000000);

    /*
     * ---
     * Main combinational datapath
     * ---
     */

    always @(*) begin

        /*
         * Defaults
         */
        sign_a       = a[31];
        sign_b       = b[31];
        sign_result  = a[31] ^ b[31];

        exp_a        = a[30:23];
        exp_b        = b[30:23];

        frac_a       = a[22:0];
        frac_b       = b[22:0];

        sig_a        = 24'h000000;
        sig_b        = 24'h000000;

        product      = 48'h000000000000;
        norm_product = 48'h000000000000;

        exp_a_unbiased = 13'sd0;
        exp_b_unbiased = 13'sd0;
        exp_product    = 14'sd0;

        rounded_sig     = 24'h000000;
        rounded_sig_ext = 25'h0000000;

        guard_bit  = 1'b0;
        round_bit  = 1'b0;
        sticky_bit = 1'b0;

        increment = 1'b0;

        shifted_product = 64'h0000000000000000;

        shift_count     = 0;
        subnormal_shift = 0;

        result = 32'h00000000;


        /*
         * --------------------------------------------------------
         * NaN
         * --------------------------------------------------------
         *
         * Any NaN input produces canonical quiet NaN.
         *
         * Canonical NaN:
         *
         *     0x7FC00000
         */
        if (a_is_nan || b_is_nan) begin

            result = 32'h7FC00000;

        end


        /*
         * --------------------------------------------------------
         * Infinity * zero
         * --------------------------------------------------------
         *
         * IEEE-754 invalid operation.
         *
         * Since this block has no exception output, return
         * canonical quiet NaN.
         */
        else if ((a_is_inf && b_is_zero) ||
                 (b_is_inf && a_is_zero)) begin

            result = 32'h7FC00000;

        end


        /*
         * --------------------------------------------------------
         * Infinity
         * --------------------------------------------------------
         */
        else if (a_is_inf || b_is_inf) begin

            result = {
                sign_result,
                8'hFF,
                23'h000000
            };

        end


        /*
         * --------------------------------------------------------
         * Zero
         * --------------------------------------------------------
         *
         * Architectural contract:
         *
         *     zero result -> +0
         */
        else if (a_is_zero || b_is_zero) begin

            result = 32'h00000000;

        end


        /*
         * --------------------------------------------------------
         * Finite non-zero multiplication
         * --------------------------------------------------------
         */
        else begin

            /*
             * ----------------------------------------------------
             * Decode operand A
             * ----------------------------------------------------
             *
             * Normal:
             *
             *     sig = 1.fraction
             *     exponent = encoded_exponent - 127
             *
             * Subnormal:
             *
             *     normalize fraction so bit 23 becomes 1.
             *
             * For a subnormal:
             *
             *     initial exponent = -126
             *
             * and every left normalization shift reduces the
             * effective exponent by one.
             */
            if (exp_a == 8'h00) begin

                sig_a = {1'b0, frac_a};

                exp_a_unbiased = -13'sd126;

                /*
                 * Normalize subnormal significand.
                 */
                for (shift_count = 0;
                     shift_count < 23;
                     shift_count = shift_count + 1) begin

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
                    $signed({5'b00000, exp_a}) - 13'sd127;

            end


            /*
             * ----------------------------------------------------
             * Decode operand B
             * ----------------------------------------------------
             */
            if (exp_b == 8'h00) begin

                sig_b = {1'b0, frac_b};

                exp_b_unbiased = -13'sd126;

                /*
                 * Normalize subnormal significand.
                 */
                for (shift_count = 0;
                     shift_count < 23;
                     shift_count = shift_count + 1) begin

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
                    $signed({5'b00000, exp_b}) - 13'sd127;

            end


            /*
             * ----------------------------------------------------
             * 24 x 24 significand multiplication
             * ----------------------------------------------------
             */
            product = sig_a * sig_b;


            /*
             * ----------------------------------------------------
             * Normalize product
             * ----------------------------------------------------
             *
             * Product range:
             *
             *     1.0 <= product < 4.0
             *
             * If bit 47 is set:
             *
             *     product = 1.xxxxx
             *
             * Otherwise:
             *
             *     product = 0.1xxxxx
             *
             * Shift the second case left by one so that
             * norm_product[47] is always the hidden bit.
             */
            if (product[47]) begin

                norm_product = product;

                exp_product =
                    exp_a_unbiased +
                    exp_b_unbiased +
                    14'sd1;

            end
            else begin

                norm_product = product << 1;

                exp_product =
                    exp_a_unbiased +
                    exp_b_unbiased;

            end


            /*
             * ----------------------------------------------------
             * Normal result
             * ----------------------------------------------------
             *
             * A normal binary32 result has:
             *
             *     exponent >= -126
             */
            if (exp_product >= -14'sd126) begin

                /*
                 * Keep 24 bits:
                 *
                 *     [47:24]
                 *
                 * Discarded:
                 *
                 *     guard  = bit 23
                 *     round  = bit 22
                 *     sticky = bits 21:0
                 */
                rounded_sig = norm_product[47:24];

                guard_bit  = norm_product[23];
                round_bit  = norm_product[22];

                sticky_bit =
                    |norm_product[21:0];


                /*
                 * ------------------------------------------------
                 * Round to nearest, ties to even
                 * ------------------------------------------------
                 */
                increment =
                    guard_bit &&
                    (round_bit ||
                     sticky_bit ||
                     rounded_sig[0]);


                /*
                 * Use a 25-bit temporary so a carry cannot be lost.
                 */
                rounded_sig_ext = {1'b0, rounded_sig};

                if (increment) begin

                    rounded_sig_ext =
                        rounded_sig_ext + 25'd1;

                end


                /*
                 * If rounding generated:
                 *
                 *     10.000...
                 *
                 * renormalize to:
                 *
                 *     1.000...
                 *
                 * and increment the exponent.
                 */
                if (rounded_sig_ext[24]) begin

                    rounded_sig = 24'h800000;

                    exp_product =
                        exp_product + 14'sd1;

                end
                else begin

                    rounded_sig = rounded_sig_ext[23:0];

                end


                /*
                 * ------------------------------------------------
                 * Overflow
                 * ------------------------------------------------
                 *
                 * Maximum finite exponent is +127.
                 *
                 * Anything above that becomes infinity under
                 * round-to-nearest.
                 */
                if (exp_product > 14'sd127) begin

                    result = {
                        sign_result,
                        8'hFF,
                        23'h000000
                    };

                end
                else begin

                    result = {
                        sign_result,
                        exp_product[7:0] + 8'd127,
                        rounded_sig[22:0]
                    };

                end

            end


            /*
             * ----------------------------------------------------
             * Subnormal / underflow result
             * ----------------------------------------------------
             *
             * Need to produce:
             *
             *     fraction = round(value * 2^149)
             *
             * Since:
             *
             *     value = norm_product * 2^(exp_product - 47)
             *
             * we need:
             *
             *     norm_product >> (-exp_product - 102)
             *
             * for negative exponents below -126.
             */
            else begin

                subnormal_shift =
                    -exp_product - 102;


                /*
                 * ------------------------------------------------
                 * Shift amount < 48
                 * ------------------------------------------------
                 *
                 * norm_product is 48 bits wide.
                 */
                if (subnormal_shift < 48) begin

                    shifted_product = norm_product;


                    /*
                     * Capture rounding information before shifting.
                     */
                    if (subnormal_shift > 0) begin

                        /*
                         * Retained result:
                         *
                         *     norm_product >> subnormal_shift
                         */
                        rounded_sig =
                            norm_product >>
                            subnormal_shift;

                        guard_bit =
                            norm_product[subnormal_shift - 1];

                        if (subnormal_shift >= 2) begin

                            round_bit =
                                norm_product[subnormal_shift - 2];

                        end
                        else begin

                            round_bit = 1'b0;

                        end

                        if (subnormal_shift >= 3) begin

                            sticky_bit = 1'b0;

                            /*
                             * Variable part-selects are avoided because
                             * Questa requires constant range bounds.
                             */
                            for (shift_count = 0;
                                 shift_count < 48;
                                 shift_count = shift_count + 1) begin

                                if (shift_count <= subnormal_shift - 3) begin

                                    sticky_bit =
                                        sticky_bit |
                                        norm_product[shift_count];

                                end

                            end

                        end
                        else begin

                            sticky_bit = 1'b0;

                        end

                    end
                    else begin

                        rounded_sig = norm_product;

                        guard_bit  = 1'b0;
                        round_bit  = 1'b0;
                        sticky_bit = 1'b0;

                    end


                    /*
                     * RNE.
                     */
                    increment =
                        guard_bit &&
                        (round_bit ||
                         sticky_bit ||
                         rounded_sig[0]);


                    /*
                     * Use 25-bit temporary for carry handling.
                     */
                    rounded_sig_ext = {1'b0, rounded_sig};

                    if (increment) begin

                        rounded_sig_ext =
                            rounded_sig_ext + 25'd1;

                    end

                    rounded_sig =
                        rounded_sig_ext[23:0];

                end


                /*
                 * ------------------------------------------------
                 * Very small result
                 * ------------------------------------------------
                 *
                 * If shift >= 48, all product bits are below the
                 * retained subnormal range.
                 *
                 * At shift == 48, bit 47 is the halfway bit.
                 */
                else begin

                    rounded_sig = 24'd0;

                    if (subnormal_shift == 48) begin

                        guard_bit =
                            norm_product[47];

                        round_bit = 1'b0;

                        sticky_bit =
                            |norm_product[46:0];

                        /*
                         * Exact halfway must round to even.
                         *
                         * The retained result is zero, which is even,
                         * therefore increment only when sticky is set.
                         */
                        increment =
                            guard_bit &&
                            sticky_bit;

                        if (increment) begin

                            rounded_sig = 24'd1;

                        end

                    end
                    else begin

                        rounded_sig = 24'd0;

                    end

                end


                /*
                 * ------------------------------------------------
                 * Rounding a subnormal can cross the normal boundary.
                 *
                 * The largest subnormal is:
                 *
                 *     0x007FFFFF
                 *
                 * and rounding it upward gives:
                 *
                 *     0x00800000
                 *
                 * which is the smallest normal number.
                 */
                if (rounded_sig >= 24'h800000) begin

                    result = {
                        sign_result,
                        8'h01,
                        23'h000000
                    };

                end
                else begin

                    result = {
                        sign_result,
                        8'h00,
                        rounded_sig[22:0]
                    };

                end

            end

        end

    end

endmodule
