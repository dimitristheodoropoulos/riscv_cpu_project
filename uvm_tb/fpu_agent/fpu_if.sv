interface fpu_if (input bit clk);
    logic        rst;
    logic [31:0] a;
    logic [31:0] b;
    logic [2:0]  op;
    logic [31:0] result;
    logic        ready;

    modport dut (
        input  clk, rst, a, b, op,
        output result, ready
    );

    modport tb (
        input  clk, result, ready,
        output rst, a, b, op
    );
endinterface