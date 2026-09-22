module power_aware_coverage (
    input logic       domain_on,
    input logic       isolation_en,
    input logic       save_req,
    input logic       restore_req
);

    logic [2:0] operating_mode;

    localparam logic [2:0] MODE_ON        = 3'd0;
    localparam logic [2:0] MODE_SAVE      = 3'd1;
    localparam logic [2:0] MODE_ISOLATED  = 3'd2;
    localparam logic [2:0] MODE_OFF       = 3'd3;
    localparam logic [2:0] MODE_RESTORE   = 3'd4;

    always_comb begin
        operating_mode = MODE_ON;

        if (!domain_on)
            operating_mode = MODE_OFF;
        else if (restore_req)
            operating_mode = MODE_RESTORE;
        else if (save_req)
            operating_mode = MODE_SAVE;
        else if (isolation_en)
            operating_mode = MODE_ISOLATED;
    end

    covergroup power_cg;

        cp_mode: coverpoint operating_mode {
            bins on       = {MODE_ON};
            bins save     = {MODE_SAVE};
            bins isolated = {MODE_ISOLATED};
            bins off      = {MODE_OFF};
            bins restore  = {MODE_RESTORE};

            bins power_down_sequence =
                (MODE_ON => MODE_SAVE => MODE_ISOLATED => MODE_OFF);

            bins wake_sequence =
                (MODE_OFF => MODE_RESTORE => MODE_ON);
        }

        cp_isolation: coverpoint isolation_en {
            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }

        cp_save: coverpoint save_req {
            bins inactive = {1'b0};
            bins active   = {1'b1};
        }

        cp_restore: coverpoint restore_req {
            bins inactive = {1'b0};
            bins active   = {1'b1};
        }

    endgroup

    power_cg cg = new();

    task automatic sample();
        cg.sample();
    endtask

endmodule
