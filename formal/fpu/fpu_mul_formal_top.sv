module fpu_mul_formal_top;

    wire [31:0] a = $anyconst;
    wire [31:0] b = $anyconst;
    wire [31:0] result;

    fp_mul dut (
        .a      (a),
        .b      (b),
        .result (result)
    );


    // ============================================================
    // CLASSIFICATION
    // ============================================================

    wire a_zero =
        (a[30:0] == 31'h00000000);

    wire b_zero =
        (b[30:0] == 31'h00000000);

    wire a_inf =
        (a[30:23] == 8'hFF) &&
        (a[22:0] == 23'h000000);

    wire b_inf =
        (b[30:23] == 8'hFF) &&
        (b[22:0] == 23'h000000);

    wire a_nan =
        (a[30:23] == 8'hFF) &&
        (a[22:0] != 23'h000000);

    wire b_nan =
        (b[30:23] == 8'hFF) &&
        (b[22:0] != 23'h000000);

    wire a_finite =
        !a_nan && !a_inf;

    wire b_finite =
        !b_nan && !b_inf;

    wire finite_nonzero =
        a_finite &&
        b_finite &&
        !a_zero &&
        !b_zero;


    // ============================================================
    // BASIC SANITY
    // ============================================================

    /*
     * For all fully-known inputs, result must be fully known.
     *
     * Do not use this as a proof of IEEE correctness; it is only
     * a combinational sanity property.
     */



    // ============================================================
    // NaN
    // ============================================================

    /*
     * Any NaN input produces canonical quiet NaN.
     */

    always @(*) begin
        if (a_nan || b_nan)
            assert (result == 32'h7FC00000);
    end


    // ============================================================
    // Infinity * Zero
    // ============================================================

    /*
     * IEEE-754 invalid operation.
     *
     * Architectural result of this implementation:
     * canonical quiet NaN.
     */

    always @(*) begin
        if ((a_inf && b_zero) ||
            (b_inf && a_zero))
            assert (result == 32'h7FC00000);
    end


    // ============================================================
    // Infinity
    // ============================================================

    /*
     * Infinity multiplied by a finite non-zero operand produces
     * signed infinity.
     */

    always @(*) begin
        if ((a_inf && b_finite && !b_zero) ||
            (b_inf && a_finite && !a_zero)) begin

            assert (result[30:23] == 8'hFF);
            assert (result[22:0] == 23'h000000);
            assert (result[31] == (a[31] ^ b[31]));

        end
    end


    // ============================================================
    // Zero
    // ============================================================

    /*
     * Architectural contract of this implementation:
     *
     *     zero result -> +0
     */

    always @(*) begin
        if ((a_zero || b_zero) &&
            !(a_inf || b_inf) &&
            !(a_nan || b_nan))
            assert (result == 32'h00000000);
    end


    // ============================================================
    // FINITE NON-ZERO RESULT CLASSIFICATION
    // ============================================================

    /*
     * A finite non-zero multiplication can produce:
     *
     *   - finite normal
     *   - finite subnormal
     *   - infinity due to overflow
     *
     * It must never produce NaN.
     */

    always @(*) begin
        if (finite_nonzero)
            assert (!(result[30:23] == 8'hFF &&
                      result[22:0] != 23'h000000));
    end


    // ============================================================
    // FINITE NON-ZERO RESULT IS NOT ZERO
    // ============================================================

    /*
     * This is intentionally NOT asserted.
     *
     * Two non-zero binary32 values can multiply to a result which
     * rounds to zero under severe underflow.
     *
     * Therefore:
     *
     *     finite_nonzero -> result != 0
     *
     * would be incorrect.
     */


    // ============================================================
    // RESULT SIGN
    // ============================================================

    /*
     * For finite non-zero results which are not zero after
     * underflow, the sign is the XOR of operand signs.
     *
     * We only constrain the sign when the result is non-zero.
     */

    always @(*) begin
        if (finite_nonzero &&
            result != 32'h00000000)
            assert (result[31] == (a[31] ^ b[31]));
    end


    // ============================================================
    // SPECIAL CASE COVERAGE
    // ============================================================

    cover property (
        a_nan || b_nan
    );

    cover property (
        (a_inf && b_zero) ||
        (b_inf && a_zero)
    );

    cover property (
        (a_inf || b_inf) &&
        !(a_zero || b_zero) &&
        !(a_nan || b_nan)
    );

    cover property (
        (a_zero || b_zero) &&
        !(a_inf || b_inf) &&
        !(a_nan || b_nan)
    );


    // ============================================================
    // FINITE NON-ZERO COVERAGE
    // ============================================================

    cover property (
        finite_nonzero
    );


    // ============================================================
    // NORMAL RESULT COVERAGE
    // ============================================================

    /*
     * Normal finite result:
     *
     *     exponent != 0
     *     exponent != 255
     */

    cover property (
        finite_nonzero &&
        result[30:23] != 8'h00 &&
        result[30:23] != 8'hFF
    );


    // ============================================================
    // SUBNORMAL RESULT COVERAGE
    // ============================================================

    cover property (
        finite_nonzero &&
        result[30:23] == 8'h00 &&
        result[22:0] != 23'h000000
    );


    // ============================================================
    // UNDERFLOW-TO-ZERO COVERAGE
    // ============================================================

    cover property (
        finite_nonzero &&
        result == 32'h00000000
    );


    // ============================================================
    // OVERFLOW-TO-INFINITY COVERAGE
    // ============================================================

    cover property (
        finite_nonzero &&
        result[30:23] == 8'hFF &&
        result[22:0] == 23'h000000
    );


    // ============================================================
    // POSITIVE NORMAL RESULT
    // ============================================================

    cover property (
        finite_nonzero &&
        result[31] == 1'b0 &&
        result[30:23] != 8'h00 &&
        result[30:23] != 8'hFF
    );


    // ============================================================
    // NEGATIVE NORMAL RESULT
    // ============================================================

    cover property (
        finite_nonzero &&
        result[31] == 1'b1 &&
        result[30:23] != 8'h00 &&
        result[30:23] != 8'hFF
    );


    // ============================================================
    // POSITIVE SUBNORMAL RESULT
    // ============================================================

    cover property (
        finite_nonzero &&
        result[31] == 1'b0 &&
        result[30:23] == 8'h00 &&
        result[22:0] != 23'h000000
    );


    // ============================================================
    // NEGATIVE SUBNORMAL RESULT
    // ============================================================

    cover property (
        finite_nonzero &&
        result[31] == 1'b1 &&
        result[30:23] == 8'h00 &&
        result[22:0] != 23'h000000
    );


    // ============================================================
    // ROUNDING / BOUNDARY COVERAGE
    // ============================================================

    /*
     * These are architectural boundary patterns rather than
     * references to internal implementation signals.
     *
     * They are intentionally kept broad here. Internal RTL
     * signals should be exposed explicitly if we later want
     * implementation-level formal coverage.
     */


    // Largest finite result before overflow.
    cover property (
        finite_nonzero &&
        result[30:23] == 8'hFE &&
        result[22:0] == 23'h7FFFFF
    );


    // Smallest positive normal result.
    cover property (
        finite_nonzero &&
        result == 32'h00800000
    );


    // Smallest positive subnormal result.
    cover property (
        finite_nonzero &&
        result == 32'h00000001
    );


    // Largest positive subnormal result.
    cover property (
        finite_nonzero &&
        result == 32'h007FFFFF
    );


    // ============================================================
    // SIGNED ZERO INPUT COVERAGE
    // ============================================================

    cover property (
        a == 32'h80000000
    );

    cover property (
        b == 32'h80000000
    );


    // ============================================================
    // SIGNED INFINITY COVERAGE
    // ============================================================

    cover property (
        a == 32'hFF800000
    );

    cover property (
        b == 32'hFF800000
    );


    // ============================================================
    // NaN COVERAGE
    // ============================================================

    cover property (
        a_nan
    );

    cover property (
        b_nan
    );

endmodule