`timescale 1ns/1ps

module noc_mesh_2x2_tb;

    import noc_router_pkg::*;

    logic clk;
    logic rst;

    logic ep0_in_valid;
    logic ep0_in_ready;
    noc_packet_t ep0_in_packet;
    logic ep0_out_valid;
    logic ep0_out_ready;
    noc_packet_t ep0_out_packet;

    logic ep1_in_valid;
    logic ep1_in_ready;
    noc_packet_t ep1_in_packet;
    logic ep1_out_valid;
    logic ep1_out_ready;
    noc_packet_t ep1_out_packet;

    logic ep2_in_valid;
    logic ep2_in_ready;
    noc_packet_t ep2_in_packet;
    logic ep2_out_valid;
    logic ep2_out_ready;
    noc_packet_t ep2_out_packet;

    logic ep3_in_valid;
    logic ep3_in_ready;
    noc_packet_t ep3_in_packet;
    logic ep3_out_valid;
    logic ep3_out_ready;
    noc_packet_t ep3_out_packet;

    noc_mesh_2x2 dut (
        .clk            (clk),
        .rst            (rst),

        .ep0_in_valid   (ep0_in_valid),
        .ep0_in_ready   (ep0_in_ready),
        .ep0_in_packet  (ep0_in_packet),
        .ep0_out_valid  (ep0_out_valid),
        .ep0_out_ready  (ep0_out_ready),
        .ep0_out_packet (ep0_out_packet),

        .ep1_in_valid   (ep1_in_valid),
        .ep1_in_ready   (ep1_in_ready),
        .ep1_in_packet  (ep1_in_packet),
        .ep1_out_valid  (ep1_out_valid),
        .ep1_out_ready  (ep1_out_ready),
        .ep1_out_packet (ep1_out_packet),

        .ep2_in_valid   (ep2_in_valid),
        .ep2_in_ready   (ep2_in_ready),
        .ep2_in_packet  (ep2_in_packet),
        .ep2_out_valid  (ep2_out_valid),
        .ep2_out_ready  (ep2_out_ready),
        .ep2_out_packet (ep2_out_packet),

        .ep3_in_valid   (ep3_in_valid),
        .ep3_in_ready   (ep3_in_ready),
        .ep3_in_packet  (ep3_in_packet),
        .ep3_out_valid  (ep3_out_valid),
        .ep3_out_ready  (ep3_out_ready),
        .ep3_out_packet (ep3_out_packet)
    );

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial clk = 1'b0;

    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------

    task automatic clear_inputs;
        begin
            ep0_in_valid  = 1'b0;
            ep1_in_valid  = 1'b0;
            ep2_in_valid  = 1'b0;
            ep3_in_valid  = 1'b0;

            ep0_in_packet = '0;
            ep1_in_packet = '0;
            ep2_in_packet = '0;
            ep3_in_packet = '0;
        end
    endtask

    task automatic check_packet(
        input noc_packet_t actual,
        input noc_packet_t expected,
        input string test_name
    );
        begin
            if (actual.src_id !== expected.src_id ||
                actual.dst_id !== expected.dst_id ||
                actual.txn_id !== expected.txn_id ||
                actual.payload !== expected.payload) begin

                $display("FAIL: %s", test_name);
                $display("      expected src=%0d dst=%0d txn=%0d payload=0x%08h",
                         expected.src_id,
                         expected.dst_id,
                         expected.txn_id,
                         expected.payload);
                $display("      actual   src=%0d dst=%0d txn=%0d payload=0x%08h",
                         actual.src_id,
                         actual.dst_id,
                         actual.txn_id,
                         actual.payload);
                $fatal(1);
            end
        end
    endtask

    task automatic send_ep0_to_ep1;
        noc_packet_t expected;
        begin
            expected.src_id  = 3'd0;
            expected.dst_id  = 3'd1;
            expected.txn_id  = 4'h1;
            expected.payload = 32'h1111_AAAA;

            ep0_in_packet = expected;
            ep0_in_valid  = 1'b1;

            wait (ep0_in_ready === 1'b1);
            @(posedge clk);
            #1;
            ep0_in_valid = 1'b0;

            wait (ep1_out_valid === 1'b1);
            check_packet(ep1_out_packet, expected, "EP0 -> EP1");

            @(posedge clk);
            #1;

            $display("PASS: EP0 -> EP1");
        end
    endtask

    task automatic send_ep0_to_ep2;
        noc_packet_t expected;
        begin
            expected.src_id  = 3'd0;
            expected.dst_id  = 3'd2;
            expected.txn_id  = 4'h2;
            expected.payload = 32'h2222_BBBB;

            ep0_in_packet = expected;
            ep0_in_valid  = 1'b1;

            wait (ep0_in_ready === 1'b1);
            @(posedge clk);
            #1;
            ep0_in_valid = 1'b0;

            wait (ep2_out_valid === 1'b1);
            check_packet(ep2_out_packet, expected, "EP0 -> EP2");

            @(posedge clk);
            #1;

            $display("PASS: EP0 -> EP2");
        end
    endtask

    task automatic send_ep0_to_ep3;
        noc_packet_t expected;
        begin
            expected.src_id  = 3'd0;
            expected.dst_id  = 3'd3;
            expected.txn_id  = 4'h3;
            expected.payload = 32'h3333_CCCC;

            ep0_in_packet = expected;
            ep0_in_valid  = 1'b1;

            wait (ep0_in_ready === 1'b1);
            @(posedge clk);
            #1;
            ep0_in_valid = 1'b0;

            wait (ep3_out_valid === 1'b1);
            check_packet(ep3_out_packet, expected, "EP0 -> EP3");

            @(posedge clk);
            #1;

            $display("PASS: EP0 -> EP3");
        end
    endtask

    task automatic send_ep3_to_ep0;
        noc_packet_t expected;
        begin
            expected.src_id  = 3'd3;
            expected.dst_id  = 3'd0;
            expected.txn_id  = 4'h4;
            expected.payload = 32'h4444_DDDD;

            ep3_in_packet = expected;
            ep3_in_valid  = 1'b1;

            wait (ep3_in_ready === 1'b1);
            @(posedge clk);
            #1;
            ep3_in_valid = 1'b0;

            wait (ep0_out_valid === 1'b1);
            check_packet(ep0_out_packet, expected, "EP3 -> EP0");

            @(posedge clk);
            #1;

            $display("PASS: EP3 -> EP0");
        end
    endtask

    // ------------------------------------------------------------
    // Mesh-level backpressure / packet stability
    // EP0 -> EP3, with EP3 stalled
    // ------------------------------------------------------------

    task automatic test_ep0_to_ep3_backpressure;
        noc_packet_t expected;
        noc_packet_t stalled_packet;
        begin
            expected.src_id  = 3'd0;
            expected.dst_id  = 3'd3;
            expected.txn_id  = 4'h5;
            expected.payload = 32'h5555_EEEE;

            // Stall the destination endpoint.
            ep3_out_ready = 1'b0;

            ep0_in_packet = expected;
            ep0_in_valid  = 1'b1;

            wait (ep0_in_ready === 1'b1);
            @(posedge clk);
            #1;
            ep0_in_valid = 1'b0;

            // Wait until the packet reaches EP3.
            wait (ep3_out_valid === 1'b1);

            stalled_packet = ep3_out_packet;

            check_packet(
                ep3_out_packet,
                expected,
                "EP0 -> EP3 backpressure initial packet"
            );

            // Packet must remain stable while EP3 is not ready.
            repeat (3) begin
                @(posedge clk);
                #1;

                if (ep3_out_valid !== 1'b1) begin
                    $display("FAIL: EP3 out_valid dropped while stalled");
                    $fatal(1);
                end

                if (ep3_out_packet !== stalled_packet) begin
                    $display("FAIL: EP3 packet changed while stalled");
                    $fatal(1);
                end
            end

            $display("PASS: EP0 -> EP3 packet stable under backpressure");

            // Release the destination.
            ep3_out_ready = 1'b1;

            // The packet must still be present and unchanged.
            if (ep3_out_valid !== 1'b1) begin
                $display("FAIL: EP3 out_valid lost before release handshake");
                $fatal(1);
            end

            check_packet(
                ep3_out_packet,
                expected,
                "EP0 -> EP3 backpressure release"
            );

            // Complete the handshake.
            @(posedge clk);
            #1;

            if (ep3_out_valid === 1'b1) begin
                $display("FAIL: EP3 packet remained valid after handshake");
                $fatal(1);
            end

            $display("PASS: EP0 -> EP3 backpressure handshake completed");
        end
    endtask

    // ------------------------------------------------------------
    // Simultaneous independent flows / no loss / no duplication
    // EP0 -> EP3 and EP1 -> EP2
    // ------------------------------------------------------------

    task automatic test_parallel_independent_flows;
        noc_packet_t expected_ep0_ep3;
        noc_packet_t expected_ep1_ep2;
        integer ep3_count;
        integer ep2_count;
        integer cycles;
        begin
            expected_ep0_ep3.src_id   = 3'd0;
            expected_ep0_ep3.dst_id   = 3'd3;
            expected_ep0_ep3.txn_id   = 4'h6;
            expected_ep0_ep3.payload  = 32'hAAAA_0001;

            expected_ep1_ep2.src_id   = 3'd1;
            expected_ep1_ep2.dst_id   = 3'd2;
            expected_ep1_ep2.txn_id   = 4'h7;
            expected_ep1_ep2.payload  = 32'hBBBB_0002;

            ep3_count = 0;
            ep2_count = 0;

            ep3_out_ready = 1'b1;
            ep2_out_ready = 1'b1;

            // Present both independent packets simultaneously.
            ep0_in_packet = expected_ep0_ep3;
            ep0_in_valid  = 1'b1;

            ep1_in_packet = expected_ep1_ep2;
            ep1_in_valid  = 1'b1;

            // Both source handshakes must complete.
            fork
                begin
                    wait (ep0_in_ready === 1'b1);
                    @(posedge clk);
                    #1;
                    ep0_in_valid = 1'b0;
                end

                begin
                    wait (ep1_in_ready === 1'b1);
                    @(posedge clk);
                    #1;
                    ep1_in_valid = 1'b0;
                end
            join

            // Observe both destinations and require exactly one
            // successful delivery for each packet.
            for (cycles = 0; cycles < 10; cycles = cycles + 1) begin
                @(posedge clk);
                #1;

                if (ep3_out_valid === 1'b1) begin
                    check_packet(
                        ep3_out_packet,
                        expected_ep0_ep3,
                        "parallel EP0 -> EP3"
                    );
                    ep3_count = ep3_count + 1;
                end

                if (ep2_out_valid === 1'b1) begin
                    check_packet(
                        ep2_out_packet,
                        expected_ep1_ep2,
                        "parallel EP1 -> EP2"
                    );
                    ep2_count = ep2_count + 1;
                end
            end

            if (ep3_count != 1) begin
                $display(
                    "FAIL: EP0 -> EP3 delivery count = %0d, expected 1",
                    ep3_count
                );
                $fatal(1);
            end

            if (ep2_count != 1) begin
                $display(
                    "FAIL: EP1 -> EP2 delivery count = %0d, expected 1",
                    ep2_count
                );
                $fatal(1);
            end

            $display("PASS: EP0 -> EP3 delivered exactly once");
            $display("PASS: EP1 -> EP2 delivered exactly once");
            $display("PASS: simultaneous independent flows preserved integrity");
        end
    endtask

    // ------------------------------------------------------------
    // Test
    // ------------------------------------------------------------

    initial begin
        clear_inputs();

        ep0_out_ready = 1'b1;
        ep1_out_ready = 1'b1;
        ep2_out_ready = 1'b1;
        ep3_out_ready = 1'b1;

        rst = 1'b1;

        repeat (3)
            @(posedge clk);

        rst = 1'b0;

        @(posedge clk);
        #1;

        send_ep0_to_ep1();
        send_ep0_to_ep2();
        send_ep0_to_ep3();
        send_ep3_to_ep0();

        test_ep0_to_ep3_backpressure();
        test_parallel_independent_flows();

        $display("");
        $display("PASS: NoC 2x2 basic end-to-end datapath test completed");
        $finish;
    end

endmodule
