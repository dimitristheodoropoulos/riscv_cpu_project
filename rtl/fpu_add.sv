module fp_add (
    input [31:0] a,   // Operand A (IEEE-754 single-precision)
    input [31:0] b,   // Operand B (IEEE-754 single-precision)
    output [31:0] result  // Result of the addition
);

    wire sign_a = a[31];
    wire [7:0] exp_a = a[30:23];
    wire [22:0] mant_a = a[22:0];

    wire sign_b = b[31];
    wire [7:0] exp_b = b[30:23];
    wire [22:0] mant_b = b[22:0];

    wire [24:0] mant_a_norm = {1'b1, mant_a};
    wire [24:0] mant_b_norm = {1'b1, mant_b};

    wire [24:0] mant_result = mant_a_norm + mant_b_norm;
    wire [7:0] exp_result = exp_a;  // Simplified, needs proper exponent handling

    assign result = {sign_a, exp_result, mant_result[22:0]};

endmodule
