// cu_tb.sv - Testbench for Control Unit

module cu_tb;

    reg [31:0] instruction;  // Instruction input to CU
    wire [2:0] ALU_op;       // ALU operation control
    wire [4:0] rs1, rs2, rd; // Register addresses
    wire is_fp;              // Floating point flag
    wire mem_read, mem_write, reg_write; // Control signals

    // Instantiate the Control Unit
    cu uut (
        .instruction(instruction),
        .ALU_op(ALU_op),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
    cu_tb.sv    .is_fp(is_fp),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .reg_write(reg_write)
    );

    initial begin
        // Test 1: R-type instruction
        instruction = 32'b000000_00001_00010_00011_00000_100000;  // Example: ADD R1, R2, R3
        #10;
        $display("ALU_op: %b, rs1: %d, rs2: %d, rd: %d", ALU_op, rs1, rs2, rd);

        // Test 2: Load Word (LW)
        instruction = 32'b100011_00001_00010_00000_0000000000000000;  // LW R2, 0(R1)
        #10;
        $display("mem_read: %b, reg_write: %b, rs1: %d, rd: %d", mem_read, reg_write, rs1, rd);

        // Test 3: Store Word (SW)
        instruction = 32'b101011_00001_00010_00000_0000000000000000;  // SW R2, 0(R1)
        #10;
        $display("mem_write: %b, rs1: %d, rs2: %d", mem_write, rs1, rs2);
        
        // Additional tests can be added for other instructions
        
        $finish;
    end

endmodule