// cu.sv - Control Unit

module cu (
    input [31:0] instruction,  // 32-bit instruction from memory
    output reg [2:0] ALU_op,   // ALU operation control
    output reg [4:0] rs1, rs2, rd, // Register addresses
    output reg is_fp,           // Floating point flag
    output reg mem_read,        // Memory read signal
    output reg mem_write,       // Memory write signal
    output reg reg_write        // Register write enable
);

    always @(*) begin
        // Default values
        ALU_op = 3'b000;
        rs1 = 0;
        rs2 = 0;
        rd = 0;
        is_fp = 0;
        mem_read = 0;
        mem_write = 0;
        reg_write = 0;

        case (instruction[31:26])  // Use the opcode part (bits 31-26)
            6'b000000: begin  // R-type instructions
                ALU_op = instruction[5:3];  // Use function code for ALU operation
                rs1 = instruction[25:21];
                rs2 = instruction[20:16];
                rd = instruction[15:11];
                reg_write = 1;
            end
            6'b100011: begin  // LW (Load Word)
                rs1 = instruction[25:21];
                rd = instruction[15:11];
                mem_read = 1;
                reg_write = 1;
            end
            6'b101011: begin  // SW (Store Word)
                rs1 = instruction[25:21];
                rs2 = instruction[20:16];
                mem_write = 1;
            end
            // Additional instructions (e.g., Branch, Jump, etc.)
            default: begin
                // Handle other instructions or NOP
            end
        endcase
    end

endmodule