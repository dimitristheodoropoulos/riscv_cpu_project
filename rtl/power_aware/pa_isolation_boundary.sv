module pa_isolation_boundary (
    input  logic       isolation_en,
    input  logic [7:0] data_in,
    output logic [7:0] data_out
);

    always_comb begin
        if (isolation_en)
            data_out = 8'h00;
        else
            data_out = data_in;
    end

endmodule
