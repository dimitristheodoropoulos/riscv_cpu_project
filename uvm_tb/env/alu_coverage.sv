import uvm_pkg::*;
`include "uvm_macros.svh"

class alu_coverage extends uvm_subscriber #(alu_transaction);
  `uvm_component_utils(alu_coverage)

  // Manual coverage bins — αντικαθιστά covergroup/coverpoint, που απαιτούν
  // την πληρωμένη svverification license στο Questa Starter Edition.
  int unsigned op_hits    [logic [3:0]];
  int unsigned zero_hits  [bit];
  int unsigned ovf_hits   [bit];

  static logic [3:0] valid_ops[8] = '{4'b0000, 4'b0001, 4'b0010, 4'b0011,
                                       4'b0100, 4'b0101, 4'b0110, 4'b0111};

  function new(string name = "alu_coverage", uvm_component parent = null);
    super.new(name, parent);
    foreach (valid_ops[i]) op_hits[valid_ops[i]] = 0;
    zero_hits[1'b0] = 0; zero_hits[1'b1] = 0;
    ovf_hits[1'b0]  = 0; ovf_hits[1'b1]  = 0;
  endfunction

  function void write(alu_transaction t);
    if (op_hits.exists(t.alu_control))
      op_hits[t.alu_control]++;
    else
      `uvm_warning("COVERAGE", $sformatf("Unexpected alu_control value: %0b", t.alu_control))
    zero_hits[t.zero]++;
    ovf_hits[t.overflow]++;
  endfunction

  function void report_phase(uvm_phase phase);
    int unsigned covered  = 0;
    int unsigned total    = $size(valid_ops);
    super.report_phase(phase);
    foreach (valid_ops[i])
      if (op_hits[valid_ops[i]] > 0) covered++;

    `uvm_info("COVERAGE",
      $sformatf("Opcode coverage: %0d/%0d bins hit (%0.1f%%)",
                 covered, total, (covered * 100.0) / total),
      UVM_LOW)
    foreach (valid_ops[i])
      `uvm_info("COVERAGE",
        $sformatf("  op=%0b hits=%0d", valid_ops[i], op_hits[valid_ops[i]]),
        UVM_LOW)
    `uvm_info("COVERAGE",
      $sformatf("Zero: hit=%0d, not_hit=%0d | Overflow: hit=%0d, not_hit=%0d",
                 zero_hits[1'b1], zero_hits[1'b0], ovf_hits[1'b1], ovf_hits[1'b0]),
      UVM_LOW)
  endfunction
endclass