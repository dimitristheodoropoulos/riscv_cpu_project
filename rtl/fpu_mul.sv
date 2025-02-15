module fp_mul (
    input [31:0] a,   // Operand A (IEEE-754 single-precision)
    input [31:0] b,   // Operand B (IEEE-754 single-precision)
    output [31:0] result  // Result of the multiplication
);

    wire sign_a = a[31];
    wire [7:0] exp_a = a[30:23];
    wire [22:0] mant_a = a[22:0];

    wire sign_b = b[31];
    wire [7:0] exp_b = b[30:23];
    wire [22:0] mant_b = b[22:0];

    wire [47:0] mant_mul = {24'b0, mant_a} * {24'b0, mant_b};  // Simplified multiplication
    wire [7:0] exp_mul = exp_a + exp_b - 127;  // Subtract the bias

    assign result = {sign_a ^ sign_b, exp_mul, mant_mul[46:24]};

endmodule
