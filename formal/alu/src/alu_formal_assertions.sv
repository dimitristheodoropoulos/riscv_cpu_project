module alu_assertions (
    input clk,
    input [31:0] A, B, Result,
    input [3:0]  Op,
    input        zero,
    input        overflow
);

  always @(posedge clk) begin
    assert (!(Result == 32'b0) || zero);
    assert (!(Result != 32'b0) || !zero);
    assert (!overflow || (Op == 4'b0010 || Op == 4'b0110));
    assert ((Op == 4'b0000 || Op == 4'b0001 || Op == 4'b0010 || Op == 4'b0011 ||
             Op == 4'b0100 || Op == 4'b0101 || Op == 4'b0110 || Op == 4'b0111)
            || (Result == 32'b0));
  end

endmodule
