module alu_assertions (
    input clk,
    input [31:0] A, B, Result,
    input [3:0]  Op,
    input        zero,
    input        overflow
);

  // zero flag πρέπει πάντα να είναι συνεπές με το Result
  always @(posedge clk)
    if (!$isunknown(Result))
      assert property (Result == 32'b0 |-> zero);

  always @(posedge clk)
    if (!$isunknown(Result))
      assert property (Result != 32'b0 |-> !zero);

  // overflow επιτρέπεται μόνο για ADD (0010) ή SUB (0110)
  always @(posedge clk)
    if (!$isunknown(Op))
      assert property (overflow |-> (Op == 4'b0010 || Op == 4'b0110));

  // Result δεν πρέπει να είναι X όταν A, B, Op είναι γνωστά
  always @(posedge clk)
    if (!$isunknown(A) && !$isunknown(B) && !$isunknown(Op))
      assert property (!$isunknown(Result));

  // κάθε γνωστό, μη έγκυρο opcode πρέπει να παράγει Result=0
  always @(posedge clk)
    if (!$isunknown(Op) &&
        !(Op inside {4'b0000,4'b0001,4'b0010,4'b0011,4'b0100,4'b0101,4'b0110,4'b0111}))
      assert property (Result == 32'b0);

endmodule