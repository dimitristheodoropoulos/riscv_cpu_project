`ifndef CPU_EXEC_UVM_WRAPPER_SV
`define CPU_EXEC_UVM_WRAPPER_SV

`timescale 1ns/1ps

module cpu_exec_uvm_wrapper (
    cpu_exec_if cpu_if
);

    logic instr_mem_program_we;

    cpu_exec_core dut (
        .clk              (cpu_if.clk),
        .reset            (cpu_if.reset),
        .execution_enable (cpu_if.execution_enable),
        .instr_mem_we     (instr_mem_program_we),
        .instr_mem_waddr  (cpu_if.program_addr[7:2]),
        .instr_mem_wdata  (cpu_if.program_data),
        .reg_init_enable  (cpu_if.reg_init_enable),
        .reg_init_addr    (cpu_if.reg_init_addr),
        .reg_init_data    (cpu_if.reg_init_data),
        .reg_init_is_fp   (cpu_if.reg_init_is_fp),
        .pc               (cpu_if.pc),
        .result           (cpu_if.result)
    );

    // --------------------------------------------------------
    // CPU Assertion-Based Verification
    // --------------------------------------------------------

    cpu_exec_assertions u_assertions (
        .clk              (cpu_if.clk),
        .reset            (cpu_if.reset),
        .execution_enable (cpu_if.execution_enable),
        .mem_read         (dut.mem_read),
        .mem_write        (dut.mem_write),
        .pc               (cpu_if.pc),
        .x0               (dut.u_rf.int_regs[0])
    );

    // --------------------------------------------------------
    // Instruction-level architectural commit observation
    //
    // This is observation-only. No DUT state is modified here.
    // commit_rd_we represents an actual architectural integer
    // register write, matching the register-file write boundary.
    // --------------------------------------------------------

    always_comb begin

        cpu_if.commit_valid =
            cpu_if.execution_enable &&
            (dut.instruction != 32'h00000000);

        cpu_if.commit_pc =
            dut.pc;

        cpu_if.commit_instruction =
            dut.instruction;

        cpu_if.commit_rd =
            dut.rd;

        cpu_if.commit_rd_we =
            cpu_if.commit_valid &&
            dut.reg_write &&
            !dut.is_fp &&
            (dut.rd != 5'd0);

        cpu_if.commit_rd_value =
            dut.writeback_data;

    end

    // --------------------------------------------------------
    // Instruction memory programming
    // --------------------------------------------------------

    always_comb begin

        instr_mem_program_we =
            cpu_if.program_enable &&
            (cpu_if.program_addr[1:0] == 2'b00) &&
            (cpu_if.program_addr[7:2] <= 6'd63);

        if (cpu_if.program_enable) begin

            if (cpu_if.program_addr[1:0] != 2'b00) begin

                $error(
                    "Unaligned program address: %h",
                    cpu_if.program_addr
                );

            end
            else if (cpu_if.program_addr[7:2] > 6'd63) begin

                $error(
                    "Program address out of range: %h",
                    cpu_if.program_addr
                );

            end

        end

    end

    // --------------------------------------------------------
    // Architectural state observation
    // --------------------------------------------------------

    integer i;

    always_comb begin

        for (i = 0; i < 32; i = i + 1) begin

            cpu_if.int_regs[i] =
                dut.u_rf.int_regs[i];

            cpu_if.fp_regs[i] =
                dut.u_rf.fp_regs[i];

        end

        for (i = 0; i < 256; i = i + 1) begin

            cpu_if.data_mem[i] =
                dut.u_mmu.memory[i];

        end

    end

endmodule

`endif