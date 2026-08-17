`timescale 1ns/1ps

module cpu_exec_reg_init_smoke_tb;

    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    logic clk;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // --------------------------------------------------------
    // CPU interface
    // --------------------------------------------------------

    cpu_exec_if cpu_if (
        .clk(clk)
    );

    // --------------------------------------------------------
    // Testbench wrapper
    // --------------------------------------------------------

    cpu_exec_uvm_wrapper dut (
        .cpu_if(cpu_if)
    );

    integer errors;

    // --------------------------------------------------------
    // Program loading helper
    // --------------------------------------------------------

    task load_instruction;
        input [31:0] addr;
        input [31:0] data;

        begin
            @(negedge clk);

            cpu_if.program_enable = 1'b1;
            cpu_if.program_addr   = addr;
            cpu_if.program_data   = data;

            @(negedge clk);

            cpu_if.program_enable = 1'b0;
            cpu_if.program_addr   = 32'b0;
            cpu_if.program_data   = 32'b0;
        end
    endtask

    // --------------------------------------------------------
    // Integer register initialization helper
    //
    // Uses the testbench-only register initialization interface
    // instead of hierarchical DUT access.
    // --------------------------------------------------------

    task init_int_reg;
        input [4:0]  addr;
        input [31:0] data;

        begin

            if (addr == 5'd0) begin

                $warning(
                    "Attempt to initialize integer x0 ignored"
                );

            end
            else begin

                @(negedge clk);

                cpu_if.reg_init_enable = 1'b1;
                cpu_if.reg_init_is_fp  = 1'b0;
                cpu_if.reg_init_addr   = addr;
                cpu_if.reg_init_data   = data;

                @(negedge clk);

                cpu_if.reg_init_enable = 1'b0;
                cpu_if.reg_init_addr   = 5'b0;
                cpu_if.reg_init_data   = 32'b0;

            end

        end
    endtask

    // --------------------------------------------------------
    // Check result
    // --------------------------------------------------------

    task check_result;
        input [31:0] expected;
        input [255:0] name;

        begin
            #1;

            if (cpu_if.result === expected) begin

                $display(
                    "PASS: %s | Result = %h",
                    name,
                    cpu_if.result
                );

            end
            else begin

                $display(
                    "FAIL: %s | Expected = %h | Got = %h",
                    name,
                    expected,
                    cpu_if.result
                );

                errors = errors + 1;

            end
        end
    endtask

    // --------------------------------------------------------
    // Check architectural register
    // --------------------------------------------------------

    task check_int_reg;
        input [4:0]  addr;
        input [31:0] expected;
        input [255:0] name;

        begin

            if (dut.dut.u_rf.int_regs[addr] === expected) begin

                $display(
                    "PASS: %s | x%0d = %h",
                    name,
                    addr,
                    dut.dut.u_rf.int_regs[addr]
                );

            end
            else begin

                $display(
                    "FAIL: %s | x%0d | Expected = %h | Got = %h",
                    name,
                    addr,
                    expected,
                    dut.dut.u_rf.int_regs[addr]
                );

                errors = errors + 1;

            end

        end
    endtask

    // --------------------------------------------------------
    // Test sequence
    // --------------------------------------------------------

    initial begin

        errors = 0;

        // ----------------------------------------------------
        // Initial interface values
        // ----------------------------------------------------

        cpu_if.reset            = 1'b1;
        cpu_if.execution_enable = 1'b0;

        cpu_if.program_enable  = 1'b0;
        cpu_if.program_addr    = 32'b0;
        cpu_if.program_data    = 32'b0;

        cpu_if.reg_init_enable = 1'b0;
        cpu_if.reg_init_is_fp  = 1'b0;
        cpu_if.reg_init_addr   = 5'b0;
        cpu_if.reg_init_data   = 32'b0;

        $display("========================================");
        $display("CPU EXEC REGISTER INIT SMOKE TEST");
        $display("========================================");

        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (2) @(posedge clk);

        #1;

        if (cpu_if.pc === 32'h00000000) begin
            $display("PASS: PC after reset = %h", cpu_if.pc);
        end
        else begin
            $display("FAIL: PC after reset | Expected = 00000000 | Got = %h", cpu_if.pc);
            errors = errors + 1;
        end

        // ----------------------------------------------------
        // Program
        //
        // ADD  x3, x1, x2
        // SUB  x3, x1, x2
        // AND  x3, x1, x2
        // OR   x3, x1, x2
        // XOR  x3, x1, x2
        // SLL  x3, x1, x2
        // SRL  x3, x1, x2
        // SLT  x3, x1, x2
        // SLTU x3, x1, x2
        // SRA  x3, x1, x2
        // ----------------------------------------------------

        load_instruction(32'h00000000, 32'h002081B3);
        load_instruction(32'h00000004, 32'h402081B3);
        load_instruction(32'h00000008, 32'h0020F1B3);
        load_instruction(32'h0000000C, 32'h0020E1B3);
        load_instruction(32'h00000010, 32'h0020C1B3);
        load_instruction(32'h00000014, 32'h002091B3);
        load_instruction(32'h00000018, 32'h0020D1B3);
        load_instruction(32'h0000001C, 32'h0020A1B3);
        load_instruction(32'h00000020, 32'h0020B1B3);
        load_instruction(32'h00000024, 32'h4020D1B3);

        // ----------------------------------------------------
        // RELEASE RESET BEFORE REGISTER INITIALIZATION
        //
        // The register initialization interface uses the normal
        // write path. Register file reset has priority, so we
        // must release reset first.
        // ----------------------------------------------------

        cpu_if.reset = 1'b0;

        @(negedge clk);
        @(posedge clk);
        #1;

        // ----------------------------------------------------
        // Initialize integer registers via interface.
        //
        // x1 = 10
        // x2 = 5
        // ----------------------------------------------------

        init_int_reg(5'd1, 32'd10);
        init_int_reg(5'd2, 32'd5);

        // ----------------------------------------------------
        // Attempt to initialize x0 via interface.
        //
        // x0 must remain zero.
        // ----------------------------------------------------

        @(negedge clk);
        cpu_if.reg_init_enable = 1'b1;
        cpu_if.reg_init_is_fp  = 1'b0;
        cpu_if.reg_init_addr   = 5'd0;
        cpu_if.reg_init_data   = 32'hDEADBEEF;
        @(negedge clk);
        cpu_if.reg_init_enable = 1'b0;
        cpu_if.reg_init_addr   = 5'b0;
        cpu_if.reg_init_data   = 32'b0;

        // ----------------------------------------------------
        // Wait one full cycle after the last init transaction
        // before enabling execution.
        // ----------------------------------------------------

        @(posedge clk);
        #1;

        // ----------------------------------------------------
        // Enable CPU execution.
        // ----------------------------------------------------

        cpu_if.execution_enable = 1'b1;

        #1;

        // ----------------------------------------------------
        // Check results after each instruction.
        // ----------------------------------------------------

        // ADD
        $display("BEFORE ADD EDGE:");
        $display("  PC          = %h", cpu_if.pc);
        $display("  instruction = %h", dut.dut.instruction);
        $display("  exec_enable = %b", cpu_if.execution_enable);
        $display("  alu_result  = %h", dut.dut.alu_result);

        check_result(32'd15, "ADD result");

        @(posedge clk);
        #1;

        $display("AFTER ADD EDGE:");
        $display("  PC      = %h", cpu_if.pc);
        $display("  x3      = %h", dut.dut.u_rf.int_regs[3]);

        if (cpu_if.pc === 32'h00000004) begin
            $display("PASS: PC after ADD = %h", cpu_if.pc);
        end
        else begin
            $display("FAIL: PC after ADD | Expected = 00000004 | Got = %h", cpu_if.pc);
            errors = errors + 1;
        end

        check_int_reg(5'd3, 32'd15, "ADD architectural writeback x3");

        // SUB
        @(posedge clk);
        #1;

        $display("AFTER SUB EDGE:");
        $display("  PC      = %h", cpu_if.pc);
        $display("  x3      = %h", dut.dut.u_rf.int_regs[3]);

        if (cpu_if.pc === 32'h00000008) begin
            $display("PASS: PC after SUB = %h", cpu_if.pc);
        end
        else begin
            $display("FAIL: PC after SUB | Expected = 00000008 | Got = %h", cpu_if.pc);
            errors = errors + 1;
        end

        check_int_reg(5'd3, 32'd5, "SUB architectural writeback x3");

        // AND
        @(posedge clk);
        #1;

        $display("AFTER AND EDGE:");
        $display("  PC      = %h", cpu_if.pc);
        $display("  x3      = %h", dut.dut.u_rf.int_regs[3]);

        if (cpu_if.pc === 32'h0000000C) begin
            $display("PASS: PC after AND = %h", cpu_if.pc);
        end
        else begin
            $display("FAIL: PC after AND | Expected = 0000000C | Got = %h", cpu_if.pc);
            errors = errors + 1;
        end

        check_int_reg(5'd3, 32'd0, "AND architectural writeback x3");

        // OR
        @(posedge clk);
        #1;

        $display("AFTER OR EDGE:");
        $display("  PC      = %h", cpu_if.pc);
        $display("  x3      = %h", dut.dut.u_rf.int_regs[3]);

        if (cpu_if.pc === 32'h00000010) begin
            $display("PASS: PC after OR = %h", cpu_if.pc);
        end
        else begin
            $display("FAIL: PC after OR | Expected = 00000010 | Got = %h", cpu_if.pc);
            errors = errors + 1;
        end

        check_int_reg(5'd3, 32'd15, "OR architectural writeback x3");

        // XOR
        @(posedge clk);
        #1;

        $display("AFTER XOR EDGE:");
        $display("  PC      = %h", cpu_if.pc);
        $display("  x3      = %h", dut.dut.u_rf.int_regs[3]);

        if (cpu_if.pc === 32'h00000014) begin
            $display("PASS: PC after XOR = %h", cpu_if.pc);
        end
        else begin
            $display("FAIL: PC after XOR | Expected = 00000014 | Got = %h", cpu_if.pc);
            errors = errors + 1;
        end

        check_int_reg(5'd3, 32'd15, "XOR architectural writeback x3");

        // SLL
        @(posedge clk);
        #1;

        $display("AFTER SLL EDGE:");
        $display("  PC      = %h", cpu_if.pc);
        $display("  x3      = %h", dut.dut.u_rf.int_regs[3]);

        if (cpu_if.pc === 32'h00000018) begin
            $display("PASS: PC after SLL = %h", cpu_if.pc);
        end
        else begin
            $display("FAIL: PC after SLL | Expected = 00000018 | Got = %h", cpu_if.pc);
            errors = errors + 1;
        end

        check_int_reg(5'd3, 32'd320, "SLL architectural writeback x3");

        // SRL
        @(posedge clk);
        #1;

        $display("AFTER SRL EDGE:");
        $display("  PC      = %h", cpu_if.pc);
        $display("  x3      = %h", dut.dut.u_rf.int_regs[3]);

        if (cpu_if.pc === 32'h0000001C) begin
            $display("PASS: PC after SRL = %h", cpu_if.pc);
        end
        else begin
            $display("FAIL: PC after SRL | Expected = 0000001C | Got = %h", cpu_if.pc);
            errors = errors + 1;
        end

        check_int_reg(5'd3, 32'd0, "SRL architectural writeback x3");

        // SLT
        @(posedge clk);
        #1;

        $display("AFTER SLT EDGE:");
        $display("  PC      = %h", cpu_if.pc);
        $display("  x3      = %h", dut.dut.u_rf.int_regs[3]);

        if (cpu_if.pc === 32'h00000020) begin
            $display("PASS: PC after SLT = %h", cpu_if.pc);
        end
        else begin
            $display("FAIL: PC after SLT | Expected = 00000020 | Got = %h", cpu_if.pc);
            errors = errors + 1;
        end

        check_int_reg(5'd3, 32'd0, "SLT architectural writeback x3");

        // SLTU
        @(posedge clk);
        #1;

        $display("AFTER SLTU EDGE:");
        $display("  PC      = %h", cpu_if.pc);
        $display("  x3      = %h", dut.dut.u_rf.int_regs[3]);

        if (cpu_if.pc === 32'h00000024) begin
            $display("PASS: PC after SLTU = %h", cpu_if.pc);
        end
        else begin
            $display("FAIL: PC after SLTU | Expected = 00000024 | Got = %h", cpu_if.pc);
            errors = errors + 1;
        end

        check_int_reg(5'd3, 32'd0, "SLTU architectural writeback x3");

        // SRA
        @(posedge clk);
        #1;

        $display("AFTER SRA EDGE:");
        $display("  PC      = %h", cpu_if.pc);
        $display("  x3      = %h", dut.dut.u_rf.int_regs[3]);

        if (cpu_if.pc === 32'h00000028) begin
            $display("PASS: PC after SRA = %h", cpu_if.pc);
        end
        else begin
            $display("FAIL: PC after SRA | Expected = 00000028 | Got = %h", cpu_if.pc);
            errors = errors + 1;
        end

        check_int_reg(5'd3, 32'd0, "SRA architectural writeback x3");

        // ----------------------------------------------------
        // Final summary
        // ----------------------------------------------------

        $display("========================================");

        if (errors == 0) begin
            $display("CPU EXEC REGISTER INIT SMOKE PASSED");
        end
        else begin
            $display("CPU EXEC REGISTER INIT SMOKE FAILED: %0d errors", errors);
            $fatal(1);
        end

        $display("========================================");

        $finish;

    end

endmodule