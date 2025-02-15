module fp_div (
    input [31:0] a,   // Operand A (IEEE-754 single-precision)
    input [31:0] b,   // Operand B (IEEE-754 single-precision)
    output reg [31:0] result  // Result of the division
);

    wire sign_a = a[31];
    wire [7:0] exp_a = a[30:23];
    wire [22:0] mant_a = a[22:0];

    wire sign_b = b[31];
    wire [7:0] exp_b = b[30:23];
    wire [22:0] mant_b = b[22:0];

    wire div_by_zero = (b == 32'b0); // Check for division by zero

    wire [7:0] exp_div = exp_a - exp_b + 127; // Adjust exponent

    // Normalize mantissas (adding implicit leading 1 for normalized numbers)
    wire [23:0] norm_mant_a = |exp_a ? {1'b1, mant_a} : {1'b0, mant_a};  
    wire [23:0] norm_mant_b = |exp_b ? {1'b1, mant_b} : {1'b0, mant_b};  

    // Perform division on mantissas (normalized)
    wire [23:0] mant_div = (norm_mant_b != 0) ? (norm_mant_a << 23) / norm_mant_b : 24'b0;  

    // Check if result is denormalized
    wire [22:0] final_mant = mant_div[23] ? mant_div[22:0] : mant_div[21:0];

    // Handle special cases: NaN, Infinity, Zero
    always @(*) begin
        if (div_by_zero) 
            result = {sign_a ^ sign_b, 8'hFF, 23'h0};  // Infinity
        else if (b == a)  
            result = 32'h3F800000; // 1.0 in IEEE-754
        else
            result = {sign_a ^ sign_b, exp_div, final_mant};
    end

endmodule