module memory_controller (
    input  logic        clk,
    input  logic        rst,

    input  logic        mem_valid,
    output logic        mem_ready,
    input  logic        mem_write,
    input  logic [31:0] mem_addr,
    input  logic [31:0] mem_wdata,
    input  logic [3:0]  mem_wstrb,
    output logic [31:0] mem_rdata
);

    localparam int DEPTH_WORDS = 256;

    logic [31:0] memory [0:DEPTH_WORDS-1];

    logic [7:0] word_index;

    assign word_index = mem_addr[9:2];

    /*
     * v1 completion semantics:
     *
     * mem_valid && mem_ready
     *     = request acceptance
     *     = transaction completion
     *
     * No separate response phase exists.
     */
    always_comb begin
        mem_ready = !rst;
        mem_rdata = memory[word_index];
    end

    /*
     * Writes are committed on the accepted request edge.
     * WSTRB[0] selects bits [7:0], etc.
     *
     * Reset does not clear the storage array. The contract does
     * not require destructive memory initialization on reset.
     */
    always_ff @(posedge clk) begin
        if (!rst) begin
            if (mem_valid && mem_ready && mem_write) begin
                if (mem_wstrb[0])
                    memory[word_index][7:0]   <= mem_wdata[7:0];

                if (mem_wstrb[1])
                    memory[word_index][15:8]  <= mem_wdata[15:8];

                if (mem_wstrb[2])
                    memory[word_index][23:16] <= mem_wdata[23:16];

                if (mem_wstrb[3])
                    memory[word_index][31:24] <= mem_wdata[31:24];
            end
        end
    end

endmodule
