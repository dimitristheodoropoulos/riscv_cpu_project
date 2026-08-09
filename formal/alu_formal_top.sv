module alu_formal_top (
    input clk,
    input [31:0] A, B,
    input [3:0]  Op,
    output [31:0] Result,
    output        zero,
    output        overflow
);

  alu dut (.A(A), .B(B), .Op(Op), .Result(Result), .zero(zero), .overflow(overflow));

  alu_assertions sva_check (
      .clk(clk), .A(A), .B(B), .Result(Result), .Op(Op), .zero(zero), .overflow(overflow)
  );

endmodule