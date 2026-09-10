module cache_v2 (
    input  logic        clk,
    input  logic        rst,

    // CPU-side request
    input  logic        req_valid,
    output logic        req_ready,
    input  logic        req_write,
    input  logic [31:0] req_addr,
    input  logic [31:0] req_wdata,
    input  logic [3:0]  req_wstrb,

    // CPU-side response
    output logic        rsp_valid,
    input  logic        rsp_ready,
    output logic [31:0] rsp_rdata,

    // Backing-memory interface
    output logic        mem_valid,
    input  logic        mem_ready,
    output logic        mem_write,
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    output logic [3:0]  mem_wstrb,
    input  logic [31:0] mem_rdata
);

    typedef enum logic [2:0] {
        IDLE,
        LOOKUP,
        REFILL,
        MEM_WRITE,
        RESP
    } state_t;

    state_t state, next_state;

    // Cache: 16 lines, one 32-bit word per line.
    logic [31:0] data_array [0:15];
    logic [25:0] tag_array  [0:15];
    logic        valid_array[0:15];

    // Captured CPU request.
    logic [31:0] req_addr_q;
    logic [31:0] req_wdata_q;
    logic [3:0]  req_wstrb_q;
    logic        req_write_q;

    // Response register.
    logic [31:0] rsp_rdata_q;

    logic [3:0]  lookup_index;
    logic [25:0] lookup_tag;
    logic        lookup_hit;

    assign lookup_index = req_addr_q[5:2];
    assign lookup_tag   = req_addr_q[31:6];

    assign lookup_hit =
        valid_array[lookup_index] &&
        (tag_array[lookup_index] == lookup_tag);

    assign rsp_rdata = rsp_rdata_q;

    // Merge write data according to byte enables.
    function automatic logic [31:0] merge_wstrb(
        input logic [31:0] old_data,
        input logic [31:0] new_data,
        input logic [3:0]  wstrb
    );
        logic [31:0] merged;
        begin
            merged = old_data;

            if (wstrb[0]) merged[7:0]   = new_data[7:0];
            if (wstrb[1]) merged[15:8]  = new_data[15:8];
            if (wstrb[2]) merged[23:16] = new_data[23:16];
            if (wstrb[3]) merged[31:24] = new_data[31:24];

            merge_wstrb = merged;
        end
    endfunction

    // FSM / output logic.
    always_comb begin
        next_state = state;

        req_ready = 1'b0;
        rsp_valid = 1'b0;

        mem_valid = 1'b0;
        mem_write = 1'b0;
        mem_addr  = 32'b0;
        mem_wdata = 32'b0;
        mem_wstrb = 4'b0;

        case (state)

            IDLE: begin
                req_ready = 1'b1;

                if (req_valid)
                    next_state = LOOKUP;
            end

            LOOKUP: begin
                if (req_write_q)
                    next_state = MEM_WRITE;
                else if (lookup_hit)
                    next_state = RESP;
                else
                    next_state = REFILL;
            end

            REFILL: begin
                mem_valid = 1'b1;
                mem_write = 1'b0;
                mem_addr  = {req_addr_q[31:2], 2'b00};

                if (mem_valid && mem_ready)
                    next_state = RESP;
            end

            MEM_WRITE: begin
                mem_valid = 1'b1;
                mem_write = 1'b1;
                mem_addr  = {req_addr_q[31:2], 2'b00};
                mem_wdata = req_wdata_q;
                mem_wstrb = req_wstrb_q;

                if (mem_valid && mem_ready)
                    next_state = RESP;
            end

            RESP: begin
                rsp_valid = 1'b1;

                if (rsp_ready)
                    next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end

    // Sequential state, request, cache and response storage.
    always_ff @(posedge clk) begin
        if (rst) begin
            state        <= IDLE;
            req_addr_q   <= 32'b0;
            req_wdata_q  <= 32'b0;
            req_wstrb_q  <= 4'b0;
            req_write_q  <= 1'b0;
            rsp_rdata_q  <= 32'b0;

            for (int i = 0; i < 16; i++) begin
                data_array[i]  <= 32'b0;
                tag_array[i]   <= 26'b0;
                valid_array[i] <= 1'b0;
            end
        end
        else begin
            state <= next_state;

            if (state == IDLE && req_valid && req_ready) begin
                req_addr_q  <= req_addr;
                req_wdata_q <= req_wdata;
                req_wstrb_q <= req_wstrb;
                req_write_q <= req_write;
            end

            if (state == LOOKUP) begin
                if (!req_write_q && lookup_hit) begin
                    rsp_rdata_q <= data_array[lookup_index];
                end
            end

            if (state == REFILL && mem_valid && mem_ready) begin
                data_array[lookup_index]  <= mem_rdata;
                tag_array[lookup_index]   <= lookup_tag;
                valid_array[lookup_index] <= 1'b1;
                rsp_rdata_q               <= mem_rdata;
            end

            if (state == MEM_WRITE && mem_valid && mem_ready) begin
                if (lookup_hit) begin
                    data_array[lookup_index] <=
                        merge_wstrb(
                            data_array[lookup_index],
                            req_wdata_q,
                            req_wstrb_q
                        );
                end

                rsp_rdata_q <= 32'b0;
            end
        end
    end

endmodule
