interface cu_if (input logic clk);
  logic [31:0] instruction;
  logic [3:0]  alu_op;
  logic [4:0]  rs1, rs2, rd;
  logic        is_fp;
  logic        mem_read;
  logic        mem_write;
  logic        reg_write;
  logic [31:0] imm_ext;
endinterface