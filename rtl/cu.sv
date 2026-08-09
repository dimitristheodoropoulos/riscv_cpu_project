// cu.sv - Control Unit (RV32I decode)

module cu (
    input  [31:0] instruction,
    output reg [3:0] ALU_op,
    output reg [4:0] rs1, rs2, rd,
    output reg        is_fp,
    output reg        mem_read,
    output reg        mem_write,
    output reg        reg_write,
    output reg [31:0] imm_ext        // sign-extended immediate (νέο - χρειάζεται immgen logic)
);

    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];

    always @(*) begin
        ALU_op    = 4'b0000;
        rs1       = 5'b0;
        rs2       = 5'b0;
        rd        = 5'b0;
        is_fp     = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        reg_write = 1'b0;
        imm_ext   = 32'b0;

        case (opcode)
            7'b0110011: begin  // R-type (ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND)
                rs1 = instruction[19:15];
                rs2 = instruction[24:20];
                rd  = instruction[11:7];
                reg_write = 1'b1;
                case (funct3)
                    3'b000: ALU_op = funct7[5] ? 4'b0110 : 4'b0010; // SUB : ADD
                    3'b111: ALU_op = 4'b0000;                       // AND
                    3'b110: ALU_op = 4'b0001;                       // OR
                    3'b010: ALU_op = 4'b0111;                       // SLT
                    default: ALU_op = 4'b1111;                      // unsupported yet
                endcase
            end

            7'b0000011: begin  // Load (LB/LH/LW/LBU/LHU) - LW πλήρως, υπόλοιπα TODO
                rs1 = instruction[19:15];
                rd  = instruction[11:7];
                imm_ext  = {{20{instruction[31]}}, instruction[31:20]}; // I-type imm
                mem_read = 1'b1;
                reg_write = 1'b1;
            end

            7'b0100011: begin  // Store (SB/SH/SW) - SW πλήρως, υπόλοιπα TODO
                rs1 = instruction[19:15];
                rs2 = instruction[24:20];
                imm_ext = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; // S-type imm
                mem_write = 1'b1;
            end

            default: begin
                // NOP / unsupported opcode (branches, jumps, U-type κ.λπ. - future work)
            end
        endcase
    end

endmodule