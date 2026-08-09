module alu (
    input  [31:0] A,
    input  [31:0] B,
    input  [3:0]  Op,
    output reg [31:0] Result,
    output            zero,
    output            overflow
);

    reg overflow_int;

    always @(*) begin
        overflow_int = 1'b0;
        case (Op)
            4'b0010: begin // ADD
                Result = A + B;
                overflow_int = (A[31] == B[31]) && (Result[31] != A[31]);
            end
            4'b0110: begin // SUB
                Result = A - B;
                overflow_int = (A[31] != B[31]) && (Result[31] != A[31]);
            end
            4'b0000: Result = A & B;                                   // AND
            4'b0001: Result = A | B;                                   // OR
            4'b0111: Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; // SLT
            4'b0011: Result = A ^ B;                                   // XOR
            4'b0100: Result = A << B[4:0];                             // SLL
            4'b0101: Result = $signed(A) >>> B[4:0];                   // SRA
            default: Result = 32'b0;
        endcase
    end

    assign zero     = (Result == 32'b0);
    assign overflow = overflow_int;

endmodule