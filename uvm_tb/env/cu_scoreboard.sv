import uvm_pkg::*;
`include "uvm_macros.svh"

class cu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(cu_scoreboard)

  uvm_analysis_imp #(cu_transaction, cu_scoreboard) item_collected_export;

  int match_count = 0;
  int mismatch_count = 0;

  function new(string name = "cu_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_collected_export = new("item_collected_export", this);
  endfunction

  function void write(cu_transaction trans);
    logic [6:0]  opcode = trans.instruction[6:0];
    logic [2:0]  funct3 = trans.instruction[14:12];
    logic [6:0]  funct7 = trans.instruction[31:25];

    logic [3:0]  exp_alu_op    = 4'b0000;
    logic [4:0]  exp_rs1       = 5'b0;
    logic [4:0]  exp_rs2       = 5'b0;
    logic [4:0]  exp_rd        = 5'b0;
    logic        exp_mem_read  = 1'b0;
    logic        exp_mem_write = 1'b0;
    logic        exp_reg_write = 1'b0;
    logic [31:0] exp_imm_ext   = 32'b0;

    case (opcode)
      7'b0110011: begin // R-type
        exp_rs1 = trans.instruction[19:15];
        exp_rs2 = trans.instruction[24:20];
        exp_rd  = trans.instruction[11:7];
        exp_reg_write = 1'b1;
        case (funct3)
          3'b000:  exp_alu_op = funct7[5] ? 4'b0110 : 4'b0010; // SUB : ADD
          3'b111:  exp_alu_op = 4'b0000; // AND
          3'b110:  exp_alu_op = 4'b0001; // OR
          3'b010:  exp_alu_op = 4'b0111; // SLT
          default: exp_alu_op = 4'b1111;
        endcase
      end
      7'b0000011: begin // Load (LW)
        exp_rs1      = trans.instruction[19:15];
        exp_rd       = trans.instruction[11:7];
        exp_imm_ext  = {{20{trans.instruction[31]}}, trans.instruction[31:20]};
        exp_mem_read = 1'b1;
        exp_reg_write = 1'b1;
      end
      7'b0100011: begin // Store (SW)
        exp_rs1 = trans.instruction[19:15];
        exp_rs2 = trans.instruction[24:20];
        exp_imm_ext  = {{20{trans.instruction[31]}}, trans.instruction[31:25], trans.instruction[11:7]};
        exp_mem_write = 1'b1;
      end
      default: ; // NOP / unsupported opcode -> όλα defaults (0)
    endcase

    if (trans.alu_op    === exp_alu_op    &&
        trans.rs1       === exp_rs1       &&
        trans.rs2       === exp_rs2       &&
        trans.rd         === exp_rd        &&
        trans.mem_read   === exp_mem_read  &&
        trans.mem_write  === exp_mem_write &&
        trans.reg_write  === exp_reg_write &&
        trans.imm_ext    === exp_imm_ext) begin
      `uvm_info("SCOREBOARD",
        $sformatf("MATCH! instr=%0h opcode=%0b", trans.instruction, opcode),
        UVM_HIGH)
      match_count++;
    end else begin
      `uvm_error("SCOREBOARD",
        $sformatf("MISMATCH! instr=%0h | Got: ALUop=%0b rs1=%0d rs2=%0d rd=%0d rw=%0b mr=%0b mw=%0b imm=%0h | Exp: ALUop=%0b rs1=%0d rs2=%0d rd=%0d rw=%0b mr=%0b mw=%0b imm=%0h",
                   trans.instruction,
                   trans.alu_op, trans.rs1, trans.rs2, trans.rd, trans.reg_write, trans.mem_read, trans.mem_write, trans.imm_ext,
                   exp_alu_op, exp_rs1, exp_rs2, exp_rd, exp_reg_write, exp_mem_read, exp_mem_write, exp_imm_ext))
      mismatch_count++;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD",
      $sformatf("Verification Summary: Matches = %0d, Mismatches = %0d", match_count, mismatch_count),
      UVM_LOW)
    if (mismatch_count > 0)
      `uvm_error("SCOREBOARD", "Verification FAILED — mismatches detected")
  endfunction
endclass