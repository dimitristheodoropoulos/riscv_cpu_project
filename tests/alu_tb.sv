module alu_tb;
    reg [31:0] A, B;
    reg [2:0] Op;
    reg is_fp;
    wire [31:0] Result;

    // Instantiate the ALU
    alu uut (
        .A(A),
        .B(B),
        .Op(Op),
        .is_fp(is_fp),
        .Result(Result)
    );

    initial begin
        $display("Starting ALU Testbench");
        
        // Integer Addition
        A = 32'd10; B = 32'd5; Op = 3'b000; is_fp = 0;
        #10 $display("Integer ADD: %d + %d = %d", A, B, Result);
        
        // Integer Subtraction
        A = 32'd20; B = 32'd7; Op = 3'b001; is_fp = 0;
        #10 $display("Integer SUB: %d - %d = %d", A, B, Result);
        
        // Floating-Point Addition
        A = 32'h3f800000; // 1.0 in IEEE 754
        B = 32'h40000000; // 2.0 in IEEE 754
        Op = 3'b000; is_fp = 1;
        #10 $display("Floating-Point ADD: %h + %h = %h", A, B, Result);
        
        // Floating-Point Multiplication
        A = 32'h3f800000; // 1.0 in IEEE 754
        B = 32'h40000000; // 2.0 in IEEE 754
        Op = 3'b010; is_fp = 1;
        #10 $display("Floating-Point MUL: %h * %h = %h", A, B, Result);
        
        $stop;
    end
endmodule
