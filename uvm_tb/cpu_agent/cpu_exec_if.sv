`timescale 1ns/1ps

interface cpu_exec_if (
    input logic clk
);

    // --------------------------------------------------------
    // Reset
    // --------------------------------------------------------

    logic reset;

    // --------------------------------------------------------
    // CPU execution control
    // --------------------------------------------------------

    logic execution_enable;

    // --------------------------------------------------------
    // Program loading interface
    // --------------------------------------------------------

    logic        program_enable;
    logic [31:0] program_addr;
    logic [31:0] program_data;

    // --------------------------------------------------------
    // Register initialization interface
    // --------------------------------------------------------

    logic        reg_init_enable;
    logic [4:0]  reg_init_addr;
    logic [31:0] reg_init_data;
    logic        reg_init_is_fp;

    // --------------------------------------------------------
    // CPU observations
    // --------------------------------------------------------

    logic [31:0] pc;
    logic [31:0] result;

    // --------------------------------------------------------
    // UVM execution synchronization
    //
    // Asserted by the driver after the complete CPU program
    // has finished executing.
    //
    // The monitor uses this signal to capture one final
    // architectural-state snapshot.
    // --------------------------------------------------------

    logic execution_done;

    // --------------------------------------------------------
    // Architectural state observation
    //
    // These signals are driven by cpu_exec_uvm_wrapper.
    // The UVM monitor reads them through this interface.
    // --------------------------------------------------------

    logic [31:0] int_regs [0:31];
    logic [31:0] fp_regs  [0:31];
    logic [31:0] data_mem [0:255];

endinterface