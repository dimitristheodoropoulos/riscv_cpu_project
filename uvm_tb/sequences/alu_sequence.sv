import uvm_pkg::*;
`include "uvm_macros.svh"

class alu_random_sequence extends uvm_sequence #(alu_transaction);
  `uvm_object_utils(alu_random_sequence)

  function new(string name = "alu_random_sequence");
    super.new(name);
  endfunction

  task body();
    repeat (100) begin
      req = alu_transaction::type_id::create("req");
      start_item(req);
      // Questa Starter Edition δεν διαθέτει license για randomize()
      // (svverification feature) — χρησιμοποιούμε $urandom απευθείας.
      req.a           = $urandom;
      req.b           = $urandom;
      req.alu_control = $urandom_range(0, 7); // 0-7 = όλες οι έγκυρες ALU ops
      finish_item(req);
    end
  endtask
endclass