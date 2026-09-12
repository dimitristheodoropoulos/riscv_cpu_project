`timescale 1ns/1ps

module noc_router_tb;

    import noc_router_pkg::*;

    logic clk;
    logic rst;

    logic north_in_valid;
    logic north_in_ready;
    noc_packet_t north_in_packet;
    logic north_out_valid;
    logic north_out_ready;
    noc_packet_t north_out_packet;

    logic south_in_valid;
    logic south_in_ready;
    noc_packet_t south_in_packet;
    logic south_out_valid;
    logic south_out_ready;
    noc_packet_t south_out_packet;

    logic east_in_valid;
    logic east_in_ready;
    noc_packet_t east_in_packet;
    logic east_out_valid;
    logic east_out_ready;
    noc_packet_t east_out_packet;

    logic west_in_valid;
    logic west_in_ready;
    noc_packet_t west_in_packet;
    logic west_out_valid;
    logic west_out_ready;
    noc_packet_t west_out_packet;

    logic local_in_valid;
    logic local_in_ready;
    noc_packet_t local_in_packet;
    logic local_out_valid;
    logic local_out_ready;
    noc_packet_t local_out_packet;

    logic north_error_valid;
    logic [2:0] north_error_dst_id;
    logic south_error_valid;
    logic [2:0] south_error_dst_id;
    logic east_error_valid;
    logic [2:0] east_error_dst_id;
    logic west_error_valid;
    logic [2:0] west_error_dst_id;
    logic local_error_valid;
    logic [2:0] local_error_dst_id;

    noc_router #(
        .ROUTER_X(1'b0),
        .ROUTER_Y(1'b0)
    ) dut (
        .clk(clk),
        .rst(rst),

        .north_in_valid(north_in_valid),
        .north_in_ready(north_in_ready),
        .north_in_packet(north_in_packet),
        .north_out_valid(north_out_valid),
        .north_out_ready(north_out_ready),
        .north_out_packet(north_out_packet),

        .south_in_valid(south_in_valid),
        .south_in_ready(south_in_ready),
        .south_in_packet(south_in_packet),
        .south_out_valid(south_out_valid),
        .south_out_ready(south_out_ready),
        .south_out_packet(south_out_packet),

        .east_in_valid(east_in_valid),
        .east_in_ready(east_in_ready),
        .east_in_packet(east_in_packet),
        .east_out_valid(east_out_valid),
        .east_out_ready(east_out_ready),
        .east_out_packet(east_out_packet),

        .west_in_valid(west_in_valid),
        .west_in_ready(west_in_ready),
        .west_in_packet(west_in_packet),
        .west_out_valid(west_out_valid),
        .west_out_ready(west_out_ready),
        .west_out_packet(west_out_packet),

        .local_in_valid(local_in_valid),
        .local_in_ready(local_in_ready),
        .local_in_packet(local_in_packet),
        .local_out_valid(local_out_valid),
        .local_out_ready(local_out_ready),
        .local_out_packet(local_out_packet),

        .north_error_valid(north_error_valid),
        .north_error_dst_id(north_error_dst_id),
        .south_error_valid(south_error_valid),
        .south_error_dst_id(south_error_dst_id),
        .east_error_valid(east_error_valid),
        .east_error_dst_id(east_error_dst_id),
        .west_error_valid(west_error_valid),
        .west_error_dst_id(west_error_dst_id),
        .local_error_valid(local_error_valid),
        .local_error_dst_id(local_error_dst_id)
    );

    always #5 clk = ~clk;

    task automatic clear_inputs;
        begin
            north_in_valid = 1'b0;
            south_in_valid = 1'b0;
            east_in_valid  = 1'b0;
            west_in_valid  = 1'b0;
            local_in_valid = 1'b0;

            north_out_ready = 1'b0;
            south_out_ready = 1'b0;
            east_out_ready  = 1'b0;
            west_out_ready  = 1'b0;
            local_out_ready = 1'b0;

            north_in_packet = '0;
            south_in_packet = '0;
            east_in_packet  = '0;
            west_in_packet  = '0;
            local_in_packet = '0;
        end
    endtask

    task automatic check(
        input logic condition,
        input string message
    );
        begin
            if (!condition) begin
                $display("FAIL: %s", message);
                $fatal(1);
            end
            else begin
                $display("PASS: %s", message);
            end
        end
    endtask

    task automatic send_local(
        input logic [2:0] dst,
        input logic [3:0] txn,
        input logic [31:0] data
    );
        begin
            @(negedge clk);

            local_in_packet.src_id  = 3'd0;
            local_in_packet.dst_id  = dst;
            local_in_packet.txn_id  = txn;
            local_in_packet.payload = data;
            local_in_valid = 1'b1;

            check(local_in_ready, "local input ready before handshake");

            @(posedge clk);
            #1;

            @(negedge clk);
            local_in_valid = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;

        clear_inputs();

        repeat (2) @(posedge clk);
        rst = 1'b0;

        /*
         * Synchronous reset verification.
         *
         * First create a pending packet under backpressure, then assert
         * reset for one clock. The pending packet must be discarded and
         * the input slot must become available again.
         */
        local_out_ready = 1'b0;

        @(negedge clk);
        local_in_packet.src_id  = 3'd0;
        local_in_packet.dst_id  = 3'd0;
        local_in_packet.txn_id  = 4'hF;
        local_in_packet.payload = 32'hFACE_000F;
        local_in_valid = 1'b1;

        check(local_in_ready,
              "reset test input ready before handshake");

        @(posedge clk);
        #1;

        local_in_valid = 1'b0;

        check(local_out_valid,
              "reset test packet is pending before reset");

        rst = 1'b1;
        local_out_ready = 1'b1;

        @(posedge clk);
        #1;

        check(!local_out_valid,
              "reset clears pending output packet");

        check(local_in_ready,
              "reset clears occupied input slot");

        check(!north_error_valid &&
              !south_error_valid &&
              !east_error_valid &&
              !west_error_valid &&
              !local_error_valid,
              "reset clears all error indications");

        rst = 1'b0;

        /*
         * EAST-output contention / round-robin verification.
         *
         * LOCAL and NORTH both request the EAST output.
         * The EAST output starts with RR pointer at LOCAL after reset.
         * First, hold EAST ready low and verify that the selected packet
         * remains stable and no transfer occurs. Then allow the transfer
         * and verify that the other contender is served next.
         */
        local_out_ready = 1'b0;
        east_out_ready  = 1'b0;

        @(negedge clk);

        local_in_packet.src_id  = 3'd0;
        local_in_packet.dst_id  = 3'd1;
        local_in_packet.txn_id  = 4'hA;
        local_in_packet.payload = 32'hAAAA_000A;
        local_in_valid = 1'b1;

        north_in_packet.src_id  = 3'd2;
        north_in_packet.dst_id  = 3'd1;
        north_in_packet.txn_id  = 4'hB;
        north_in_packet.payload = 32'hBBBB_000B;
        north_in_valid = 1'b1;

        check(local_in_ready &&
              north_in_ready,
              "contention inputs ready before handshake");

        @(posedge clk);
        #1;

        local_in_valid = 1'b0;
        north_in_valid = 1'b0;

        check(east_out_valid,
              "EAST output has contention request");

        check(east_out_packet.src_id == 3'd0 &&
              east_out_packet.txn_id == 4'hA &&
              east_out_packet.payload == 32'hAAAA_000A,
              "RR selects LOCAL first when EAST is stalled");

        check(!east_out_ready,
              "EAST output is held under backpressure");

        east_out_ready = 1'b1;

        #1;

        check(east_out_valid,
              "EAST winner remains presented before transfer");

        check(east_out_packet.src_id == 3'd0 &&
              east_out_packet.txn_id == 4'hA,
              "LOCAL contender remains selected until handshake");

        @(posedge clk);
        #1;

        check(east_out_valid,
              "second contender remains pending after first transfer");

        check(east_out_packet.src_id == 3'd2 &&
              east_out_packet.dst_id == 3'd1 &&
              east_out_packet.txn_id == 4'hB &&
              east_out_packet.payload == 32'hBBBB_000B,
              "RR advances and serves NORTH contender next");

        @(posedge clk);
        #1;

        /*
         * LOCAL routing
         */
        local_out_ready = 1'b1;

        send_local(3'd0, 4'h1, 32'h1111_0001);

        #1;

        check(local_out_valid, "LOCAL packet reaches local output");
        check(local_out_packet.dst_id == 3'd0,
              "LOCAL destination preserved");
        check(local_out_packet.txn_id == 4'h1,
              "LOCAL transaction ID preserved");
        check(local_out_packet.payload == 32'h1111_0001,
              "LOCAL payload preserved");

        @(posedge clk);

        /*
         * EAST routing
         */
        local_out_ready = 1'b0;
        east_out_ready  = 1'b1;

        send_local(3'd1, 4'h2, 32'h2222_0002);

        #1;

        check(east_out_valid, "EAST packet reaches east output");
        check(east_out_packet.dst_id == 3'd1,
              "EAST destination preserved");
        check(east_out_packet.txn_id == 4'h2,
              "EAST transaction ID preserved");
        check(east_out_packet.payload == 32'h2222_0002,
              "EAST payload preserved");

        @(posedge clk);

        /*
         * SOUTH routing
         */
        east_out_ready  = 1'b0;
        south_out_ready = 1'b1;

        send_local(3'd2, 4'h3, 32'h3333_0003);

        #1;

        check(south_out_valid, "SOUTH packet reaches south output");
        check(south_out_packet.dst_id == 3'd2,
              "SOUTH destination preserved");

        @(posedge clk);

        /*
         * EAST from router X=0,Y=0 also covers destination (1,1):
         * first hop must be EAST.
         */
        south_out_ready = 1'b0;
        east_out_ready  = 1'b1;

        send_local(3'd3, 4'h4, 32'h4444_0004);

        #1;

        check(east_out_valid, "destination (1,1) routes EAST first");

        @(posedge clk);

        /*
         * Invalid destination from LOCAL input.
         */
        east_out_ready = 1'b0;

        @(negedge clk);

        local_in_packet.src_id  = 3'd0;
        local_in_packet.dst_id  = 3'd7;
        local_in_packet.txn_id  = 4'h5;
        local_in_packet.payload = 32'hDEAD_0005;
        local_in_valid = 1'b1;

        #1;

        check(local_in_ready, "invalid packet is accepted for error handling");
        check(local_error_valid, "LOCAL invalid destination raises error");
        check(local_error_dst_id == 3'd7,
              "LOCAL error reports original destination");

        @(posedge clk);
        @(negedge clk);

        local_in_valid = 1'b0;

        /*
         * Invalid destination verification from all five inputs.
         *
         * All five inputs are accepted simultaneously with invalid
         * destination ID 7. Each input must generate its own one-cycle
         * error indication and report the original destination.
         */
        local_out_ready = 1'b0;
        north_out_ready = 1'b0;
        south_out_ready = 1'b0;
        east_out_ready  = 1'b0;
        west_out_ready  = 1'b0;

        @(negedge clk);

        local_in_packet.src_id  = 3'd0;
        local_in_packet.dst_id  = 3'd7;
        local_in_packet.txn_id  = 4'h7;
        local_in_packet.payload = 32'h7000_0000;
        local_in_valid = 1'b1;

        north_in_packet.src_id  = 3'd1;
        north_in_packet.dst_id  = 3'd7;
        north_in_packet.txn_id  = 4'h8;
        north_in_packet.payload = 32'h7000_0001;
        north_in_valid = 1'b1;

        south_in_packet.src_id  = 3'd2;
        south_in_packet.dst_id  = 3'd7;
        south_in_packet.txn_id  = 4'h9;
        south_in_packet.payload = 32'h7000_0002;
        south_in_valid = 1'b1;

        east_in_packet.src_id  = 3'd3;
        east_in_packet.dst_id  = 3'd7;
        east_in_packet.txn_id  = 4'hA;
        east_in_packet.payload = 32'h7000_0003;
        east_in_valid = 1'b1;

        west_in_packet.src_id  = 3'd0;
        west_in_packet.dst_id  = 3'd7;
        west_in_packet.txn_id  = 4'hB;
        west_in_packet.payload = 32'h7000_0004;
        west_in_valid = 1'b1;

        #1;

        check(local_in_ready &&
              north_in_ready &&
              south_in_ready &&
              east_in_ready &&
              west_in_ready,
              "all five invalid inputs are accepted");

        check(local_error_valid &&
              north_error_valid &&
              south_error_valid &&
              east_error_valid &&
              west_error_valid,
              "all five invalid inputs raise independent errors");

        check(local_error_dst_id == 3'd7 &&
              north_error_dst_id == 3'd7 &&
              south_error_dst_id == 3'd7 &&
              east_error_dst_id == 3'd7 &&
              west_error_dst_id == 3'd7,
              "all five errors report original invalid destination");

        @(posedge clk);

        local_in_valid = 1'b0;
        north_in_valid = 1'b0;
        south_in_valid = 1'b0;
        east_in_valid  = 1'b0;
        west_in_valid  = 1'b0;

        #1;

        check(!local_error_valid &&
              !north_error_valid &&
              !south_error_valid &&
              !east_error_valid &&
              !west_error_valid,
              "invalid error indications clear after acceptance");

        check(local_in_ready &&
              north_in_ready &&
              south_in_ready &&
              east_in_ready &&
              west_in_ready,
              "invalid packets are rejected without occupying input slots");

        /*
         * Same-flow ordering verification.
         *
         * Two packets with the same src_id and dst_id are injected in
         * order under output backpressure. The first packet must be
         * delivered before the second packet.
         */
        local_out_ready = 1'b0;

        @(negedge clk);

        local_in_packet.src_id  = 3'd1;
        local_in_packet.dst_id  = 3'd0;
        local_in_packet.txn_id  = 4'hC;
        local_in_packet.payload = 32'h1111_00C1;
        local_in_valid = 1'b1;

        check(local_in_ready,
              "first ordered packet input ready");

        @(posedge clk);
        #1;

        check(local_out_valid &&
              local_out_packet.src_id == 3'd1 &&
              local_out_packet.dst_id == 3'd0 &&
              local_out_packet.txn_id == 4'hC &&
              local_out_packet.payload == 32'h1111_00C1,
              "first same-flow packet is presented first");

        local_in_packet.src_id  = 3'd1;
        local_in_packet.dst_id  = 3'd0;
        local_in_packet.txn_id  = 4'hD;
        local_in_packet.payload = 32'h2222_00D1;

        check(!local_in_ready,
              "second same-flow packet waits behind first packet");

        local_out_ready = 1'b1;

        #1;

        check(local_out_valid &&
              local_out_packet.txn_id == 4'hC &&
              local_out_packet.payload == 32'h1111_00C1,
              "first same-flow packet remains ahead until handshake");

        @(posedge clk);
        #1;

          @(posedge clk);
          #1;
        check(local_out_valid &&
              local_out_packet.src_id == 3'd1 &&
              local_out_packet.dst_id == 3'd0 &&
              local_out_packet.txn_id == 4'hD &&
              local_out_packet.payload == 32'h2222_00D1,
              "second same-flow packet is delivered after first");

        @(posedge clk);
        #1;

        local_in_valid = 1'b0;

        /*
         * Backpressure.
         */
        local_out_ready = 1'b0;

        local_in_packet.src_id  = 3'd0;
        local_in_packet.dst_id  = 3'd0;
        local_in_packet.txn_id  = 4'h6;
        local_in_packet.payload = 32'h6666_0006;
        local_in_valid = 1'b1;

        @(posedge clk);
        #1;

        local_in_valid = 1'b0;

        check(local_out_valid,
              "output remains valid under backpressure");
        check(local_out_packet.payload == 32'h6666_0006,
              "packet remains stable under backpressure");
        check(!local_in_ready,
              "input slot remains occupied under backpressure");

        local_out_ready = 1'b1;

        #1;

        check(local_out_valid,
              "packet remains presented until handshake");

        @(posedge clk);
        #1;

        $display("PASS: NoC router functional smoke test completed");
        $finish;
    end

endmodule
