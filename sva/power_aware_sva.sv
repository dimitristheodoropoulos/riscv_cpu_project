module power_aware_sva (
    input logic       clk,
    input logic       rst_n,
    input logic       domain_on,
    input logic       isolation_en,
    input logic       save_req,
    input logic       restore_req,
    input logic [7:0] switchable_data_out,
    input logic [7:0] data_out
);

    // Isolation contract:
    // When isolation is enabled, the consumer-visible output is clamped to zero.
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        isolation_en |-> (data_out == 8'h00)
    );

    // Transparent operation:
    // When isolation is disabled, the consumer-visible output follows
    // the switchable-domain output.
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        !isolation_en |-> (data_out == switchable_data_out)
    );

    // Save/restore requests are legal only while the switchable domain is on.
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        save_req |-> domain_on
    );

    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        restore_req |-> domain_on
    );

    // OFF-state invariant.
    // If the domain is off, isolation must remain enabled.
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        !domain_on |-> isolation_en
    );

    // Power-down sequencing:
    // SAVE is followed by ISOLATED on the next clock.
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        save_req |=> (domain_on && isolation_en &&
                      !save_req && !restore_req)
    );

    // Restore sequencing:
    // RESTORE is followed by normal ON operation.
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        restore_req |=> (domain_on && !isolation_en &&
                         !save_req && !restore_req)
    );

endmodule
