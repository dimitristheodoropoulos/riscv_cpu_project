// cpu_exec_core.sv
//
// Minimal single-cycle RV32I execution core.

module cpu_exec_core (
    input  logic        clk,
    input  logic        reset,

    // Testbench-only execution control
    input  logic        execution_enable,

    // Synthesizable instruction-memory programming interface
    input  logic        instr_mem_we,
    input  logic [5:0]  instr_mem_waddr,
    input  logic [31:0] instr_mem_wdata,

    // Testbench-only register initialization interface
    input  logic        reg_init_enable,
    input  logic [4:0]  reg_init_addr,
    input  logic [31:0] reg_init_data,
    input  logic        reg_init_is_fp,

    output logic [31:0] pc,
    output logic [31:0] result
);


    // --------------------------------------------------------
    // Instruction fetch
    // --------------------------------------------------------

    logic [31:0] instruction;
    logic [31:0] instr_mem [0:63];
    logic [31:0] next_pc;


    always_ff @(posedge clk) begin
        if (instr_mem_we)
            instr_mem[instr_mem_waddr] <= instr_mem_wdata;
    end


    integer i;


    // --------------------------------------------------------
    // PC logic
    //
    // PC increments by 4 only when execution is enabled.
    // During program/register initialization, execution_enable
    // is deasserted so the PC remains at zero.
    // --------------------------------------------------------

    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin

            pc <= 32'h00000000;

        end
        else if (execution_enable) begin

            if (instruction != 32'h00000000)
                pc <= next_pc;

        end

    end


    always_comb begin

        instruction =
            instr_mem[pc[7:2]];

    end


    // --------------------------------------------------------
    // Control Unit
    // --------------------------------------------------------

    logic [3:0]  cu_alu_op;

    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;

    logic is_fp;

    logic mem_read;
    logic mem_write;
    logic reg_write;

    logic [31:0] imm_ext;
    logic        branch;


    cu u_cu (

        .instruction (instruction),

        .ALU_op      (cu_alu_op),

        .rs1         (rs1),
        .rs2         (rs2),
        .rd          (rd),

        .is_fp       (is_fp),

        .mem_read    (mem_read),
        .mem_write   (mem_write),

        .reg_write   (reg_write),

        .imm_ext     (imm_ext),

        .branch      (branch)

    );



    // --------------------------------------------------------
    // Register File
    // --------------------------------------------------------

    logic [31:0] reg1_data;
    logic [31:0] reg2_data;

    logic [31:0] writeback_data;


    register_file u_rf (

        .clk          (clk),

        .reset        (reset),


        .read_addr1   (rs1),
        .read_addr2   (rs2),


        .write_addr   (reg_init_enable ? reg_init_addr : rd),

        .write_data   (reg_init_enable ? reg_init_data : writeback_data),

        .write_enable (reg_init_enable ? 1'b1      : reg_write),

        .is_fp        (reg_init_enable ? reg_init_is_fp : is_fp),


        .read_data1   (reg1_data),

        .read_data2   (reg2_data)

    );



    // --------------------------------------------------------
    // Branch / next-PC control
    //
    // Supported conditional branches:
    //   BEQ, BNE, BLT, BGE
    //
    // Taken branch target = PC + B-immediate.
    // Not-taken path = PC + 4.
    // --------------------------------------------------------

    logic        branch_taken;

    always_comb begin

        branch_taken = 1'b0;

        if (branch) begin

            case (instruction[14:12])

                3'b000:
                    branch_taken = (reg1_data == reg2_data); // BEQ

                3'b001:
                    branch_taken = (reg1_data != reg2_data); // BNE

                3'b100:
                    branch_taken =
                        ($signed(reg1_data) < $signed(reg2_data)); // BLT

                3'b101:
                    branch_taken =
                        ($signed(reg1_data) >= $signed(reg2_data)); // BGE

                default:
                    branch_taken = 1'b0;

            endcase

        end

    end

    assign next_pc =
        (branch && branch_taken)
            ? pc + imm_ext
            : pc + 32'd4;


    // ALU
    // --------------------------------------------------------

    logic        is_mem;

    logic [3:0] alu_op_eff;

    logic [31:0] alu_b;

    logic [31:0] alu_result;



    assign is_mem =
        mem_read || mem_write;



    assign alu_op_eff =
        is_mem ? 4'b0010 :
                 cu_alu_op;



    assign alu_b =
        is_mem ? imm_ext :
                 reg2_data;



    alu u_alu (

        .A        (reg1_data),

        .B        (alu_b),

        .Op       (alu_op_eff),

        .Result   (alu_result),

        .zero     (),

        .overflow ()

    );



    // --------------------------------------------------------
    // Data Memory
    // --------------------------------------------------------

    logic [31:0] mmu_data_out;


    mmu u_mmu (

        .clk          (clk),

        .reset        (reset),

        .virtual_addr (alu_result),

        .data_in      (reg2_data),

        .mem_read     (mem_read),

        .mem_write    (mem_write),

        .data_out     (mmu_data_out),

        .physical_addr(),

        .mem_ready    ()

    );



    // --------------------------------------------------------
    // Writeback
    // --------------------------------------------------------

    assign writeback_data =
        mem_read ?
        mmu_data_out :
        alu_result;



    assign result =
        alu_result;



endmodule
