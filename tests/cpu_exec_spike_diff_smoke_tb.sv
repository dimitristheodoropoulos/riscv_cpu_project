`timescale 1ns/1ps

module cpu_exec_spike_diff_smoke_tb;

    logic clk;

    cpu_exec_if cpu_if(clk);

    cpu_exec_uvm_wrapper dut (
        .cpu_if(cpu_if)
    );

    integer dut_trace_fd;

    // ------------------------------------------------------------
    // Test program
    //
    // x1 = 0x80002000
    // x2 = 7
    //
    // ADD x3, x1, x2 -> x3 = 0x80002007
    // BEQ x2, x2, +8 -> taken; skips PC 0x08
    // ADD x20, x1, x2 -> skipped
    // SW x2, 0(x1)
    // LW x4, 0(x1) -> x4 = 7
    // ------------------------------------------------------------

    localparam logic [31:0] I0 = 32'h002081B3;
    localparam logic [31:0] I1 = 32'h00210463;
    localparam logic [31:0] I2 = 32'h00208A33;
    localparam logic [31:0] I3 = 32'h0020A023;
    localparam logic [31:0] I4 = 32'h0000A203;

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Program loading
    // ------------------------------------------------------------

    task automatic load_instruction(
        input logic [31:0] addr,
        input logic [31:0] data
    );
        begin
            @(negedge clk);

            cpu_if.program_addr   = addr;
            cpu_if.program_data   = data;
            cpu_if.program_enable = 1'b1;

            @(posedge clk);

            #1;
            cpu_if.program_enable = 1'b0;
        end
    endtask

    // ------------------------------------------------------------
    // Integer register initialization
    // ------------------------------------------------------------

    task automatic init_integer_register(
        input integer index,
        input logic [31:0] value
    );
        begin
            @(negedge clk);

            cpu_if.reg_init_addr    = index[4:0];
            cpu_if.reg_init_data    = value;
            cpu_if.reg_init_is_fp   = 1'b0;
            cpu_if.reg_init_enable  = 1'b1;

            @(posedge clk);

            #1;
            cpu_if.reg_init_enable = 1'b0;
        end
    endtask

    // ------------------------------------------------------------
    // Commit check
    //
    // commit_* are sampled before the active edge because the
    // wrapper exposes the currently executing instruction.
    // ------------------------------------------------------------

    task automatic check_commit(
        input logic [31:0] expected_pc,
        input logic [31:0] expected_instruction,
        input logic        expected_rd_valid,
        input logic [4:0]  expected_rd
    );
        begin
            if (cpu_if.commit_valid !== 1'b1) begin
                $display(
                    "FAIL: commit_valid | PC=%08h | instruction=%08h",
                    cpu_if.commit_pc,
                    cpu_if.commit_instruction
                );
                $fatal(1);
            end

            if (cpu_if.commit_pc !== expected_pc) begin
                $display(
                    "FAIL: commit PC | Expected=%08h | Got=%08h",
                    expected_pc,
                    cpu_if.commit_pc
                );
                $fatal(1);
            end

            if (cpu_if.commit_instruction !== expected_instruction) begin
                $display(
                    "FAIL: commit instruction | Expected=%08h | Got=%08h",
                    expected_instruction,
                    cpu_if.commit_instruction
                );
                $fatal(1);
            end

            if (expected_rd_valid &&
                cpu_if.commit_rd !== expected_rd) begin
                $display(
                    "FAIL: commit rd | Expected=%0d | Got=%0d",
                    expected_rd,
                    cpu_if.commit_rd
                );
                $fatal(1);
            end




        end
    endtask

    // ------------------------------------------------------------
    // Architectural register check
    // ------------------------------------------------------------

    task automatic write_commit_trace(
        input logic [31:0] pc,
        input logic [31:0] instruction,
        input logic        rd_valid,
        input logic [4:0]  rd
    );
        begin
            if (rd_valid) begin
                $fdisplay(
                    dut_trace_fd,
                    "DUT_COMMIT %08h %08h x%0d %08h",
                    pc,
                    instruction,
                    rd,
                    cpu_if.int_regs[rd]
                );
            end
            else begin
                $fdisplay(
                    dut_trace_fd,
                    "DUT_COMMIT %08h %08h",
                    pc,
                    instruction
                );
            end
        end
    endtask

    task automatic check_register(
        input integer index,
        input logic [31:0] expected
    );
        begin
            if (cpu_if.int_regs[index] !== expected) begin
                $display(
                    "FAIL: x%0d | Expected=%08h | Got=%08h",
                    index,
                    expected,
                    cpu_if.int_regs[index]
                );
                $fatal(1);
            end

            $display(
                "DUT_REG x%0d %08h",
                index,
                cpu_if.int_regs[index]
            );
        end
    endtask

    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------

    initial begin

        dut_trace_fd = $fopen("dut_spike_diff.trace", "w");
        if (dut_trace_fd == 0) begin
            $display("FAIL: unable to open DUT trace file");
            $fatal(1);
        end

        cpu_if.reset            = 1'b1;
        cpu_if.execution_enable = 1'b0;
        cpu_if.program_enable   = 1'b0;
        cpu_if.program_addr     = 32'h0;
        cpu_if.program_data     = 32'h0;

        cpu_if.reg_init_enable  = 1'b0;
        cpu_if.reg_init_addr    = 5'd0;
        cpu_if.reg_init_data    = 32'h0;
        cpu_if.reg_init_is_fp   = 1'b0;

        // Hold reset for one complete clock edge.
        @(posedge clk);
        #1;

        if (cpu_if.pc !== 32'h00000000) begin
            $display(
                "FAIL: PC after reset | Expected=00000000 | Got=%08h",
                cpu_if.pc
            );
            $fatal(1);
        end

        // Program image at the DUT's zero-based address space
        // while reset is still asserted.
        load_instruction(32'h00000000, I0);
        load_instruction(32'h00000004, I1);
        load_instruction(32'h00000008, I2);
        load_instruction(32'h0000000c, I3);
        load_instruction(32'h00000010, I4);

        // Release reset before architectural register initialization.
        @(negedge clk);
        cpu_if.reset = 1'b0;

        // Initial architectural state.
        init_integer_register(1, 32'h80002000);
        init_integer_register(2, 32'd7);

        // Start execution.
        //
        // The first instruction is observed at the current
        // negedge, before the following posedge executes it.
        @(negedge clk);
        cpu_if.execution_enable = 1'b1;

        // Allow the wrapper's combinational commit observation
        // to settle after execution_enable changes.
        #1ps;

        // --------------------------------------------------------
        // ADD x3, x1, x2
        // --------------------------------------------------------

        check_commit(
            32'h00000000,
            I0,
            1'b1,
            5'd3
        );

        @(posedge clk);
        #1;

        check_register(3, 32'h80002007);
        write_commit_trace(
            32'h00000000,
            I0,
            1'b1,
            5'd3
        );

        // --------------------------------------------------------
        // BEQ x2, x2, +8 — taken
        // --------------------------------------------------------

        @(negedge clk);
        check_commit(
            32'h00000004,
            I1,
            1'b0,
            5'd0
        );

        @(posedge clk);
        #1;

        if (cpu_if.pc !== 32'h0000000c) begin
            $display(
                "FAIL: taken BEQ target | Expected=0000000c | Got=%08h",
                cpu_if.pc
            );
            $fatal(1);
        end

        write_commit_trace(
            32'h00000004,
            I1,
            1'b0,
            5'd0
        );

        // --------------------------------------------------------
        // PC 0x08 must be skipped by the taken branch.
        // --------------------------------------------------------

        @(negedge clk);

        if (cpu_if.pc !== 32'h0000000c) begin
            $display(
                "FAIL: skipped instruction PC | Expected=0000000c | Got=%08h",
                cpu_if.pc
            );
            $fatal(1);
        end

        check_commit(
            32'h0000000c,
            I3,
            1'b0,
            5'd0
        );

        @(posedge clk);
        #1;

        write_commit_trace(
            32'h0000000c,
            I3,
            1'b0,
            5'd0
        );

        // --------------------------------------------------------
        // LW x4, 0(x1)
        // --------------------------------------------------------

        @(negedge clk);
        check_commit(
            32'h00000010,
            I4,
            1'b1,
            5'd4
        );

        @(posedge clk);
        #1;

        check_register(4, 32'd7);
        write_commit_trace(
            32'h00000010,
            I4,
            1'b1,
            5'd4
        );

        $display("DUT_FINAL_PC %08h", cpu_if.pc);


        $fdisplay(dut_trace_fd, "DUT_FINAL_PC %08h", cpu_if.pc);


        $fclose(dut_trace_fd);

        // Final architectural-state snapshot.
        if (cpu_if.pc !== 32'h00000014) begin
            $display(
                "FAIL: final PC | Expected=00000014 | Got=%08h",
                cpu_if.pc
            );
            $fatal(1);
        end

        check_register(0, 32'd0);
        check_register(1, 32'h80002000);
        check_register(2, 32'd7);
        check_register(3, 32'h80002007);
        check_register(4, 32'd7);
        check_register(20, 32'd0);

        cpu_if.execution_enable = 1'b0;

        $display("DUT_SPIKE_DIFF_SMOKE_PASS");

        $finish;
    end

endmodule
