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
    // Complete legal endpoint traffic matrix
    //
    // Exercise all 16 legal src/dst combinations in the 2x2 mesh:
    //   - 4 local/self-delivery cases
    //   - all one-hop cases
    //   - all legal multi-hop/reverse paths
    //
    // This is executable traffic-space coverage only; no DUT changes.
    // ------------------------------------------------------------

    task automatic send_matrix_packet(
        input integer src_ep,
        input integer dst_ep,
        input [3:0] txn_id
    );
        noc_packet_t expected;
        begin
            expected.src_id  = src_ep[2:0];
            expected.dst_id  = dst_ep[2:0];
            expected.txn_id  = txn_id;
            expected.payload = 32'hC000_0000 |
                               (src_ep << 8) |
                               dst_ep;

            case (src_ep)
                0: begin
                    ep0_in_packet = expected;
                    ep0_in_valid  = 1'b1;
                    wait (ep0_in_ready === 1'b1);
                    @(posedge clk);
                    #1;
                    ep0_in_valid = 1'b0;
                end

                1: begin
                    ep1_in_packet = expected;
                    ep1_in_valid  = 1'b1;
                    wait (ep1_in_ready === 1'b1);
                    @(posedge clk);
                    #1;
                    ep1_in_valid = 1'b0;
                end

                2: begin
                    ep2_in_packet = expected;
                    ep2_in_valid  = 1'b1;
                    wait (ep2_in_ready === 1'b1);
                    @(posedge clk);
                    #1;
                    ep2_in_valid = 1'b0;
                end

                3: begin
                    ep3_in_packet = expected;
                    ep3_in_valid  = 1'b1;
                    wait (ep3_in_ready === 1'b1);
                    @(posedge clk);
                    #1;
                    ep3_in_valid = 1'b0;
                end

                default: begin
                    $display("FAIL: invalid matrix source EP%0d", src_ep);
                    $fatal(1);
                end
            endcase

            case (dst_ep)
                0: begin
                    wait (ep0_out_valid === 1'b1);
                    check_packet(
                        ep0_out_packet,
                        expected,
                        $sformatf("traffic matrix EP%0d -> EP%0d",
                                  src_ep, dst_ep)
                    );
                    @(posedge clk);
                    #1;
                end

                1: begin
                    wait (ep1_out_valid === 1'b1);
                    check_packet(
                        ep1_out_packet,
                        expected,
                        $sformatf("traffic matrix EP%0d -> EP%0d",
                                  src_ep, dst_ep)
                    );
                    @(posedge clk);
                    #1;
                end

                2: begin
                    wait (ep2_out_valid === 1'b1);
                    check_packet(
                        ep2_out_packet,
                        expected,
                        $sformatf("traffic matrix EP%0d -> EP%0d",
                                  src_ep, dst_ep)
                    );
                    @(posedge clk);
                    #1;
                end

                3: begin
                    wait (ep3_out_valid === 1'b1);
                    check_packet(
                        ep3_out_packet,
                        expected,
                        $sformatf("traffic matrix EP%0d -> EP%0d",
                                  src_ep, dst_ep)
                    );
                    @(posedge clk);
                    #1;
                end

                default: begin
                    $display("FAIL: invalid matrix destination EP%0d", dst_ep);
                    $fatal(1);
                end
            endcase

            $display(
                "PASS: traffic matrix EP%0d -> EP%0d",
                src_ep,
                dst_ep
            );
        end
    endtask

    task automatic test_complete_endpoint_traffic_matrix;
        integer src_ep;
        integer dst_ep;
        integer txn;
        begin
            txn = 0;

            for (src_ep = 0; src_ep < 4; src_ep = src_ep + 1) begin
                for (dst_ep = 0; dst_ep < 4; dst_ep = dst_ep + 1) begin
                    send_matrix_packet(
                        src_ep,
                        dst_ep,
                        txn[3:0]
                    );
                    txn = txn + 1;
                end
            end

            $display("PASS: complete 4x4 legal endpoint traffic matrix");
        end
    endtask

    // ------------------------------------------------------------
    // Mesh hotspot contention + intermediate-link backpressure
    //
    // Three independent sources target the same destination:
    //   EP0 -> EP3
    //   EP1 -> EP3
    //   EP2 -> EP3
    //
    // EP3 is stalled so that R11 becomes blocked.  Observe the
    // R01->R11 and R10->R11 internal valid/ready links explicitly.
    //
    // This is TB-only verification observation; no DUT changes.
    // ------------------------------------------------------------

    task automatic test_three_way_hotspot_backpressure;
        noc_packet_t pkt_ep0_ep3;
        noc_packet_t pkt_ep1_ep3;
        noc_packet_t pkt_ep2_ep3;

        noc_packet_t held_r01_south_packet;
        noc_packet_t held_r10_east_packet;

        integer ep3_count;
        integer cycles;
        logic seen_txn8;
        logic seen_txn9;
        logic seen_txn10;
        logic observed_r01_backpressure;
        logic observed_r10_backpressure;

        begin
            pkt_ep0_ep3.src_id   = 3'd0;
            pkt_ep0_ep3.dst_id   = 3'd3;
            pkt_ep0_ep3.txn_id   = 4'h8;
            pkt_ep0_ep3.payload  = 32'h8000_0001;

            pkt_ep1_ep3.src_id   = 3'd1;
            pkt_ep1_ep3.dst_id   = 3'd3;
            pkt_ep1_ep3.txn_id   = 4'h9;
            pkt_ep1_ep3.payload  = 32'h8000_0002;

            pkt_ep2_ep3.src_id   = 3'd2;
            pkt_ep2_ep3.dst_id   = 3'd3;
            pkt_ep2_ep3.txn_id   = 4'hA;
            pkt_ep2_ep3.payload  = 32'h8000_0003;

            ep3_count = 0;
            seen_txn8 = 1'b0;
            seen_txn9 = 1'b0;
            seen_txn10 = 1'b0;
            observed_r01_backpressure = 1'b0;
            observed_r10_backpressure = 1'b0;

            ep3_out_ready = 1'b0;

            // Present all three hotspot contenders concurrently.
            ep0_in_packet = pkt_ep0_ep3;
            ep1_in_packet = pkt_ep1_ep3;
            ep2_in_packet = pkt_ep2_ep3;

            ep0_in_valid = 1'b1;
            ep1_in_valid = 1'b1;
            ep2_in_valid = 1'b1;

            // Each source must be accepted by its local router.
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

                begin
                    wait (ep2_in_ready === 1'b1);
                    @(posedge clk);
                    #1;
                    ep2_in_valid = 1'b0;
                end
            join

            #1;



            // EP3 must remain stalled while the three contenders
            // propagate toward R11.
            repeat (6) begin
                @(posedge clk);
                #1;


                if (ep3_out_valid === 1'b1 &&
                    ep3_out_ready === 1'b1) begin
                    $display(
                        "FAIL: EP3 produced a delivery while EP3 was stalled"
                    );
                    $fatal(1);
                end

                // R01 -> R11 intermediate link.
                if (dut.r01_south_out_valid === 1'b1) begin
                    if (dut.r01_south_out_ready === 1'b0) begin
                        observed_r01_backpressure = 1'b1;
                    end
                end

                // R10 -> R11 intermediate link.
                if (dut.r10_east_out_valid === 1'b1) begin
                    if (dut.r10_east_out_ready === 1'b0) begin
                        observed_r10_backpressure = 1'b1;
                    end
                end
            end

            if (dut.r01_south_out_ready !== dut.r11_north_in_ready) begin
                $display(
                    "FAIL: R01->R11 ready connection is inconsistent"
                );
                $fatal(1);
            end

            if (dut.r10_east_out_ready !== dut.r11_west_in_ready) begin
                $display(
                    "FAIL: R10->R11 ready connection is inconsistent"
                );
                $fatal(1);
            end

            // Capture any currently stalled intermediate packets and
            // verify that they remain stable while the downstream
            // destination is blocked.
            if (dut.r01_south_out_valid === 1'b1 &&
                dut.r01_south_out_ready === 1'b0) begin

                held_r01_south_packet = dut.r01_south_out_packet;

                repeat (2) begin
                    @(posedge clk);
                    #1;

                    if (dut.r01_south_out_valid !== 1'b1) begin
                        $display(
                            "FAIL: R01->R11 valid dropped while stalled"
                        );
                        $fatal(1);
                    end

                    if (dut.r01_south_out_packet !==
                        held_r01_south_packet) begin
                        $display(
                            "FAIL: R01->R11 packet changed while stalled"
                        );
                        $fatal(1);
                    end

                    if (dut.r01_south_out_ready !== 1'b0) begin
                        $display(
                            "FAIL: R01->R11 ready changed during stall"
                        );
                        $fatal(1);
                    end
                end
            end

            if (dut.r10_east_out_valid === 1'b1 &&
                dut.r10_east_out_ready === 1'b0) begin

                held_r10_east_packet = dut.r10_east_out_packet;

                repeat (2) begin
                    @(posedge clk);
                    #1;

                    if (dut.r10_east_out_valid !== 1'b1) begin
                        $display(
                            "FAIL: R10->R11 valid dropped while stalled"
                        );
                        $fatal(1);
                    end

                    if (dut.r10_east_out_packet !==
                        held_r10_east_packet) begin
                        $display(
                            "FAIL: R10->R11 packet changed while stalled"
                        );
                        $fatal(1);
                    end

                    if (dut.r10_east_out_ready !== 1'b0) begin
                        $display(
                            "FAIL: R10->R11 ready changed during stall"
                        );
                        $fatal(1);
                    end
                end
            end

            // At least one of the two intermediate links must have
            // experienced actual valid/ready backpressure.
            if (!observed_r01_backpressure &&
                !observed_r10_backpressure) begin
                $display(
                    "FAIL: no intermediate-link backpressure was observed"
                );
                $fatal(1);
            end

            $display(
                "PASS: three-way EP0/EP1/EP2 -> EP3 hotspot established"
            );

            if (observed_r01_backpressure) begin
                $display(
                    "PASS: R01 -> R11 intermediate backpressure observed"
                );
            end

            if (observed_r10_backpressure) begin
                $display(
                    "PASS: R10 -> R11 intermediate backpressure observed"
                );
            end

            #1;



            // Release the hotspot destination.
            ep3_out_ready = 1'b1;

            // Observe deliveries at the actual VALID/READY handshake edge.
            // The packet is sampled before the clock edge; #1 is used only
            // after the edge to allow DUT state updates before the next loop.
            for (cycles = 0; cycles < 20; cycles = cycles + 1) begin

                if (ep3_out_valid === 1'b1 &&
                    ep3_out_ready === 1'b1) begin

                    ep3_count = ep3_count + 1;

                    if (ep3_out_packet.txn_id === pkt_ep0_ep3.txn_id) begin
                        if (seen_txn8) begin
                            $display(
                                "FAIL: duplicate EP0 -> EP3 transaction"
                            );
                            $fatal(1);
                        end

                        check_packet(
                            ep3_out_packet,
                            pkt_ep0_ep3,
                            "hotspot EP0 -> EP3"
                        );
                        seen_txn8 = 1'b1;

                    end else if (
                        ep3_out_packet.txn_id === pkt_ep1_ep3.txn_id
                    ) begin
                        if (seen_txn9) begin
                            $display(
                                "FAIL: duplicate EP1 -> EP3 transaction"
                            );
                            $fatal(1);
                        end

                        check_packet(
                            ep3_out_packet,
                            pkt_ep1_ep3,
                            "hotspot EP1 -> EP3"
                        );
                        seen_txn9 = 1'b1;

                    end else if (
                        ep3_out_packet.txn_id === pkt_ep2_ep3.txn_id
                    ) begin
                        if (seen_txn10) begin
                            $display(
                                "FAIL: duplicate EP2 -> EP3 transaction"
                            );
                            $fatal(1);
                        end

                        check_packet(
                            ep3_out_packet,
                            pkt_ep2_ep3,
                            "hotspot EP2 -> EP3"
                        );
                        seen_txn10 = 1'b1;

                    end else begin
                        $display(
                            "FAIL: unexpected EP3 transaction id %0d",
                            ep3_out_packet.txn_id
                        );
                        $fatal(1);
                    end
                end

                @(posedge clk);
                #1;
            end

            if (ep3_count != 3 ||
                !seen_txn8 ||
                !seen_txn9 ||
                !seen_txn10) begin
                $display(
                    "FAIL: hotspot delivery count=%0d seen_txn8=%0d seen_txn9=%0d seen_txn10=%0d",
                    ep3_count,
                    seen_txn8,
                    seen_txn9,
                    seen_txn10
                );
                $fatal(1);
            end

            $display(
                "PASS: three-way hotspot delivered all packets exactly once"
            );
            $display(
                "PASS: hotspot packet integrity preserved under backpressure"
            );
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
        test_complete_endpoint_traffic_matrix();
        test_three_way_hotspot_backpressure();

        $display("");
        $display("PASS: NoC 2x2 basic end-to-end datapath test completed");
        $finish;
    end

endmodule
