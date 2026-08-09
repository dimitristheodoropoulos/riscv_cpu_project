module cu_assertions (
    input clk,
    input [31:0] instruction,
    input [3:0]  ALU_op,
    input [4:0]  rs1, rs2, rd,
    input        mem_read,
    input        mem_write,
    input        reg_write
);

  wire [6:0] opcode = instruction[6:0];

  // --------------------------------------------------------------------------
  // Memory control signals must never be active simultaneously.
  //
  // The CU is combinational, while the assertions are sampled on posedge clk.
  // Disable the check while the opcode/control inputs are unknown.
  // --------------------------------------------------------------------------
  property p_mem_mutex;
    @(posedge clk)
      !$isunknown({opcode, mem_read, mem_write}) |->
      !(mem_read && mem_write);
  endproperty

  a_mem_mutex: assert property (p_mem_mutex)
    else $error("SVA: mem_read and mem_write active simultaneously");


  // --------------------------------------------------------------------------
  // Load instruction:
  // opcode = 0000011
  // Expected:
  //   mem_read  = 1
  //   mem_write = 0
  //   reg_write = 1
  // --------------------------------------------------------------------------
  property p_load_signals;
    @(posedge clk)
      !$isunknown(opcode) &&
      (opcode == 7'b0000011)
      |->
      (mem_read && !mem_write && reg_write);
  endproperty

  a_load_signals: assert property (p_load_signals)
    else $error("SVA: Load opcode did not produce correct control signals");


  // --------------------------------------------------------------------------
  // Store instruction:
  // opcode = 0100011
  // Expected:
  //   mem_write = 1
  //   mem_read  = 0
  //   reg_write = 0
  // --------------------------------------------------------------------------
  property p_store_signals;
    @(posedge clk)
      !$isunknown(opcode) &&
      (opcode == 7'b0100011)
      |->
      (mem_write && !mem_read && !reg_write);
  endproperty

  a_store_signals: assert property (p_store_signals)
    else $error("SVA: Store opcode did not produce correct control signals");


  // --------------------------------------------------------------------------
  // R-type instruction:
  // opcode = 0110011
  // Expected:
  //   reg_write = 1
  //   mem_read  = 0
  //   mem_write = 0
  // --------------------------------------------------------------------------
  property p_rtype_signals;
    @(posedge clk)
      !$isunknown(opcode) &&
      (opcode == 7'b0110011)
      |->
      (reg_write && !mem_read && !mem_write);
  endproperty

  a_rtype_signals: assert property (p_rtype_signals)
    else $error("SVA: R-type opcode did not produce correct control signals");


  // --------------------------------------------------------------------------
  // Register fields must not contain X/Z for supported instructions.
  //
  // R-type : rs1, rs2, rd are used
  // Load   : rs1, rd are used
  // Store  : rs1, rs2 are used
  // --------------------------------------------------------------------------
  property p_reg_fields_known;
    @(posedge clk)
      !$isunknown(opcode) &&
      (opcode inside {
        7'b0110011,
        7'b0000011,
        7'b0100011
      })
      |->
      (!$isunknown(rs1) &&
       !$isunknown(rs2) &&
       !$isunknown(rd));
  endproperty

  a_reg_fields_known: assert property (p_reg_fields_known)
    else $error("SVA: register fields contain X/Z for a known opcode");


endmodule