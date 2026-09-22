`timescale 1ns/1ps

module power_aware_tb;

    logic       clk;
    logic       rst_n;
    logic       power_down_req;
    logic       wake_req;
    logic [7:0] data_in;

    logic       domain_on;
    logic       isolation_en;
    logic       save_req;
    logic       restore_req;
    logic [7:0] data_out;
    logic [7:0] switchable_data_out;
    logic [7:0] retained_state;

    int errors;

    pa_power_controller u_controller (
        .clk            (clk),
        .rst_n          (rst_n),
        .power_down_req (power_down_req),
        .wake_req       (wake_req),
        .domain_on      (domain_on),
        .isolation_en   (isolation_en),
        .save_req       (save_req),
        .restore_req    (restore_req)
    );

    pa_switchable_block u_switchable (
        .clk           (clk),
        .rst_n         (rst_n),
        .domain_on     (domain_on),
        .save_req      (save_req),
        .restore_req   (restore_req),
        .data_in       (data_in),
        .data_out      (switchable_data_out),
        .retained_state(retained_state)
    );

    pa_isolation_boundary u_isolation (
        .isolation_en (isolation_en),
        .data_in      (switchable_data_out),
        .data_out     (data_out)
    );

    power_aware_sva u_sva (
        .clk                (clk),
        .rst_n              (rst_n),
        .domain_on          (domain_on),
        .isolation_en       (isolation_en),
        .save_req           (save_req),
        .restore_req        (restore_req),
        .switchable_data_out(switchable_data_out),
        .data_out           (data_out)
    );

`ifdef ENABLE_POWER_AWARE_COVERAGE
    power_aware_coverage u_coverage (
        .domain_on    (domain_on),
        .isolation_en (isolation_en),
        .save_req     (save_req),
        .restore_req  (restore_req)
    );
`endif

    always #5 clk = ~clk;

    task automatic check_outputs(
        input logic       exp_domain_on,
        input logic       exp_isolation_en,
        input logic       exp_save_req,
        input logic       exp_restore_req,
        input logic [7:0] exp_data_out
    );
        begin
`ifdef ENABLE_POWER_AWARE_COVERAGE
            u_coverage.sample();
`endif
            if (domain_on !== exp_domain_on) begin
                $display("ERROR: domain_on expected=%0b actual=%0b",
                         exp_domain_on, domain_on);
                errors++;
            end

            if (isolation_en !== exp_isolation_en) begin
                $display("ERROR: isolation_en expected=%0b actual=%0b",
                         exp_isolation_en, isolation_en);
                errors++;
            end

            if (save_req !== exp_save_req) begin
                $display("ERROR: save_req expected=%0b actual=%0b",
                         exp_save_req, save_req);
                errors++;
            end

            if (restore_req !== exp_restore_req) begin
                $display("ERROR: restore_req expected=%0b actual=%0b",
                         exp_restore_req, restore_req);
                errors++;
            end

            if (data_out !== exp_data_out) begin
                $display("ERROR: data_out expected=%02h actual=%02h",
                         exp_data_out, data_out);
                errors++;
            end
        end
    endtask

    initial begin
        clk            = 1'b0;
        rst_n          = 1'b0;
        power_down_req = 1'b0;
        wake_req       = 1'b0;
        data_in        = 8'h00;
        errors         = 0;

        // Reset -> ON
        #2;
        check_outputs(1'b1, 1'b0, 1'b0, 1'b0, 8'h00);

        rst_n = 1'b1;

        // Normal operation: write retained candidate state.
        data_in = 8'h5A;
        @(posedge clk);
        #1;
        check_outputs(1'b1, 1'b0, 1'b0, 1'b0, 8'h5A);

        // Request power-down: ON -> SAVE.
        power_down_req = 1'b1;
        @(posedge clk);
        #1;
        check_outputs(1'b1, 1'b0, 1'b1, 1'b0, 8'h5A);

        // SAVE -> ISOLATED.
        power_down_req = 1'b0;
        @(posedge clk);
        #1;
        check_outputs(1'b1, 1'b1, 1'b0, 1'b0, 8'h00);

        // ISOLATED -> OFF.
        @(posedge clk);
        #1;
        check_outputs(1'b0, 1'b1, 1'b0, 1'b0, 8'h00);

        if (retained_state !== 8'h5A) begin
            $display("ERROR: retained_state expected=5A actual=%02h",
                     retained_state);
            errors++;
        end

        // Illegal/no wake request: remain OFF.
        @(posedge clk);
        #1;
        check_outputs(1'b0, 1'b1, 1'b0, 1'b0, 8'h00);

        // Wake-up: OFF -> RESTORE.
        wake_req = 1'b1;
        @(posedge clk);
        #1;
        check_outputs(1'b1, 1'b1, 1'b0, 1'b1, 8'h00);

        // RESTORE -> ON.
        wake_req = 1'b0;
        @(posedge clk);
        #1;
        check_outputs(1'b1, 1'b0, 1'b0, 1'b0, 8'h5A);

        if (errors == 0)
            $display("POWER_AWARE_TB: PASS");
        else
            $display("POWER_AWARE_TB: FAIL (%0d errors)", errors);

        $finish;
    end

endmodule
