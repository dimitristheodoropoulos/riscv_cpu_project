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

    // This specifically targets:
    //
    //     else if ((a_is_inf && b_is_zero) ||
    //              (b_is_inf && a_is_zero))
    //
    // in rtl/fpu_mul.sv line 179.
    //
    // IEEE-754:
    //
    //     infinity * zero = NaN
    //
    // The RTL returns canonical quiet NaN.

    // +Inf * +0 = NaN
    a  = 32'h7F800000;
    b  = 32'h00000000;
    op = OP_MUL;
    check_result(
        32'h7FC00000,
        "FPU MUL +Inf * +0"
    );

    // +0 * +Inf = NaN
    //
    // Exercises the opposite side of the OR condition.
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
    // = 0x00000002 (still subnormal)
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
    //
    // Exercises exp_result == 1 while mant_diff[23] == 0
    // during subtraction normalization.
    a  = 32'h00800000;
    b  = 32'h007FFFFF;
    op = OP_SUB;
    check_result(
        32'h00000001,
        "FPU SUB smallest normal - largest subnormal"
    );

    // Smallest normal result via subtraction:
    // 2^-125 - 2^-126 = 2^-126 (0x00800000)
    //
    // Exercises exp_result == 1 with mant_diff[23] == 1
    // at the normal-number boundary.
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
    //
    // 0x7F7FFFFF = maximum finite positive binary32 value.
    //
    // This forces the exponent overflow path in fp_add.sv.
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
    //
    // 0x7F7FFFFF - 0xFF7FFFFF
    //
    // Since fp_sub.sv implements subtraction as:
    //
    //     a + (-b)
    //
    // the second operand becomes +MAX finite and the ADD
    // datapath produces an exponent overflow.
    //
    // This specifically targets the previously uncovered
    // branch at rtl/fpu_add.sv line 582 in the
    // /fpu_tb/dut/sub_op/add_op instance:
    //
    //     if (exp_result >= 8'hFF)
    //
    // Expected:
    //
    //     +infinity = 0x7F800000
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

    // Existing targeted vector for the ADD rounding boundary.
    //
    // The rounded significand reaches the exponent boundary,
    // exercising the carry/normalization path after rounding.
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

    // Target the exact branch:
    //
    //     if (mant_rounded_ext[24]) begin
    //
    // in rtl/fpu_add.sv line 553.
    //
    // Mathematical values:
    //
    //     0x3FFFFFFF = 2.0 - 2^-24
    //     0x33800000 = 2^-24
    //
    // Therefore:
    //
    //     (2.0 - 2^-24) + 2^-24 = 2.0
    //
    // The smaller operand is shifted by 24 positions.
    // Its G bit becomes 1 while R/S are 0.
    //
    // The larger significand has LSB = 1, so:
    //
    //     round_up = G && (R || S || LSB)
    //              = 1 && (0 || 0 || 1)
    //              = 1
    //
    // Thus:
    //
    //     0xFFFFFF + 1 = 0x1000000
    //
    // which sets mant_rounded_ext[24].
    //
    // This must execute the rounding-carry branch and produce
    // the normalized result 2.0 = 0x40000000.

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

    // Invalid opcode: 100 should select the default case
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

    // MUL normalization path: product[47] == 0
    // 1.0 * 1.0 = 1.0
    a  = 32'h3F800000;
    b  = 32'h3F800000;
    op = OP_MUL;
    check_result(
        32'h3F800000,
        "FPU MUL normalization (product[47]==0)"
    );

    // MUL normalization path: product[47] == 1
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

    // This vector provokes the rounded significand overflow path.
    //
    // a = 0x3FFFFFFE
    // b = 0x3F800001
    //
    // The exact product is just below the 2.0 boundary and
    // rounds upward to 2.0 under round-to-nearest-even.
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
    //
    // 0x7F7FFFFF = maximum finite positive binary32 value
    // 0x40000000 = 2.0
    //
    // This forces the exponent overflow path.
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
    // Subnormal result with subnormal_shift == 25
    // ------------------------------------------------------------

    // 2^-63 * 2^-64 = 2^-127
    //
    // Encodings:
    //
    //     2^-63 = 0x20000000
    //     2^-64 = 0x1F800000
    //
    // This exercises the subnormal path with a large shift.
    a  = 32'h20000000;
    b  = 32'h1F800000;
    op = OP_MUL;
    check_result(
        32'h00400000,
        "FPU MUL subnormal shift 25"
    );


    // ------------------------------------------------------------
    // Explicit coverage of subnormal rounding-bit branches
    // ------------------------------------------------------------

    // This again uses subnormal_shift == 25 and therefore
    // explicitly exercises:
    //
    //     if (subnormal_shift > 0)
    //     if (subnormal_shift >= 2)
    //     if (subnormal_shift >= 3)
    //
    // in rtl/fpu_mul.sv.
    //
    // Expected result remains 2^-127.

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
    // This is the exact halfway point between zero and the
    // smallest positive subnormal.
    //
    // RNE chooses zero because zero is even.
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

    // Smallest positive subnormal multiplied by a value slightly
    // greater than 0.5.
    //
    // RNE must produce the smallest positive subnormal.
    a  = 32'h00000001;
    b  = 32'h3F000001;
    op = OP_MUL;
    check_result(
        32'h00000001,
        "FPU MUL underflow rounding up"
    );


    // ------------------------------------------------------------
    // Subnormal -> normal boundary
    // ------------------------------------------------------------

    // Largest subnormal * (1 + 2^-23)
    //
    // rounds to the smallest normal number.
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
    //
    // 0x7F7FFFFF = maximum finite positive binary32 value
    // 0x3F000000 = 0.5
    //
    // This specifically targets:
    //
    //     if (exp_unbiased > 14'sd127)
    //
    // at rtl/fpu_div.sv line 274.

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
    // Normal result crossing into subnormal range
    // ------------------------------------------------------------

    // Smallest normal / 2.0
    //
    //     2^-126 / 2 = 2^-127
    //
    // Binary32 encoding:
    //
    //     2^-127 = 0x00400000
    //
    // This enters the subnormal path with:
    //
    //     shift_cnt = 11
    //
    // and therefore exercises:
    //
    //     shift_cnt >= 1
    //     shift_cnt >= 2
    //     shift_cnt >= 3
    //
    // as well as:
    //
    //     i < QWIDTH
    //
    // inside the sticky-bit loop.
    a  = 32'h00800000;
    b  = 32'h40000000;
    op = OP_DIV;
    check_result(
        32'h00400000,
        "FPU DIV normal to subnormal"
    );


    // ------------------------------------------------------------
    // Explicit second subnormal division
    // ------------------------------------------------------------

    // 2^-126 / 4.0 = 2^-128
    //
    // This is another subnormal result and exercises the same
    // guard/round/sticky extraction path with a different
    // shift amount.
    a  = 32'h00800000;
    b  = 32'h40800000;
    op = OP_DIV;
    check_result(
        32'h00200000,
        "FPU DIV deeper subnormal"
    );


    // ------------------------------------------------------------
    // Extreme DIV underflow
    // ------------------------------------------------------------

    // Smallest positive subnormal / maximum finite
    //
    // is far below the smallest representable subnormal and must
    // round to zero.
    //
    // This exercises:
    //
    //     if (shift_cnt >= QWIDTH)
    //
    // at rtl/fpu_div.sv line 303.
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