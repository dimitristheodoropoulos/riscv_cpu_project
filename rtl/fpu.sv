module fpu (
    input        clk,
    input        rst,
    input  [31:0] a,
    input  [31:0] b,
    input  [2:0]  op,
    output reg [31:0] result,
    output reg        ready
);

    wire [31:0] fadd_result;
    wire [31:0] fsub_result;
    wire [31:0] fmul_result;
    wire [31:0] fdiv_result;

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

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            result <= 32'h00000000;
            ready  <= 1'b0;

        end
        else begin

            case (op)

                3'b000: result <= fadd_result;
                3'b001: result <= fsub_result;
                3'b010: result <= fmul_result;
                3'b011: result <= fdiv_result;

                default:
                    result <= 32'h00000000;

            endcase

            ready <= 1'b1;

        end

    end

endmodule