module fpu_sva (
    input logic        clk,
    input logic        rst,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [2:0]  op,
    input logic [31:0] result,
    input logic        ready
);

    default clocking cb @(posedge clk);
    endclocking


    // ============================================================
    // RESET ASSERTIONS
    // ============================================================

    // Reset forces result to zero on the reset clock edge.
    property p_reset_result_zero;
        rst |=> result == 32'h00000000;
    endproperty

    assert property (p_reset_result_zero)
        else $error("SVA: result is not zero after reset");


    // Reset forces ready low on the reset clock edge.
    property p_reset_ready_zero;
        rst |=> ready == 1'b0;
    endproperty

    assert property (p_reset_ready_zero)
        else $error("SVA: ready is not zero after reset");


    // ============================================================
    // READY AFTER RESET RELEASE
    // ============================================================

    // Reset is released at one clock edge.
    // The sequential RTL sets ready <= 1 at that edge.
    // Therefore the new ready value must be visible on the
    // following sampled clock.
    property p_ready_after_reset;
        $past(rst) && !rst |=> ready;
    endproperty

    assert property (p_ready_after_reset)
        else $error("SVA: ready was not asserted after reset release");


    // ============================================================
    // NORMAL OPERATION
    // ============================================================

    // For every cycle in which reset is inactive, the next
    // registered cycle must have ready asserted.
    property p_ready_when_active;
        !rst |=> ready;
    endproperty

    assert property (p_ready_when_active)
        else $error("SVA: ready deasserted during normal operation");


    // ============================================================
    // VALID OPCODES
    // ============================================================

    // ADD = 000
    property p_valid_add_opcode;
        (!rst && op == 3'b000) |=> ready;
    endproperty

    assert property (p_valid_add_opcode)
        else $error("SVA: ADD operation did not assert ready");


    // SUB = 001
    property p_valid_sub_opcode;
        (!rst && op == 3'b001) |=> ready;
    endproperty

    assert property (p_valid_sub_opcode)
        else $error("SVA: SUB operation did not assert ready");


    // MUL = 010
    property p_valid_mul_opcode;
        (!rst && op == 3'b010) |=> ready;
    endproperty

    assert property (p_valid_mul_opcode)
        else $error("SVA: MUL operation did not assert ready");


    // DIV = 011
    property p_valid_div_opcode;
        (!rst && op == 3'b011) |=> ready;
    endproperty

    assert property (p_valid_div_opcode)
        else $error("SVA: DIV operation did not assert ready");


    // ============================================================
    // INVALID OPCODE
    // ============================================================

    // Opcodes 100-111 are invalid.
    // fpu.sv drives result <= 0 in the default case.
    property p_invalid_opcode_result_zero;
        (!rst &&
         (op == 3'b100 ||
          op == 3'b101 ||
          op == 3'b110 ||
          op == 3'b111))
        |=> result == 32'h00000000;
    endproperty

    assert property (p_invalid_opcode_result_zero)
        else $error("SVA: invalid opcode did not produce zero result");


    // Even for an invalid opcode, the sequential else branch
    // executes and ready <= 1.
    property p_invalid_opcode_ready;
        (!rst &&
         (op == 3'b100 ||
          op == 3'b101 ||
          op == 3'b110 ||
          op == 3'b111))
        |=> ready;
    endproperty

    assert property (p_invalid_opcode_ready)
        else $error("SVA: ready was not asserted for invalid opcode");


    // ============================================================
    // NO UNKNOWN VALUES
    // ============================================================

    // During normal operation, result must be known.
    property p_result_known;
        !rst |-> !$isunknown(result);
    endproperty

    assert property (p_result_known)
        else $error("SVA: result contains X/Z during normal operation");


    // During normal operation, ready must be known.
    property p_ready_known;
        !rst |-> !$isunknown(ready);
    endproperty

    assert property (p_ready_known)
        else $error("SVA: ready contains X/Z during normal operation");


    // ============================================================
    // RESET PRIORITY
    // ============================================================

    property p_reset_overrides_ready;
        rst |=> !ready;
    endproperty

    assert property (p_reset_overrides_ready)
        else $error("SVA: reset did not force ready low");


    property p_reset_overrides_result;
        rst |=> result == 32'h00000000;
    endproperty

    assert property (p_reset_overrides_result)
        else $error("SVA: reset did not force result to zero");


endmodule
