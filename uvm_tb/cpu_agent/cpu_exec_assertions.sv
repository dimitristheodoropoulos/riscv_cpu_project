`ifndef CPU_EXEC_ASSERTIONS_SV
`define CPU_EXEC_ASSERTIONS_SV

module cpu_exec_assertions (
    input logic        clk,
    input logic        reset,

    input logic        execution_enable,

    input logic        mem_read,
    input logic        mem_write,

    input logic [31:0] pc,
    input logic [31:0] x0
);

    // --------------------------------------------------------
    // PC must be zero while reset is asserted
    // --------------------------------------------------------

    property p_reset_pc_zero;
        @(posedge clk) reset |-> (pc == 32'h00000000);
    endproperty

    a_reset_pc_zero: assert property (p_reset_pc_zero)
        else $error("CPU ASSERTION FAILED: PC is not zero during reset");

    // --------------------------------------------------------
    // RISC-V x0 architectural invariant
    // x0 must remain zero outside reset
    // --------------------------------------------------------

    property p_x0_zero;
        @(posedge clk) disable iff (reset) (x0 == 32'h00000000);
    endproperty

    a_x0_zero: assert property (p_x0_zero)
        else $error("CPU ASSERTION FAILED: x0 is not zero");

    // --------------------------------------------------------
    // Memory read and write must not be active simultaneously
    // --------------------------------------------------------

    property p_no_mem_rd_wr;
        @(posedge clk) disable iff (reset) !(mem_read && mem_write);
    endproperty

    a_no_mem_rd_wr: assert property (p_no_mem_rd_wr)
        else $error("CPU ASSERTION FAILED: mem_read and mem_write both high");

    // --------------------------------------------------------
    // Execution must be disabled during reset
    // --------------------------------------------------------

    property p_no_exec_during_reset;
        @(posedge clk) reset |-> !execution_enable;
    endproperty

    a_no_exec_during_reset: assert property (p_no_exec_during_reset)
        else $error("CPU ASSERTION FAILED: execution_enable active during reset");

endmodule

`endif