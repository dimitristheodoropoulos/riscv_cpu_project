interface alu_if (input logic clk);
  logic [31:0] a;
  logic [31:0] b;
  logic [3:0]  alu_control;
  logic [31:0] result;
  logic        zero;
  logic        overflow;
endinterface