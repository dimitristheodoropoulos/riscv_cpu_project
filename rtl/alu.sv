module alu (
    input [31:0] A,  // Operand A
    input [31:0] B,  // Operand B
    input [2:0] Op,  // Operation code
    input is_fp,     // Floating-point operation flag
    output reg [31:0] Result  // Result of operation
);

    wire [31:0] fp_result;
    wire [31:0] int_result;
    
    // Integer ALU operations
    always @(*) begin
        case (Op)
            3'b000: int_result = A + B;      // ADD
            3'b001: int_result = A - B;      // SUB
            3'b010: int_result = A & B;      // AND
            3'b011: int_result = A | B;      // OR
            3'b100: int_result = A ^ B;      // XOR
            3'b101: int_result = A << B;     // Shift Left
            3'b110: int_result = A >>> B;    // Shift Right Arithmetic
            default: int_result = 32'b0;     // Default case
        endcase
    end

    // Instantiate the FPU for floating-point operations
    fpu fpu_unit (
        .A(A),
        .B(B),
        .Op(Op),
        .Result(fp_result)
    );

    // Select output based on operation type
    always @(*) begin
        if (is_fp)
            Result = fp_result;
        else
            Result = int_result;
    end

endmodule
