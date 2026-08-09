import uvm_pkg::*;
`include "uvm_macros.svh"

class cu_random_sequence extends uvm_sequence #(cu_transaction);
  `uvm_object_utils(cu_random_sequence)

  function new(string name = "cu_random_sequence");
    super.new(name);
  endfunction

  // R-type: τυχαία rs1/rs2/rd, τυχαία επιλογή ανάμεσα σε ADD/SUB/AND/OR/SLT
  function logic [31:0] build_r_type();
    logic [4:0] rs1, rs2, rd;
    logic [2:0] funct3;
    logic       funct7_5;
    logic [2:0] funct3_choices[4] = '{3'b000, 3'b111, 3'b110, 3'b010};
    rs1      = $urandom_range(0, 31);
    rs2      = $urandom_range(0, 31);
    rd       = $urandom_range(0, 31);
    funct3   = funct3_choices[$urandom_range(0, 3)];
    funct7_5 = $urandom_range(0, 1);
    return {(funct7_5 ? 7'b0100000 : 7'b0000000), rs2, rs1, funct3, rd, 7'b0110011};
  endfunction

  function logic [31:0] build_load();
    logic [4:0]  rs1, rd;
    logic [11:0] imm;
    rs1 = $urandom_range(0, 31);
    rd  = $urandom_range(0, 31);
    imm = $urandom_range(0, 4095);
    return {imm, rs1, 3'b010, rd, 7'b0000011}; // LW
  endfunction

  function logic [31:0] build_store();
    logic [4:0]  rs1, rs2;
    logic [11:0] imm;
    rs1 = $urandom_range(0, 31);
    rs2 = $urandom_range(0, 31);
    imm = $urandom_range(0, 4095);
    return {imm[11:5], rs2, rs1, 3'b010, imm[4:0], 7'b0100011}; // SW
  endfunction

  task body();
    logic [31:0] instr;
    int kind;
    repeat (100) begin
      req = cu_transaction::type_id::create("req");
      start_item(req);
      kind = $urandom_range(0, 2); // 0=R-type, 1=Load, 2=Store
      case (kind)
        0: instr = build_r_type();
        1: instr = build_load();
        2: instr = build_store();
      endcase
      req.instruction = instr;
      finish_item(req);
    end
  endtask
endclass