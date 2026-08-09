module cu_assertions (
    input clk,
    input [31:0] instruction,
    input [3:0]  ALU_op,
    input [4:0]  rs1, rs2, rd,
    input        mem_read, mem_write, reg_write
);

  wire [6:0] opcode = instruction[6:0];

  // mem_read και mem_write ποτέ ταυτόχρονα ενεργά
  property p_mem_mutex;
    @(posedge clk) disable iff ($isunknown(opcode))
      !(mem_read && mem_write);
  endproperty
  a_mem_mutex: assert property (p_mem_mutex)
    else $error("SVA: mem_read και mem_write ενεργά ταυτόχρονα");

  // Load (0000011) -> mem_read ενεργό, mem_write ανενεργό
  property p_load_signals;
    @(posedge clk) disable iff ($isunknown(opcode))
      (opcode == 7'b0000011) |-> (mem_read && !mem_write && reg_write);
  endproperty
  a_load_signals: assert property (p_load_signals)
    else $error("SVA: Load opcode δεν παρήγαγε σωστά control signals");

  // Store (0100011) -> mem_write ενεργό, mem_read/reg_write ανενεργά
  property p_store_signals;
    @(posedge clk) disable iff ($isunknown(opcode))
      (opcode == 7'b0100011) |-> (mem_write && !mem_read && !reg_write);
  endproperty
  a_store_signals: assert property (p_store_signals)
    else $error("SVA: Store opcode δεν παρήγαγε σωστά control signals");

  // R-type (0110011) -> reg_write ενεργό, mem_read/mem_write ανενεργά
  property p_rtype_signals;
    @(posedge clk) disable iff ($isunknown(opcode))
      (opcode == 7'b0110011) |-> (reg_write && !mem_read && !mem_write);
  endproperty
  a_rtype_signals: assert property (p_rtype_signals)
    else $error("SVA: R-type opcode δεν παρήγαγε σωστά control signals");

  // rs1/rs2/rd πάντα valid 5-bit register index (no X) όταν το opcode είναι γνωστό
  property p_reg_fields_known;
    @(posedge clk) disable iff ($isunknown(opcode))
      opcode inside {7'b0110011, 7'b0000011, 7'b0100011}
      |-> (!$isunknown(rs1) && !$isunknown(rd));
  endproperty
  a_reg_fields_known: assert property (p_reg_fields_known)
    else $error("SVA: rs1/rd είναι X για γνωστό opcode");

endmodule