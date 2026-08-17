`ifndef CPU_REFERENCE_MODEL_SV
`define CPU_REFERENCE_MODEL_SV

package cpu_model_pkg;

    import cpu_pkg::*;

    // ------------------------------------------------------------
    // RV32I Reference Model
    //
    // Models the currently supported CPU execution subset:
    //
    //   R-type: ADD, SUB, AND, OR, XOR, SLL, SRA, SLT
    //   I-type: LW
    //   S-type: SW
    //
    // The model maintains architectural state independently
    // from the RTL implementation.
    // ------------------------------------------------------------

    class cpu_reference_model;

        // --------------------------------------------------------
        // Architectural state
        // --------------------------------------------------------

        bit [31:0] regs [0:31];

        // Data memory: 256 x 32-bit words
        bit [31:0] data_mem [0:255];

        // Instruction memory: 64 x 32-bit words
        bit [31:0] instr_mem [0:63];

        bit [31:0] pc;

        // --------------------------------------------------------
        // Constructor
        // --------------------------------------------------------

        function new();
            reset_model();
        endfunction

        // --------------------------------------------------------
        // Reset architectural state
        // --------------------------------------------------------

        function void reset_model();

            int i;

            for (i = 0; i < 32; i++) begin
                regs[i] = 32'h00000000;
            end

            for (i = 0; i < 256; i++) begin
                data_mem[i] = 32'h00000000;
            end

            for (i = 0; i < 64; i++) begin
                instr_mem[i] = 32'h00000000;
            end

            pc = 32'h00000000;

        endfunction

        // --------------------------------------------------------
        // Load instruction memory image
        // --------------------------------------------------------

        function void load_program(
            input bit [31:0] instr_image [0:63]
        );

            int i;

            for (i = 0; i < 64; i++) begin
                instr_mem[i] = instr_image[i];
            end

        endfunction

        // --------------------------------------------------------
        // Initialize integer architectural registers
        // --------------------------------------------------------

        function void init_regs(
            input bit [31:0] init_int_regs [0:31]
        );

            int i;

            for (i = 0; i < 32; i++) begin
                regs[i] = init_int_regs[i];
            end

            // RISC-V x0 is hardwired to zero.
            regs[0] = 32'h00000000;

        endfunction

        // --------------------------------------------------------
        // Execute one instruction
        // --------------------------------------------------------

        function void execute_instruction(
            input bit [31:0] instr
        );

            bit [6:0]  opcode;
            bit [4:0]  rd;
            bit [2:0]  funct3;
            bit [4:0]  rs1;
            bit [4:0]  rs2;
            bit [6:0]  funct7;

            bit [31:0] rs1_data;
            bit [31:0] rs2_data;

            bit signed [31:0] imm_i;
            bit signed [31:0] imm_s;

            bit [31:0] addr;

            opcode = instr[6:0];
            rd     = instr[11:7];
            funct3 = instr[14:12];
            rs1    = instr[19:15];
            rs2    = instr[24:20];
            funct7 = instr[31:25];

            // ----------------------------------------------------
            // Architectural reads
            //
            // x0 is always zero.
            // ----------------------------------------------------

            if (rs1 == 5'd0)
                rs1_data = 32'h00000000;
            else
                rs1_data = regs[rs1];

            if (rs2 == 5'd0)
                rs2_data = 32'h00000000;
            else
                rs2_data = regs[rs2];

            // ----------------------------------------------------
            // Decode / execute
            // ----------------------------------------------------

            case (opcode)

                // ------------------------------------------------
                // R-type
                //
                // ADD
                // SUB
                // AND
                // OR
                // XOR
                // SLL
                // SRA
                // SLT
                // ------------------------------------------------

                7'b0110011: begin

                    case (funct3)

                        // ADD / SUB
                        3'b000: begin

                            if (funct7 == 7'b0100000) begin

                                // SUB
                                if (rd != 5'd0)
                                    regs[rd] =
                                        rs1_data - rs2_data;

                            end
                            else if (funct7 == 7'b0000000) begin

                                // ADD
                                if (rd != 5'd0)
                                    regs[rd] =
                                        rs1_data + rs2_data;

                            end

                        end

                        // AND
                        3'b111: begin

                            if (funct7 == 7'b0000000 &&
                                rd != 5'd0) begin

                                regs[rd] =
                                    rs1_data & rs2_data;

                            end

                        end

                        // OR
                        3'b110: begin

                            if (funct7 == 7'b0000000 &&
                                rd != 5'd0) begin

                                regs[rd] =
                                    rs1_data | rs2_data;

                            end

                        end

                        // SLT
                        3'b010: begin

                            if (funct7 == 7'b0000000 &&
                                rd != 5'd0) begin

                                regs[rd] =
                                    ($signed(rs1_data) <
                                     $signed(rs2_data))
                                    ? 32'd1
                                    : 32'd0;

                            end

                        end

                        // XOR
                        3'b100: begin

                            if (funct7 == 7'b0000000 &&
                                rd != 5'd0) begin

                                regs[rd] =
                                    rs1_data ^ rs2_data;

                            end

                        end

                        // SLL
                        3'b001: begin

                            if (funct7 == 7'b0000000 &&
                                rd != 5'd0) begin

                                regs[rd] =
                                    rs1_data << rs2_data[4:0];

                            end

                        end

                        // SRA
                        3'b101: begin

                            if (funct7 == 7'b0100000 &&
                                rd != 5'd0) begin

                                regs[rd] =
                                    $signed(rs1_data) >>> rs2_data[4:0];

                            end

                        end

                        default: begin
                            // Unsupported R-type instruction.
                        end

                    endcase

                end

                // ------------------------------------------------
                // I-type LW
                //
                // opcode = 0000011
                // funct3 = 010
                // ------------------------------------------------

                7'b0000011: begin

                    if (funct3 == 3'b010) begin

                        imm_i =
                            $signed({
                                {20{instr[31]}},
                                instr[31:20]
                            });

                        addr =
                            rs1_data + imm_i;

                        if (rd != 5'd0) begin

                            regs[rd] =
                                data_mem[addr[7:0]];

                        end

                    end

                end

                // ------------------------------------------------
                // S-type SW
                //
                // opcode = 0100011
                // funct3 = 010
                // ------------------------------------------------

                7'b0100011: begin

                    if (funct3 == 3'b010) begin

                        imm_s =
                            $signed({
                                {20{instr[31]}},
                                instr[31:25],
                                instr[11:7]
                            });

                        addr =
                            rs1_data + imm_s;

                        data_mem[addr[7:0]] =
                            rs2_data;

                    end

                end

                default: begin
                    // Unsupported instruction / NOP.
                end

            endcase

            // ----------------------------------------------------
            // x0 remains architecturally zero.
            // ----------------------------------------------------

            regs[0] = 32'h00000000;

            // ----------------------------------------------------
            // Single-cycle CPU: advance PC by 4.
            // ----------------------------------------------------

            pc = pc + 32'd4;

        endfunction

        // --------------------------------------------------------
        // Execute complete instr_image
        //
        // IMPORTANT:
        // The caller supplies the initial register image.
        // --------------------------------------------------------

        function void execute_program(
            input bit [31:0] instr_image [0:63],
            input bit [31:0] init_int_regs [0:31],
            input integer instr_count
        );

            int i;

            // Start from clean architectural state.
            reset_model();

            // Load instr_image.
            load_program(instr_image);

            // Apply transaction's initial register state.
            init_regs(init_int_regs);

            // Start execution at address zero.
            pc = 32'h00000000;

            // Execute requested number of instructions.
            for (i = 0; i < instr_count; i++) begin

                execute_instruction(
                    instr_mem[pc[7:2]]
                );

            end

            // Architectural invariant.
            regs[0] = 32'h00000000;

        endfunction

    endclass

endpackage

`endif