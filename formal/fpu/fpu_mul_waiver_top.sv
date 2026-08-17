module fpu_mul_waiver_top;

    wire [31:0] a = $anyconst;
    wire [31:0] b = $anyconst;
    wire [31:0] result;

    fp_mul dut (
        .a      (a),
        .b      (b),
        .result (result)
    );

endmodule
