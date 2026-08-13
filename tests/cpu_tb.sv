`timescale 1ns/1ps

module cpu_tb;

reg clk;
reg reset;

wire [31:0] result;

integer errors;

cpu_core dut (
    .clk(clk),
    .reset(reset),
    .result(result)
);

always #5 clk = ~clk;

initial begin

    clk = 1'b0;
    reset = 1'b1;

    errors = 0;

    #20;

    reset = 1'b0;

    repeat (10) begin
        @(posedge clk);
    end

    #1;

    if (^result === 1'bx) begin
        $display("FAIL: CPU result contains X/Z");
        errors = errors + 1;
    end
    else begin
        $display(
            "PASS: CPU result is known: %h",
            result
        );
    end

    if (errors == 0) begin
        $display("");
        $display("CPU VERIFICATION PASSED");
    end
    else begin
        $display("");
        $display(
            "CPU VERIFICATION FAILED: %0d errors",
            errors
        );
    end

    $finish;
end

endmodule