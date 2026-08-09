import uvm_pkg::*;
`include "uvm_macros.svh"

class alu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(alu_scoreboard)

  uvm_analysis_imp #(alu_transaction, alu_scoreboard) item_collected_export;

  int match_count = 0;
  int mismatch_count = 0;

  function new(string name = "alu_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_collected_export = new("item_collected_export", this);
  endfunction

  function void write(alu_transaction trans);
    logic [31:0] expected_res;
    logic        expected_zero;
    logic        expected_overflow;

    expected_overflow = 1'b0;

    case (trans.alu_control)
      4'b0010: begin // ADD
        expected_res = trans.a + trans.b;
        expected_overflow = (trans.a[31] == trans.b[31]) && (expected_res[31] != trans.a[31]);
      end
      4'b0110: begin // SUB
        expected_res = trans.a - trans.b;
        expected_overflow = (trans.a[31] != trans.b[31]) && (expected_res[31] != trans.a[31]);
      end
      4'b0000: expected_res = trans.a & trans.b;                                         // AND
      4'b0001: expected_res = trans.a | trans.b;                                         // OR
      4'b0111: expected_res = ($signed(trans.a) < $signed(trans.b)) ? 32'd1 : 32'd0;      // SLT
      4'b0011: expected_res = trans.a ^ trans.b;                                         // XOR
      4'b0100: expected_res = trans.a << trans.b[4:0];                                   // SLL
      4'b0101: expected_res = $signed(trans.a) >>> trans.b[4:0];                          // SRA
      default: expected_res = 32'b0;
    endcase

    expected_zero = (expected_res == 32'b0);

    if (trans.result === expected_res &&
        trans.zero   === expected_zero &&
        trans.overflow === expected_overflow) begin
      `uvm_info("SCOREBOARD",
        $sformatf("MATCH! A=%0h B=%0h Ctrl=%0b -> Res=%0h Zero=%0b OVF=%0b",
                   trans.a, trans.b, trans.alu_control, trans.result, trans.zero, trans.overflow),
        UVM_HIGH)
      match_count++;
    end else begin
      `uvm_error("SCOREBOARD",
        $sformatf("MISMATCH! A=%0h B=%0h Ctrl=%0b | Got: Res=%0h Zero=%0b OVF=%0b | Exp: Res=%0h Zero=%0b OVF=%0b",
                   trans.a, trans.b, trans.alu_control,
                   trans.result, trans.zero, trans.overflow,
                   expected_res, expected_zero, expected_overflow))
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