`timescale 1ns/1ps

module cpu_exec_uvm_wrapper (
    cpu_exec_if cpu_if
);

    cpu_exec_core dut (
        .clk              (cpu_if.clk),
        .reset            (cpu_if.reset),
        .execution_enable (cpu_if.execution_enable),
        .reg_init_enable  (cpu_if.reg_init_enable),
        .reg_init_addr    (cpu_if.reg_init_addr),
        .reg_init_data    (cpu_if.reg_init_data),
        .reg_init_is_fp   (cpu_if.reg_init_is_fp),
        .pc               (cpu_if.pc),
        .result           (cpu_if.result)
    );


    // --------------------------------------------------------
    // Instruction memory programming
    //
    // Sampled on positive clock edge.
    // Driver presents program_enable before posedge.
    // --------------------------------------------------------

    always @(posedge cpu_if.clk) begin

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
            else begin

                dut.instr_mem[cpu_if.program_addr[7:2]]
                    = cpu_if.program_data;

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