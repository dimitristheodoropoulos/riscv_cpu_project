module fpu (
    input clk,
    input rst,
    input [31:0] a,   // Operand A (IEEE-754 single-precision)
    input [31:0] b,   // Operand B (IEEE-754 single-precision)
    input [2:0] op,   // Operation code (000 = ADD, 001 = SUB, 010 = MUL, 011 = DIV)
    output reg [31:0] result,  // Result of operation
    output reg ready           // Ready signal (operation complete)
);

    // Signals for operations
    wire [31:0] fadd_result, fsub_result, fmul_result, fdiv_result;

    // Instantiate the floating-point operation modules
    fp_add add_op (
        .a(a),
        .b(b),
        .result(fadd_result)
    );

    fp_sub sub_op (
        .a(a),
        .b(b),
        .result(fsub_result)
    );

    fp_mul mul_op (
        .a(a),
        .b(b),
        .result(fmul_result)
    );

    fp_div div_op (
        .a(a),
        .b(b),
        .result(fdiv_result)
    );

    // Control logic to select the operation based on the op input
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result <= 32'b0;
            ready <= 0;
        end else begin
            case (op)
                3'b000: result <= fadd_result;
                3'b001: result <= fsub_result;
                3'b010: result <= fmul_result;
                3'b011: result <= fdiv_result;
                default: result <= 32'b0;
            endcase
            ready <= 1;
        end
    end

endmodule
