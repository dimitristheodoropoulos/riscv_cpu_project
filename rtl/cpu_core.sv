module cpu_core (
    input clk,
    input reset,
    output [31:0] result
);

wire [31:0] alu_result;

wire [31:0] reg1_data;
wire [31:0] reg2_data;

wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;

wire [3:0] alu_op;
wire is_fp;

wire [31:0] mmu_virtual_addr;
wire [31:0] mmu_data_in;
wire [31:0] mmu_data_out;

wire mmu_mem_read;
wire mmu_mem_write;
wire mmu_ready;
wire [31:0] mmu_physical_addr;

wire [31:0] cache_data_out;
wire cache_hit;
wire cache_miss;
wire [31:0] cache_physical_addr;

/*
 * Temporary deterministic integration configuration.
 *
 * This is intentionally not presented as a complete CPU.
 * It provides a stable integration path until the instruction
 * decode / control / writeback path is implemented.
 */

assign rs1 = 5'd0;
assign rs2 = 5'd0;
assign rd = 5'd1;

assign alu_op = 4'b0010;
assign is_fp = 1'b0;

/*
 * The register file keeps x0 hardwired to zero.
 * Therefore the ALU receives deterministic zero operands.
 */

register_file rf (
    .clk(clk),
    .reset(reset),

    .read_addr1(rs1),
    .read_addr2(rs2),

    .write_addr(rd),
    .write_data(alu_result),
    .write_enable(1'b0),

    .is_fp(is_fp),

    .read_data1(reg1_data),
    .read_data2(reg2_data)
);

alu alu_unit (
    .A(reg1_data),
    .B(reg2_data),
    .Op(alu_op),
    .Result(alu_result),
    .zero(),
    .overflow()
);

/*
 * Memory interface.
 *
 * For the current integration smoke test we keep the interface
 * deterministic and disabled.
 */

assign mmu_virtual_addr = alu_result;
assign mmu_data_in = 32'b0;

assign mmu_mem_read = 1'b0;
assign mmu_mem_write = 1'b0;

mmu mmu_unit (
    .clk(clk),
    .virtual_addr(mmu_virtual_addr),
    .data_in(mmu_data_in),
    .mem_read(mmu_mem_read),
    .mem_write(mmu_mem_write),
    .data_out(mmu_data_out),
    .physical_addr(mmu_physical_addr),
    .mem_ready(mmu_ready)
);

cache cache_unit (
    .virtual_addr(mmu_virtual_addr),
    .data_in(mmu_data_in),
    .mem_read(mmu_mem_read),
    .mem_write(mmu_mem_write),
    .data_out(cache_data_out),
    .hit(cache_hit),
    .miss(cache_miss),
    .physical_addr(cache_physical_addr)
);

assign result = alu_result;

endmodule