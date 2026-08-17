`timescale 1ns/1ps

module alu_unit_tb;

    reg  [31:0] A;
    reg  [31:0] B;
    reg  [3:0]  Op;

    wire [31:0] Result;
    wire        zero;
    wire        overflow;

    integer tests;
    integer passed;

    // Functional coverage tracking
    integer opcode_hits [0:15];
    integer cov_i;
    reg     zero_seen;
    reg     overflow_seen;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    alu uut (
        .A(A),
        .B(B),
        .Op(Op),
        .Result(Result),
        .zero(zero),
        .overflow(overflow)
    );

    // ------------------------------------------------------------
    // Self-checking task
    // ------------------------------------------------------------
    task check_result;
        input [31:0] expected;
        input        expected_zero;
        input        expected_overflow;
        input [255:0] test_name;

        begin
            tests = tests + 1;
            opcode_hits[Op] = opcode_hits[Op] + 1;

            #1;

            if (zero)     zero_seen     = 1'b1;
            if (overflow) overflow_seen = 1'b1;

            if ((Result === expected) &&
                (zero === expected_zero) &&
                (overflow === expected_overflow)) begin

                passed = passed + 1;

                $display(
                    "PASS: %s | A=%h B=%h Op=%b Result=%h Zero=%b Overflow=%b",
                    test_name, A, B, Op, Result, zero, overflow
                );

            end else begin

                $display(
                    "FAIL: %s | A=%h B=%h Op=%b | Expected: Result=%h Zero=%b Overflow=%b | Got: Result=%h Zero=%b Overflow=%b",
                    test_name,
                    A, B, Op,
                    expected, expected_zero, expected_overflow,
                    Result, zero, overflow
                );

            end
        end
    endtask

    // ------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------
    initial begin

        tests  = 0;
        passed = 0;
        zero_seen     = 1'b0;
        overflow_seen = 1'b0;
        for (cov_i = 0; cov_i < 16; cov_i = cov_i + 1)
            opcode_hits[cov_i] = 0;

        $display("========================================");
        $display("ALU Functional Verification");
        $display("========================================");

        // --------------------------------------------------------
        // AND
        // --------------------------------------------------------
        A = 32'hFFFF0000;
        B = 32'h0F0F0F0F;
        Op = 4'b0000;
        check_result(
            32'h0F0F0000,
            1'b0,
            1'b0,
            "AND"
        );

        // --------------------------------------------------------
        // OR
        // --------------------------------------------------------
        A = 32'hF0000000;
        B = 32'h0000000F;
        Op = 4'b0001;
        check_result(
            32'hF000000F,
            1'b0,
            1'b0,
            "OR"
        );

        // --------------------------------------------------------
        // ADD
        // --------------------------------------------------------
        A = 32'd10;
        B = 32'd5;
        Op = 4'b0010;
        check_result(
            32'd15,
            1'b0,
            1'b0,
            "ADD"
        );

        // ADD zero result
        A = 32'd0;
        B = 32'd0;
        Op = 4'b0010;
        check_result(
            32'd0,
            1'b1,
            1'b0,
            "ADD zero"
        );

        // ADD signed overflow: 0x7fffffff + 1
        A = 32'h7FFFFFFF;
        B = 32'h00000001;
        Op = 4'b0010;
        check_result(
            32'h80000000,
            1'b0,
            1'b1,
            "ADD signed overflow"
        );

        // --------------------------------------------------------
        // XOR
        // --------------------------------------------------------
        A = 32'hAAAA5555;
        B = 32'hFFFF0000;
        Op = 4'b0011;
        check_result(
            32'h55555555,
            1'b0,
            1'b0,
            "XOR"
        );

        // --------------------------------------------------------
        // SLL
        // --------------------------------------------------------
        A = 32'h00000001;
        B = 32'd4;
        Op = 4'b0100;
        check_result(
            32'h00000010,
            1'b0,
            1'b0,
            "SLL"
        );

        // --------------------------------------------------------
        // SRA
        // --------------------------------------------------------
        A = 32'h80000000;
        B = 32'd4;
        Op = 4'b0101;
        check_result(
            32'hF8000000,
            1'b0,
            1'b0,
            "SRA signed"
        );

        // --------------------------------------------------------
        // SUB
        // --------------------------------------------------------
        A = 32'd20;
        B = 32'd7;
        Op = 4'b0110;
        check_result(
            32'd13,
            1'b0,
            1'b0,
            "SUB"
        );

        // SUB zero result
        A = 32'd42;
        B = 32'd42;
        Op = 4'b0110;
        check_result(
            32'd0,
            1'b1,
            1'b0,
            "SUB zero"
        );

        // SUB signed overflow: INT_MIN - 1
        A = 32'h80000000;
        B = 32'h00000001;
        Op = 4'b0110;
        check_result(
            32'h7FFFFFFF,
            1'b0,
            1'b1,
            "SUB signed overflow"
        );

        // --------------------------------------------------------
        // SLT
        // --------------------------------------------------------
        A = 32'd5;
        B = 32'd10;
        Op = 4'b0111;
        check_result(
            32'd1,
            1'b0,
            1'b0,
            "SLT true"
        );

        A = 32'd10;
        B = 32'd5;
        Op = 4'b0111;
        check_result(
            32'd0,
            1'b1,
            1'b0,
            "SLT false"
        );

        // Signed comparison: -1 < 1
        A = 32'hFFFFFFFF;
        B = 32'h00000001;
        Op = 4'b0111;
        check_result(
            32'd1,
            1'b0,
            1'b0,
            "SLT signed negative"
        );

        // --------------------------------------------------------
        // Invalid opcode
        // --------------------------------------------------------
        A = 32'h12345678;
        B = 32'h87654321;
        Op = 4'b1111;
        check_result(
            32'd0,
            1'b1,
            1'b0,
            "Invalid opcode"
        );

        // --------------------------------------------------------
        // --------------------------------------------------------
        // Functional coverage report
        // --------------------------------------------------------
        $display("========================================");
        $display("ALU FUNCTIONAL COVERAGE REPORT");
        $display("========================================");
        $display("AND  (0000): %0d hits", opcode_hits[0]);
        $display("OR   (0001): %0d hits", opcode_hits[1]);
        $display("ADD  (0010): %0d hits", opcode_hits[2]);
        $display("XOR  (0011): %0d hits", opcode_hits[3]);
        $display("SLL  (0100): %0d hits", opcode_hits[4]);
        $display("SRA  (0101): %0d hits", opcode_hits[5]);
        $display("SUB  (0110): %0d hits", opcode_hits[6]);
        $display("SLT  (0111): %0d hits", opcode_hits[7]);
        $display("Zero flag exercised    : %s", zero_seen     ? "YES" : "NO");
        $display("Overflow flag exercised: %s", overflow_seen ? "YES" : "NO");

        // Summary
        // --------------------------------------------------------
        $display("========================================");
        $display("ALU VERIFICATION SUMMARY");
        $display("Tests : %0d", tests);
        $display("Passed: %0d", passed);
        $display("Failed: %0d", tests - passed);
        $display("========================================");

        if (passed != tests) begin
            $display("ALU VERIFICATION FAILED");
            $fatal(1);
        end else begin
            $display("ALU VERIFICATION PASSED");
        end

        $finish;
    end

endmodule
