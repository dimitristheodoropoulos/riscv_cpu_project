`timescale 1ns/1ps

module cpu_exec_branch_smoke_tb;

    logic        clk;
    logic        reset;
    logic        execution_enable;

    logic        instr_mem_we;
    logic [5:0]  instr_mem_waddr;
    logic [31:0] instr_mem_wdata;

    logic        reg_init_enable;
    logic [4:0]  reg_init_addr;
    logic [31:0] reg_init_data;
    logic        reg_init_is_fp;

    wire [31:0]  pc;
    wire [31:0]  result;

    integer errors;

    cpu_exec_core dut (
        .clk              (clk),
        .reset            (reset),
        .execution_enable (execution_enable),

        .instr_mem_we     (instr_mem_we),
        .instr_mem_waddr  (instr_mem_waddr),
        .instr_mem_wdata  (instr_mem_wdata),

        .reg_init_enable  (reg_init_enable),
        .reg_init_addr    (reg_init_addr),
        .reg_init_data    (reg_init_data),
        .reg_init_is_fp   (reg_init_is_fp),

        .pc               (pc),
        .result           (result)
    );

    always #5 clk = ~clk;

    task automatic program_instruction(
        input logic [5:0]  addr,
        input logic [31:0] data
    );
        begin
            @(negedge clk);
            instr_mem_waddr = addr;
            instr_mem_wdata = data;
            instr_mem_we    = 1'b1;

            @(posedge clk);
            #1;

            instr_mem_we = 1'b0;
        end
    endtask

    task automatic init_int_reg(
        input logic [4:0]  addr,
        input logic [31:0] data
    );
        begin
            @(negedge clk);
            reg_init_addr   = addr;
            reg_init_data   = data;
            reg_init_is_fp  = 1'b0;
            reg_init_enable = 1'b1;

            @(posedge clk);
            #1;

            reg_init_enable = 1'b0;
        end
    endtask

    task automatic check_pc(
        input logic [31:0] expected,
        input string       name
    );
        begin
            if (pc !== expected) begin
                $display(
                    "FAIL: %s | PC=%h expected=%h",
                    name, pc, expected
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: %s | PC=%h",
                    name, pc
                );
            end
        end
    endtask

    /*
     * B-type instruction encoder.
     *
     * imm is a signed byte offset relative to current PC.
     *
     * B-immediate layout:
     *   imm[12]   -> instruction[31]
     *   imm[10:5] -> instruction[30:25]
     *   imm[4:1]  -> instruction[11:8]
     *   imm[11]   -> instruction[7]
     *   imm[0]    -> implicit zero
     */
    function automatic [31:0] enc_branch(
        input logic [2:0] funct3,
        input logic [4:0] rs1,
        input logic [4:0] rs2,
        input integer     imm
    );
        logic [12:0] bimm;
        begin
            bimm = imm[12:0];

            enc_branch = {
                bimm[12],
                bimm[10:5],
                rs2,
                rs1,
                funct3,
                bimm[4:1],
                bimm[11],
                7'b1100011
            };
        end
    endfunction

    /*
     * Branch smoke sequence
     *
     * PC  0: BEQ x1,x2,+8   -> taken     -> PC 8
     * PC  8: BNE x1,x2,+8   -> taken     -> PC 16
     * PC 16: BLT x3,x4,+8   -> taken     -> PC 24
     * PC 24: BGE x4,x3,+8   -> taken     -> PC 32
     * PC 32: BEQ x1,x3,+8   -> not taken -> PC 36
     * PC 36: BNE x1,x1,+8   -> not taken -> PC 40
     * PC 40: BLT x4,x3,+8   -> not taken -> PC 44
     * PC 44: BGE x3,x4,+8   -> not taken -> PC 48
     * PC 48: BGE x5,x6,-8   -> taken     -> PC 40
     *
     * x3 = -5, x4 = +5, therefore:
     *   BLT x3,x4  -> taken
     *   BGE x4,x3  -> taken
     *   BLT x4,x3  -> not taken
     *   BGE x3,x4  -> not taken
     *
     * x5 = 100, x6 = 100.
     * The final BGE x5,x6,-8 verifies a negative branch offset.
     */
    initial begin

        clk              = 1'b0;
        reset            = 1'b1;
        execution_enable = 1'b0;

        instr_mem_we     = 1'b0;
        instr_mem_waddr  = 6'd0;
        instr_mem_wdata  = 32'd0;

        reg_init_enable  = 1'b0;
        reg_init_addr    = 5'd0;
        reg_init_data    = 32'd0;
        reg_init_is_fp   = 1'b0;

        errors = 0;

        $display("========================================");
        $display("CPU EXEC RV32I BRANCH SMOKE TEST");
        $display("========================================");

        repeat (2) @(posedge clk);
        #1;
        reset = 1'b0;

        /*
         * Register initialization:
         *
         * x1 = 10
         * x2 = 10
         * x3 = -5
         * x4 = 5
         * x5 = 100
         * x6 = 100
         */
        init_int_reg(5'd1, 32'd10);
        init_int_reg(5'd2, 32'd10);
        init_int_reg(5'd3, 32'hFFFFFFFB);
        init_int_reg(5'd4, 32'd5);
        init_int_reg(5'd5, 32'd100);
        init_int_reg(5'd6, 32'd100);

        /*
         * Program branch instructions.
         */
        program_instruction(
            6'd0,
            enc_branch(3'b000, 5'd1, 5'd2, 13'd8)
        ); // BEQ x1,x2,+8

        program_instruction(
            6'd2,
            enc_branch(3'b001, 5'd1, 5'd3, 13'd8)
        ); // BNE x1,x3,+8

        program_instruction(
            6'd4,
            enc_branch(3'b100, 5'd3, 5'd4, 13'd8)
        ); // BLT x3,x4,+8

        program_instruction(
            6'd6,
            enc_branch(3'b101, 5'd4, 5'd3, 13'd8)
        ); // BGE x4,x3,+8

        program_instruction(
            6'd8,
            enc_branch(3'b000, 5'd1, 5'd3, 13'd8)
        ); // BEQ x1,x3,+8, not taken

        program_instruction(
            6'd9,
            enc_branch(3'b001, 5'd1, 5'd1, 13'd8)
        ); // BNE x1,x1,+8, not taken

        program_instruction(
            6'd10,
            enc_branch(3'b100, 5'd4, 5'd3, 13'd8)
        ); // BLT x4,x3,+8, not taken

        program_instruction(
            6'd11,
            enc_branch(3'b101, 5'd3, 5'd4, 13'd8)
        ); // BGE x3,x4,+8, not taken

        program_instruction(
            6'd12,
            enc_branch(3'b101, 5'd5, 5'd6, -8)
        ); // BGE x5,x6,-8

        @(negedge clk);
        execution_enable = 1'b1;

        /*
         * PC 0: BEQ taken -> 8
         */
        @(posedge clk);
        #1;
        check_pc(32'd8, "BEQ taken (+8)");

        /*
         * PC 8: BNE x1,x3 taken -> 16
         */
        @(posedge clk);
        #1;
        check_pc(32'd16, "BNE taken (+8)");

        /*
         * PC 16: BLT x3,x4 taken -> 24
         */
        @(posedge clk);
        #1;
        check_pc(32'd24, "BLT signed taken (+8)");

        /*
         * PC 24: BGE x4,x3 taken -> 32
         */
        @(posedge clk);
        #1;
        check_pc(32'd32, "BGE signed taken (+8)");

        /*
         * PC 32: BEQ x1,x3 not taken -> 36
         */
        @(posedge clk);
        #1;
        check_pc(32'd36, "BEQ not taken (+4)");

        /*
         * PC 36: BNE x1,x1 not taken -> 40
         */
        @(posedge clk);
        #1;
        check_pc(32'd40, "BNE not taken (+4)");

        /*
         * PC 40: BLT x4,x3 not taken -> 44
         */
        @(posedge clk);
        #1;
        check_pc(32'd44, "BLT signed not taken (+4)");

        /*
         * PC 44: BGE x3,x4 not taken -> 48
         */
        @(posedge clk);
        #1;
        check_pc(32'd48, "BGE signed not taken (+4)");

        /*
         * PC 48: BGE x5,x6,-8 taken -> 40
         */
        @(posedge clk);
        #1;
        check_pc(32'd40, "BGE taken (-8)");


        if (errors == 0) begin
            $display("");
            $display("========================================");
            $display("CPU EXEC BRANCH SMOKE PASSED");
            $display("========================================");
        end
        else begin
            $display("");
            $display(
                "CPU EXEC BRANCH SMOKE FAILED: %0d errors",
                errors
            );
            $fatal(1);
        end

        $finish;
    end

endmodule
