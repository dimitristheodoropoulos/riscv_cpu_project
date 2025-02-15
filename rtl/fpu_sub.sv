module fp_sub (
    input [31:0] a,   // Operand A (IEEE-754 single-precision)
    input [31:0] b,   // Operand B (IEEE-754 single-precision)
    output [31:0] result  // Result of the subtraction
);

    wire [31:0] b_neg = {~b[31], b[30:0]};  // Invert the sign bit for subtraction

    fp_add add_op (
        .a(a),
        .b(b_neg),
        .result(result)
    );

endmodule
