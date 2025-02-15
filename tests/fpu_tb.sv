module fpu_tb;

    reg clk;
    reg rst;
    reg [31:0] a;
    reg [31:0] b;
    reg [2:0] op;

    wire [31:0] result;
    wire ready;

    fpu uut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .ready(ready)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        a = 0;
        b = 0;
        op = 0;
        #20;  
        rst = 0;

        // ADD Test
        a = 32'h40000000;  // 2.0
        b = 32'h40400000;  // 3.0
        op = 3'b000;       // ADD
        #10;
        wait (ready);
        $display("ADD: A = %h, B = %h, Result = %h", a, b, result);

        // SUB Test
        a = 32'h40800000;  // 4.0
        b = 32'h40000000;  // 2.0
        op = 3'b001;       // SUB
        #10;
        wait (ready);
        $display("SUB: A = %h, B = %h, Result = %h", a, b, result);

        // MUL Test
        a = 32'h40400000;  // 3.0
        b = 32'h40000000;  // 2.0
        op = 3'b010;       // MUL
        #10;
        wait (ready);
        $display("MUL: A = %h, B = %h, Result = %h", a, b, result);

        // DIV Test
        a = 32'h40800000;  // 8.0
        b = 32'h40000000;  // 2.0
        op = 3'b011;       // DIV
        #10;
        wait (ready);
        $display("DIV: A = %h, B = %h, Result = %h", a, b, result);

        $finish;
    end

endmodule
