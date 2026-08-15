`timescale 1ns/1ps

module fpu_tb;

reg        clk;
reg        rst;
reg [31:0] a;
reg [31:0] b;
reg [2:0]  op;

wire [31:0] result;
wire        ready;

integer errors;

localparam OP_ADD = 3'b000;
localparam OP_SUB = 3'b001;
localparam OP_MUL = 3'b010;
localparam OP_DIV = 3'b011;

fpu dut (
    .clk    (clk),
    .rst    (rst),
    .a      (a),
    .b      (b),
    .op     (op),
    .result (result),
    .ready  (ready)
);

always #5 clk = ~clk;

task automatic check_result;
input [31:0]  expected;
input [127:0] test_name;

begin
    @(posedge clk);
    #1;

    if (!ready) begin
        $display(
            "FAIL: %s | ready was not asserted",
            test_name
        );
        errors = errors + 1;
    end
    else if (result !== expected) begin
        $display(
            "FAIL: %s | expected=%h got=%h",
            test_name,
            expected,
            result
        );
        errors = errors + 1;
    end
    else begin
        $display(
            "PASS: %s | expected=%h got=%h",
            test_name,
            expected,
            result
        );
    end
end
endtask

initial begin

    clk    = 1'b0;
    rst    = 1'b1;
    a      = 32'b0;
    b      = 32'b0;
    op     = OP_ADD;
    errors = 0;

    #20;
    rst = 1'b0;


    // ============================================================
    // Basic arithmetic
    // ============================================================

    // ADD: 2.0 + 3.0 = 5.0
    a  = 32'h40000000;
    b  = 32'h40400000;
    op = OP_ADD;
    check_result(
        32'h40A00000,
        "FPU ADD 2.0 + 3.0"
    );

    // SUB: 4.0 - 2.0 = 2.0
    a  = 32'h40800000;
    b  = 32'h40000000;
    op = OP_SUB;
    check_result(
        32'h40000000,
        "FPU SUB 4.0 - 2.0"
    );

    // MUL: 3.0 * 2.0 = 6.0
    a  = 32'h40400000;
    b  = 32'h40000000;
    op = OP_MUL;
    check_result(
        32'h40C00000,
        "FPU MUL 3.0 * 2.0"
    );

    // DIV: 8.0 / 2.0 = 4.0
    a  = 32'h41000000;
    b  = 32'h40000000;
    op = OP_DIV;
    check_result(
        32'h40800000,
        "FPU DIV 8.0 / 2.0"
    );


    // ============================================================
    // Sign coverage
    // ============================================================

    // ADD: -2.0 + 3.0 = 1.0
    a  = 32'hC0000000;
    b  = 32'h40400000;
    op = OP_ADD;
    check_result(
        32'h3F800000,
        "FPU ADD -2.0 + 3.0"
    );

    // ADD: 2.0 + -3.0 = -1.0
    a  = 32'h40000000;
    b  = 32'hC0400000;
    op = OP_ADD;
    check_result(
        32'hBF800000,
        "FPU ADD 2.0 + -3.0"
    );

    // SUB: 2.0 - 3.0 = -1.0
    a  = 32'h40000000;
    b  = 32'h40400000;
    op = OP_SUB;
    check_result(
        32'hBF800000,
        "FPU SUB 2.0 - 3.0"
    );

    // SUB: -2.0 - 3.0 = -5.0
    a  = 32'hC0000000;
    b  = 32'h40400000;
    op = OP_SUB;
    check_result(
        32'hC0A00000,
        "FPU SUB -2.0 - 3.0"
    );

    // MUL: -3.0 * 2.0 = -6.0
    a  = 32'hC0400000;
    b  = 32'h40000000;
    op = OP_MUL;
    check_result(
        32'hC0C00000,
        "FPU MUL -3.0 * 2.0"
    );

    // MUL: -3.0 * -2.0 = +6.0
    a  = 32'hC0400000;
    b  = 32'hC0000000;
    op = OP_MUL;
    check_result(
        32'h40C00000,
        "FPU MUL -3.0 * -2.0"
    );

    // DIV: -8.0 / 2.0 = -4.0
    a  = 32'hC1000000;
    b  = 32'h40000000;
    op = OP_DIV;
    check_result(
        32'hC0800000,
        "FPU DIV -8.0 / 2.0"
    );

    // DIV: -8.0 / -2.0 = +4.0
    a  = 32'hC1000000;
    b  = 32'hC0000000;
    op = OP_DIV;
    check_result(
        32'h40800000,
        "FPU DIV -8.0 / -2.0"
    );


    // ============================================================
    // DIV targeted boundary test
    // ============================================================

    // 0x3FFFFFFF = 1.9999998807907104
    // 0x3F800000 = 1.0
    //
    // Therefore:
    //
    //     0x3FFFFFFF / 0x3F800000
    //         = 1.9999998807907104
    //
    // Expected binary32 result:
    //
    //     0x3FFFFFFF
    //
    // This is a near-2.0 normalization boundary case.

    a  = 32'h3FFFFFFF;
    b  = 32'h3F800000;
    op = OP_DIV;
    check_result(
        32'h3FFFFFFF,
        "FPU DIV near-2.0 boundary"
    );


    // ============================================================
    // ADD special-value coverage
    // ============================================================

    // NaN + normal = NaN
    a  = 32'h7FC00000;
    b  = 32'h3F800000;
    op = OP_ADD;
    check_result(
        32'h7FC00000,
        "FPU ADD NaN + 1.0"
    );

    // normal + NaN = NaN
    a  = 32'h3F800000;
    b  = 32'h7FC00000;
    op = OP_ADD;
    check_result(
        32'h7FC00000,
        "FPU ADD 1.0 + NaN"
    );

    // +Inf + +Inf = +Inf
    a  = 32'h7F800000;
    b  = 32'h7F800000;
    op = OP_ADD;
    check_result(
        32'h7F800000,
        "FPU ADD +Inf + +Inf"
    );

    // -Inf + -Inf = -Inf
    a  = 32'hFF800000;
    b  = 32'hFF800000;
    op = OP_ADD;
    check_result(
        32'hFF800000,
        "FPU ADD -Inf + -Inf"
    );

    // +Inf + -Inf = NaN
    a  = 32'h7F800000;
    b  = 32'hFF800000;
    op = OP_ADD;
    check_result(
        32'h7FC00000,
        "FPU ADD +Inf + -Inf"
    );

    // -Inf + +Inf = NaN
    a  = 32'hFF800000;
    b  = 32'h7F800000;
    op = OP_ADD;
    check_result(
        32'h7FC00000,
        "FPU ADD -Inf + +Inf"
    );

    // +Inf + normal = +Inf
    a  = 32'h7F800000;
    b  = 32'h3F800000;
    op = OP_ADD;
    check_result(
        32'h7F800000,
        "FPU ADD +Inf + 1.0"
    );

    // normal + +Inf = +Inf
    a  = 32'h3F800000;
    b  = 32'h7F800000;
    op = OP_ADD;
    check_result(
        32'h7F800000,
        "FPU ADD 1.0 + +Inf"
    );


    // ============================================================
    // ADD internal-path coverage
    // ============================================================

    // Equal exponents, same sign: 1.0 + 1.0 = 2.0
    a  = 32'h3F800000;
    b  = 32'h3F800000;
    op = OP_ADD;
    check_result(
        32'h40000000,
        "FPU ADD equal exponents"
    );

    // exp_a < exp_b: 2.0 + 4.0 = 6.0
    a  = 32'h40000000;
    b  = 32'h40800000;
    op = OP_ADD;
    check_result(
        32'h40C00000,
        "FPU ADD exp_a < exp_b"
    );

    // exp_a > exp_b with opposite signs:
    // 4.0 + -2.0 = 2.0
    a  = 32'h40800000;
    b  = 32'hC0000000;
    op = OP_ADD;
    check_result(
        32'h40000000,
        "FPU ADD exp_a > exp_b"
    );

    // exp_a < exp_b with opposite signs:
    // 2.0 + -4.0 = -2.0
    a  = 32'h40000000;
    b  = 32'hC0800000;
    op = OP_ADD;
    check_result(
        32'hC0000000,
        "FPU ADD exp_a < exp_b opposite sign"
    );

    // Equal exponent, mant_a >= mant_b:
    // 1.5 + -1.0 = 0.5
    a  = 32'h3FC00000;
    b  = 32'hBF800000;
    op = OP_ADD;
    check_result(
        32'h3F000000,
        "FPU ADD mant_a >= mant_b"
    );

    // Equal exponent, mant_a < mant_b:
    // 1.0 + -1.5 = -0.5
    a  = 32'h3F800000;
    b  = 32'hBFC00000;
    op = OP_ADD;
    check_result(
        32'hBF000000,
        "FPU ADD mant_a < mant_b"
    );

    // Exact cancellation: 2.0 + -2.0 = 0.0
    a  = 32'h40000000;
    b  = 32'hC0000000;
    op = OP_ADD;
    check_result(
        32'h00000000,
        "FPU ADD exact cancellation"
    );


    // ============================================================
    // Zero and special-case coverage
    // ============================================================

    // ADD: 0.0 + 3.0 = 3.0
    a  = 32'h00000000;
    b  = 32'h40400000;
    op = OP_ADD;
    check_result(
        32'h40400000,
        "FPU ADD 0.0 + 3.0"
    );

    // ADD: 3.0 + 0.0 = 3.0
    a  = 32'h40400000;
    b  = 32'h00000000;
    op = OP_ADD;
    check_result(
        32'h40400000,
        "FPU ADD 3.0 + 0.0"
    );

    // SUB: 3.0 - 0.0 = 3.0
    a  = 32'h40400000;
    b  = 32'h00000000;
    op = OP_SUB;
    check_result(
        32'h40400000,
        "FPU SUB 3.0 - 0.0"
    );

    // SUB: 0.0 - 3.0 = -3.0
    a  = 32'h00000000;
    b  = 32'h40400000;
    op = OP_SUB;
    check_result(
        32'hC0400000,
        "FPU SUB 0.0 - 3.0"
    );

    // MUL: 3.0 * 0.0 = 0.0
    a  = 32'h40400000;
    b  = 32'h00000000;
    op = OP_MUL;
    check_result(
        32'h00000000,
        "FPU MUL 3.0 * 0.0"
    );

    // MUL: 0.0 * 3.0 = 0.0
    a  = 32'h00000000;
    b  = 32'h40400000;
    op = OP_MUL;
    check_result(
        32'h00000000,
        "FPU MUL 0.0 * 3.0"
    );

    // MUL: 0.0 * 0.0 = 0.0
    a  = 32'h00000000;
    b  = 32'h00000000;
    op = OP_MUL;
    check_result(
        32'h00000000,
        "FPU MUL 0.0 * 0.0"
    );

    // DIV: 4.0 / 0.0 = +infinity
    a  = 32'h40800000;
    b  = 32'h00000000;
    op = OP_DIV;
    check_result(
        32'h7F800000,
        "FPU DIV 4.0 / 0.0"
    );

    // DIV: 0.0 / 4.0 = 0.0
    a  = 32'h00000000;
    b  = 32'h40800000;
    op = OP_DIV;
    check_result(
        32'h00000000,
        "FPU DIV 0.0 / 4.0"
    );


    // ============================================================
    // MUL invalid operation: infinity * zero
    // ============================================================

    // +Inf * +0 = NaN
    a  = 32'h7F800000;
    b  = 32'h00000000;
    op = OP_MUL;
    check_result(
        32'h7FC00000,
        "FPU MUL +Inf * +0"
    );

    // +0 * +Inf = NaN
    a  = 32'h00000000;
    b  = 32'h7F800000;
    op = OP_MUL;
    check_result(
        32'h7FC00000,
        "FPU MUL +0 * +Inf"
    );

    // -Inf * +0 = NaN
    a  = 32'hFF800000;
    b  = 32'h00000000;
    op = OP_MUL;
    check_result(
        32'h7FC00000,
        "FPU MUL -Inf * +0"
    );

    // +0 * -Inf = NaN
    a  = 32'h00000000;
    b  = 32'hFF800000;
    op = OP_MUL;
    check_result(
        32'h7FC00000,
        "FPU MUL +0 * -Inf"
    );


    // ============================================================
    // SUB signed-zero coverage
    // ============================================================

    // SUB: 3.0 - (-0.0) = 3.0
    a  = 32'h40400000;
    b  = 32'h80000000;
    op = OP_SUB;
    check_result(
        32'h40400000,
        "FPU SUB 3.0 - (-0.0)"
    );


    // ============================================================
    // ADD subnormal coverage
    // ============================================================

    // Smallest positive subnormal + smallest positive subnormal
    // = 0x00000002
    a  = 32'h00000001;
    b  = 32'h00000001;
    op = OP_ADD;
    check_result(
        32'h00000002,
        "FPU ADD subnormal + subnormal"
    );

    // Subnormal subtraction path:
    // 2^-148 - 2^-149 = 2^-149
    a  = 32'h00000002;
    b  = 32'h80000001;
    op = OP_ADD;
    check_result(
        32'h00000001,
        "FPU ADD subnormal opposite sign"
    );

    // Smallest normal - largest subnormal.
    //
    // 0x00800000 - 0x007FFFFF = 0x00000001
    a  = 32'h00800000;
    b  = 32'h007FFFFF;
    op = OP_SUB;
    check_result(
        32'h00000001,
        "FPU SUB smallest normal - largest subnormal"
    );

    // Smallest normal result via subtraction:
    // 2^-125 - 2^-126 = 2^-126
    a  = 32'h01000000;
    b  = 32'h00800000;
    op = OP_SUB;
    check_result(
        32'h00800000,
        "FPU SUB smallest normal result"
    );


    // ============================================================
    // ADD overflow
    // ============================================================

    // MAX finite + MAX finite = +infinity
    a  = 32'h7F7FFFFF;
    b  = 32'h7F7FFFFF;
    op = OP_ADD;
    check_result(
        32'h7F800000,
        "FPU ADD overflow"
    );


    // ============================================================
    // SUB overflow
    // ============================================================

    // MAX finite - (-MAX finite) = +infinity
    a  = 32'h7F7FFFFF;
    b  = 32'hFF7FFFFF;
    op = OP_SUB;
    check_result(
        32'h7F800000,
        "FPU SUB overflow"
    );


    // ============================================================
    // ADD rounding carry boundary
    // ============================================================

    a  = 32'h7EFFFFFF;
    b  = 32'h73400001;
    op = OP_ADD;
    check_result(
        32'h7F000000,
        "FPU ADD rounding carry boundary"
    );


    // ============================================================
    // ADD explicit mant_rounded_ext[24] carry coverage
    // ============================================================

    // 0x3FFFFFFF = 2.0 - 2^-24
    // 0x33800000 = 2^-24
    //
    // Therefore:
    //
    //     (2.0 - 2^-24) + 2^-24 = 2.0
    //
    // This targets:
    //
    //     if (mant_rounded_ext[24]) begin
    //
    a  = 32'h3FFFFFFF;
    b  = 32'h33800000;
    op = OP_ADD;
    check_result(
        32'h40000000,
        "FPU ADD explicit rounding carry mant_rounded_ext[24]"
    );


    // ============================================================
    // Invalid opcode coverage
    // ============================================================

    a  = 32'h3F800000;
    b  = 32'h40000000;
    op = 3'b100;

    check_result(
        32'h00000000,
        "FPU invalid opcode"
    );


    // ============================================================
    // MUL normalization coverage
    // ============================================================

    // product[47] == 0
    // 1.0 * 1.0 = 1.0
    a  = 32'h3F800000;
    b  = 32'h3F800000;
    op = OP_MUL;
    check_result(
        32'h3F800000,
        "FPU MUL normalization (product[47]==0)"
    );

    // product[47] == 1
    // 1.5 * 1.5 = 2.25
    a  = 32'h3FC00000;
    b  = 32'h3FC00000;
    op = OP_MUL;
    check_result(
        32'h40100000,
        "FPU MUL normalization (product[47]==1)"
    );


    // ============================================================
    // MUL rounding overflow
    // ============================================================

    a  = 32'h3FFFFFFE;
    b  = 32'h3F800001;
    op = OP_MUL;
    check_result(
        32'h40000000,
        "FPU MUL rounding overflow"
    );


    // ============================================================
    // MUL overflow
    // ============================================================

    // MAX finite * 2.0 = +infinity
    a  = 32'h7F7FFFFF;
    b  = 32'h40000000;
    op = OP_MUL;
    check_result(
        32'h7F800000,
        "FPU MUL overflow"
    );


    // ============================================================
    // MUL subnormal-path coverage
    // ============================================================

    // ------------------------------------------------------------
    // NEW TARGET 1:
    // subnormal_shift < 48 + rounding increment
    // ------------------------------------------------------------

    // NOTE:
    //
    // The previously suggested:
    //
    //     0x10000000 * 0x10000003
    //
    // does NOT produce subnormal_shift == 25.
    //
    // The corrected vector below keeps the exponent product at
    // the required boundary and introduces enough significand
    // fraction to force rounding upward.
    //
    //     0x20000000 = 2^-63
    //     0x1F800003 ~= 2^-64 * (1 + 3*2^-23)
    //
    // Product is in the subnormal region with:
    //
    //     subnormal_shift = 25
    //
    // and the discarded portion causes:
    //
    //     increment = 1
    //
    // Expected:
    //
    //     0x00400002
    a  = 32'h20000000;
    b  = 32'h1F800003;
    op = OP_MUL;
    check_result(
        32'h00400002,
        "FPU MUL subnormal shift<48 rounding increment"
    );


    // ------------------------------------------------------------
    // Existing shift-25 exact subnormal case
    // ------------------------------------------------------------

    // 2^-63 * 2^-64 = 2^-127
    //
    // This gives:
    //
    //     subnormal_shift = 25
    //
    // and exercises the shift/guard/round/sticky path.
    a  = 32'h20000000;
    b  = 32'h1F800000;
    op = OP_MUL;
    check_result(
        32'h00400000,
        "FPU MUL subnormal shift 25"
    );


    // ------------------------------------------------------------
    // NEW TARGET 2:
    // exact halfway -> ties to even -> zero
    // ------------------------------------------------------------

    // These operands produce exactly:
    //
    //     2^-150
    //
    // which is halfway between:
    //
    //     0
    //
    // and:
    //
    //     2^-149
    //
    // Under round-to-nearest-even the result is zero.
    //
    // This specifically targets:
    //
    //     subnormal_shift == 48
    //
    // with:
    //
    //     increment = 0
    //
    a  = 32'h1A000000;
    b  = 32'h1A000000;
    op = OP_MUL;
    check_result(
        32'h00000000,
        "FPU MUL subnormal exact halfway"
    );


    // ------------------------------------------------------------
    // NEW TARGET 3:
    // halfway + sticky -> round upward
    // ------------------------------------------------------------

    // This is slightly greater than 2^-150.
    //
    // Therefore:
    //
    //     guard  = 1
    //     sticky = 1
    //     increment = 1
    //
    // Result must become the smallest positive subnormal.
    a  = 32'h1A000001;
    b  = 32'h1A000000;
    op = OP_MUL;
    check_result(
        32'h00000001,
        "FPU MUL subnormal halfway plus sticky"
    );


    // ------------------------------------------------------------
    // Existing explicit subnormal rounding-bit path
    // ------------------------------------------------------------

    // Same shift-25 case, explicitly documenting the
    // guard/round/sticky extraction path.
    a  = 32'h20000000;
    b  = 32'h1F800000;
    op = OP_MUL;
    check_result(
        32'h00400000,
        "FPU MUL subnormal guard-round-sticky path"
    );


    // ------------------------------------------------------------
    // Very small result: subnormal_shift == 48
    // ------------------------------------------------------------

    // Smallest positive subnormal * 0.5
    //
    //     2^-149 * 2^-1 = 2^-150
    //
    // Exact halfway point.
    a  = 32'h00000001;
    b  = 32'h3F000000;
    op = OP_MUL;
    check_result(
        32'h00000000,
        "FPU MUL exact halfway underflow"
    );


    // ------------------------------------------------------------
    // Very small result: subnormal_shift == 48, round upward
    // ------------------------------------------------------------

    // Smallest positive subnormal * value slightly greater
    // than 0.5.
    a  = 32'h00000001;
    b  = 32'h3F000001;
    op = OP_MUL;
    check_result(
        32'h00000001,
        "FPU MUL underflow rounding up"
    );


    // ------------------------------------------------------------
    // Very small result: subnormal_shift > 48
    // ------------------------------------------------------------

    // Smallest positive subnormal * 0.25
    //
    //     2^-149 * 2^-2 = 2^-151
    //
    // Must round to zero.
    a  = 32'h00000001;
    b  = 32'h3E800000;
    op = OP_MUL;
    check_result(
        32'h00000000,
        "FPU MUL very small underflow shift > 48"
    );


    // ------------------------------------------------------------
    // NEW TARGET 4:
    // subnormal -> normal boundary
    // ------------------------------------------------------------

    // Smallest normal * largest float below 1.0.
    //
    //     0x00800000 = smallest normal
    //     0x3F7FFFFF = 1.0 - 2^-24
    //
    // The exact product is just below the smallest normal,
    // but rounds to:
    //
    //     0x00800000
    //
    // This targets:
    //
    //     if (rounded_sig >= 24'h800000)
    //
    a  = 32'h00800000;
    b  = 32'h3F7FFFFF;
    op = OP_MUL;
    check_result(
        32'h00800000,
        "FPU MUL smallest normal boundary"
    );


    // ------------------------------------------------------------
    // Existing subnormal -> normal boundary
    // ------------------------------------------------------------

    // Largest subnormal * (1 + 2^-23)
    //
    // Expected to round to the smallest normal.
    a  = 32'h007FFFFF;
    b  = 32'h3F800001;
    op = OP_MUL;
    check_result(
        32'h00800000,
        "FPU MUL subnormal rounds to smallest normal"
    );


    // ============================================================
    // DIV overflow
    // ============================================================

    // MAX finite / 0.5 = +infinity
    a  = 32'h7F7FFFFF;
    b  = 32'h3F000000;
    op = OP_DIV;
    check_result(
        32'h7F800000,
        "FPU DIV overflow"
    );


    // ============================================================
    // DIV subnormal-path coverage
    // ============================================================

    // ------------------------------------------------------------
    // NEW / TARGETED:
    // normal -> subnormal quotient path
    // ------------------------------------------------------------

    // Smallest normal / 2.0
    //
    //     2^-126 / 2 = 2^-127
    //
    // Result:
    //
    //     0x00400000
    //
    // This targets the branch:
    //
    //     if (shift_cnt >= QWIDTH)
    //
    // FALSE
    //
    // and therefore enters:
    //
    //     else begin
    //         sig_raw = quotient >> shift_cnt;
    //     end
    //
    // The guard/round/sticky path is exercised as well.
    a  = 32'h00800000;
    b  = 32'h40000000;
    op = OP_DIV;
    check_result(
        32'h00400000,
        "FPU DIV subnormal quotient path"
    );


    // ------------------------------------------------------------
    // Explicit second subnormal division
    // ------------------------------------------------------------

    // 2^-126 / 4.0 = 2^-128
    //
    // Another subnormal result with a different shift amount.
    a  = 32'h00800000;
    b  = 32'h40800000;
    op = OP_DIV;
    check_result(
        32'h00200000,
        "FPU DIV deeper subnormal"
    );


    // ------------------------------------------------------------
    // DIV subnormal rounding candidate
    // ------------------------------------------------------------

    // Slightly above smallest normal / 2.
    //
    // This is useful for exercising the rounding extraction
    // in the subnormal division path.
    a  = 32'h00800001;
    b  = 32'h40000000;
    op = OP_DIV;
    check_result(
        32'h00400000,
        "FPU DIV subnormal rounding"
    );


    // ------------------------------------------------------------
    // Extreme DIV underflow
    // ------------------------------------------------------------

    // Smallest positive subnormal / maximum finite
    //
    // Far below representable range -> zero.
    a  = 32'h00000001;
    b  = 32'h7F7FFFFF;
    op = OP_DIV;
    check_result(
        32'h00000000,
        "FPU DIV extreme underflow"
    );


    // ============================================================
    // Final verification result
    // ============================================================

    if (errors == 0) begin
        $display("");
        $display("========================================");
        $display("FPU VERIFICATION PASSED");
        $display("========================================");
    end
    else begin
        $display("");
        $display(
            "FPU VERIFICATION FAILED: %0d errors",
            errors
        );
        $display("========================================");
    end

    // Stop the simulation and return control
    // to the Questa Tcl command sequence.
    $stop;

end

endmodule