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
    // Exercises exp_result == 1 while mant_diff[23] == 0
    // during subtraction normalization.
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
    // 2^-125 - 2^-126 = 2^-126 (0x00800000)
    // Exercises exp_result == 1 with mant_diff[23] == 1
    // (the normal-number boundary).
    a  = 32'h01000000;
    b  = 32'h00800000;
    op = OP_SUB;
    check_result(
        32'h00800000,
        "FPU SUB smallest normal result"
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

    // MUL normalization path: mant_product[47] == 0
    // 1.0 * 1.0 = 1.0
    a  = 32'h3F800000;
    b  = 32'h3F800000;
    op = OP_MUL;
    check_result(
        32'h3F800000,
        "FPU MUL normalization (mant_product[47]==0)"
    );

    // MUL normalization path: mant_product[47] == 1
    // 1.5 * 1.5 = 2.25
    a  = 32'h3FC00000;
    b  = 32'h3FC00000;
    op = OP_MUL;
    check_result(
        32'h40100000,
        "FPU MUL normalization (mant_product[47]==1)"
    );

    // ============================================================
    // MUL rounding overflow: rounded_sig_ext[24] == 1
    // ============================================================

    // This vector provokes the branch:
    //   if (rounded_sig_ext[24]) begin
    // in fp_mul.sv line ~251.
    //
    // a = 0x3FFFFFFE = 1.11111111111111111111110 × 2^0
    // b = 0x3F800001 = 1.00000000000000000000001 × 2^0
    // Product significand = (2^24-2) * (2^23+1) = 2^47 - 2
    // Normalized product = 2^48 - 4 → norm_product[47:24] = 0xFFFFFF
    // guard=1, round=1, sticky=1, LSB=1 → increment=1
    // rounded_sig_ext = 0x1000000 → rounded_sig_ext[24] = 1
    // Result = 2.0 = 0x40000000
    a  = 32'h3FFFFFFE;
    b  = 32'h3F800001;
    op = OP_MUL;
    check_result(
        32'h40000000,
        "FPU MUL rounding overflow (rounded_sig_ext[24]==1)"
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