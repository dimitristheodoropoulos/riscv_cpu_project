`timescale 1ns/1ps

module fpu_differential_tb;

reg        clk;
reg        rst;
reg [31:0] a;
reg [31:0] b;
reg [2:0]  op;

wire [31:0] result;
wire        ready;

integer fd;
integer rc;
integer vector_count;
integer errors;

reg [31:0] vector_a;
reg [31:0] vector_b;
reg [2:0]  vector_op;
reg [31:0] expected;

reg [8*128-1:0] line;

localparam OP_ADD = 3'b000;
localparam OP_SUB = 3'b001;
localparam OP_MUL = 3'b010;
localparam OP_DIV = 3'b011;

fpu dut (
    .clk    (clk),
    .rst    (rst),
    .a      (a),
    .b      (b),
    .op     (op),
    .result (result),
    .ready  (ready)
);

always #5 clk = ~clk;


// ============================================================
// Operation name helper
// ============================================================

function [8*4-1:0] op_name;
    input [2:0] operation;

    begin
        case (operation)
            OP_ADD:  op_name = "ADD ";
            OP_SUB:  op_name = "SUB ";
            OP_MUL:  op_name = "MUL ";
            OP_DIV:  op_name = "DIV ";
            default: op_name = "UNK ";
        endcase
    end
endfunction


// ============================================================
// Single differential vector check
// ============================================================

task automatic check_vector;
    input [31:0] tv_a;
    input [31:0] tv_b;
    input [2:0]  tv_op;
    input [31:0] tv_expected;

    begin
        a  = tv_a;
        b  = tv_b;
        op = tv_op;

        @(posedge clk);
        #1;

        vector_count = vector_count + 1;

        if (!ready) begin

            $display(
                "FAIL [%0d] %s a=%h b=%h | ready=0 expected=%h",
                vector_count,
                op_name(tv_op),
                tv_a,
                tv_b,
                tv_expected
            );

            errors = errors + 1;

        end
        else if (result !== tv_expected) begin

            $display(
                "FAIL [%0d] %s a=%h b=%h | expected=%h got=%h",
                vector_count,
                op_name(tv_op),
                tv_a,
                tv_b,
                tv_expected,
                result
            );

            errors = errors + 1;

        end
    end
endtask


// ============================================================
// Test
// ============================================================

initial begin

    clk = 1'b0;
    rst = 1'b1;

    a   = 32'h00000000;
    b   = 32'h00000000;
    op  = OP_ADD;

    vector_count = 0;
    errors       = 0;

    // Reset
    #20;
    rst = 1'b0;

    // --------------------------------------------------------
    // Open generated reference-model vectors
    // --------------------------------------------------------

    fd = $fopen(
        "../sim/output/fpu_differential_vectors.txt",
        "r"
    );

    if (fd == 0) begin

        $display(
            "FATAL: Could not open differential vector file"
        );

        $stop;

    end

    $display("");
    $display("========================================");
    $display("FPU DIFFERENTIAL VERIFICATION");
    $display("========================================");
    $display("Loading reference-model vectors...");
    $display("");


    // --------------------------------------------------------
    // Read file line-by-line.
    //
    // File format:
    //
    // # a b op expected
    // 00000000 00000000 0 00000000
    // ...
    // --------------------------------------------------------

    while (!$feof(fd)) begin

        rc = $fgets(line, fd);

        if (rc > 0) begin

            // Ignore comments/header/blank lines.
            if ((line[8*128-1 -: 8] != "#") &&
                (line[8*128-1 -: 8] != "\n")) begin

                rc = $sscanf(
                    line,
                    "%h %h %h %h",
                    vector_a,
                    vector_b,
                    vector_op,
                    expected
                );

                if (rc == 4) begin

                    check_vector(
                        vector_a,
                        vector_b,
                        vector_op,
                        expected
                    );

                end
            end
        end
    end


    $fclose(fd);


    // --------------------------------------------------------
    // Final report
    // --------------------------------------------------------

    $display("");
    $display("========================================");
    $display("FPU DIFFERENTIAL VERIFICATION");
    $display("========================================");
    $display("Vectors executed : %0d", vector_count);
    $display("Errors            : %0d", errors);
    $display("");

    if (errors == 0 && vector_count > 0) begin

        $display("========================================");
        $display("FPU DIFFERENTIAL VERIFICATION PASSED");
        $display("========================================");

    end
    else begin

        $display("========================================");
        $display("FPU DIFFERENTIAL VERIFICATION FAILED");
        $display("========================================");

    end

    $stop;

end

endmodule