package cpu_exec_random_sequence_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import cpu_pkg::*;
  import cpu_agent_pkg::*;

  class cpu_exec_random_sequence extends uvm_sequence #(cpu_transaction);

    `uvm_object_utils(cpu_exec_random_sequence)

    localparam int unsigned PROGRAM_LEN = 8;

    typedef enum int unsigned {
      OP_ADD,
      OP_SUB,
      OP_AND,
      OP_OR,
      OP_XOR,
      OP_SLL,
      OP_SRA,
      OP_SLT
    } random_op_e;

    typedef enum int unsigned {
      REG_ZERO,
      REG_NONZERO
    } reg_class_e;

    typedef enum int unsigned {
      VAL_ZERO,
      VAL_POS,
      VAL_NEG,
      VAL_MAX,
      VAL_MIN,
      VAL_OTHER
    } value_class_e;

    int unsigned seed;

    function new(string name = "cpu_exec_random_sequence");
      super.new(name);
    endfunction

    // ------------------------------------------------------------
    // RV32I R-type encoder
    // ------------------------------------------------------------
    function automatic bit [31:0] encode_rtype(
      input bit [6:0] funct7,
      input bit [4:0] rs2,
      input bit [4:0] rs1,
      input bit [2:0] funct3,
      input bit [4:0] rd
    );
      return {
        funct7,
        rs2,
        rs1,
        funct3,
        rd,
        7'b0110011
      };
    endfunction

    // ------------------------------------------------------------
    // Explicit legal RV32I encoders
    // ------------------------------------------------------------
    function automatic bit [31:0] encode_add(
      input bit [4:0] rd,
      input bit [4:0] rs1,
      input bit [4:0] rs2
    );
      return encode_rtype(7'b0000000, rs2, rs1, 3'b000, rd);
    endfunction

    function automatic bit [31:0] encode_sub(
      input bit [4:0] rd,
      input bit [4:0] rs1,
      input bit [4:0] rs2
    );
      return encode_rtype(7'b0100000, rs2, rs1, 3'b000, rd);
    endfunction

    function automatic bit [31:0] encode_and(
      input bit [4:0] rd,
      input bit [4:0] rs1,
      input bit [4:0] rs2
    );
      return encode_rtype(7'b0000000, rs2, rs1, 3'b111, rd);
    endfunction

    function automatic bit [31:0] encode_or(
      input bit [4:0] rd,
      input bit [4:0] rs1,
      input bit [4:0] rs2
    );
      return encode_rtype(7'b0000000, rs2, rs1, 3'b110, rd);
    endfunction

    function automatic bit [31:0] encode_xor(
      input bit [4:0] rd,
      input bit [4:0] rs1,
      input bit [4:0] rs2
    );
      return encode_rtype(7'b0000000, rs2, rs1, 3'b100, rd);
    endfunction

    function automatic bit [31:0] encode_sll(
      input bit [4:0] rd,
      input bit [4:0] rs1,
      input bit [4:0] rs2
    );
      return encode_rtype(7'b0000000, rs2, rs1, 3'b001, rd);
    endfunction

    function automatic bit [31:0] encode_sra(
      input bit [4:0] rd,
      input bit [4:0] rs1,
      input bit [4:0] rs2
    );
      return encode_rtype(7'b0100000, rs2, rs1, 3'b101, rd);
    endfunction

    function automatic bit [31:0] encode_slt(
      input bit [4:0] rd,
      input bit [4:0] rs1,
      input bit [4:0] rs2
    );
      return encode_rtype(7'b0000000, rs2, rs1, 3'b010, rd);
    endfunction

    // ------------------------------------------------------------
    // Controlled register selection
    // ------------------------------------------------------------
    function automatic bit [4:0] choose_reg(
      input reg_class_e cls
    );
      if (cls == REG_ZERO)
        return 5'd0;

      return $urandom_range(31, 1);
    endfunction

    // ------------------------------------------------------------
    // Controlled initial operand values
    // ------------------------------------------------------------
    function automatic bit [31:0] choose_value(
      input value_class_e cls
    );
      case (cls)
        VAL_ZERO:
          return 32'h00000000;

        VAL_POS:
          return $urandom_range(32'h0000007f, 32'h00000001);

        VAL_NEG:
          return $urandom_range(32'hffffffff, 32'hffffff80);

        VAL_MAX:
          return 32'h7fffffff;

        VAL_MIN:
          return 32'h80000000;

        default:
          return $urandom;
      endcase
    endfunction

    // ------------------------------------------------------------
    // Controlled operation selection
    // ------------------------------------------------------------
    function automatic random_op_e choose_operation();
      return random_op_e'($urandom_range(OP_SLT, OP_ADD));
    endfunction

    // ------------------------------------------------------------
    // Encode selected operation
    // ------------------------------------------------------------
    function automatic bit [31:0] encode_operation(
      input random_op_e op,
      input bit [4:0] rd,
      input bit [4:0] rs1,
      input bit [4:0] rs2
    );
      case (op)
        OP_ADD: return encode_add(rd, rs1, rs2);
        OP_SUB: return encode_sub(rd, rs1, rs2);
        OP_AND: return encode_and(rd, rs1, rs2);
        OP_OR : return encode_or (rd, rs1, rs2);
        OP_XOR: return encode_xor(rd, rs1, rs2);
        OP_SLL: return encode_sll(rd, rs1, rs2);
        OP_SRA: return encode_sra(rd, rs1, rs2);
        OP_SLT: return encode_slt(rd, rs1, rs2);
        default:
          return 32'h00000013; // ADDI x0,x0,0 (NOP)
      endcase
    endfunction

    // ------------------------------------------------------------
    // Main sequence
    // ------------------------------------------------------------
    virtual task body();

      cpu_transaction tr;
      random_op_e op;
      reg_class_e rs1_class;
      reg_class_e rs2_class;
      reg_class_e rd_class;
      value_class_e value_class;
      bit [4:0] rd;
      bit [4:0] rs1;
      bit [4:0] rs2;

      if (!$value$plusargs("RAND_SEED=%d", seed))
        seed = $urandom;

      `uvm_info(
        get_type_name(),
        $sformatf("Starting controlled-random CPU sequence, seed=%0d",
                  seed),
        UVM_MEDIUM
      )

      void'($urandom(seed));

      tr = cpu_transaction::type_id::create("random_cpu_transaction");

      // Controlled register initialization.
      // Keep x0 fixed at zero and initialize only the registers
      // that the generated program may use.
      for (int i = 0; i < 32; i++) begin
        tr.init_int_regs[i] = 32'h00000000;
      end

      tr.init_int_regs[0] = 32'h00000000;

      for (int i = 1; i < 32; i++) begin
        value_class = value_class_e'($urandom_range(VAL_OTHER, VAL_ZERO));
        tr.init_int_regs[i] = choose_value(value_class);

      end

      // Fixed program length for the first version.
      for (int i = 0; i < PROGRAM_LEN; i++) begin

        op = choose_operation();

        rs1_class = reg_class_e'($urandom_range(REG_NONZERO, REG_ZERO));
        rs2_class = reg_class_e'($urandom_range(REG_NONZERO, REG_ZERO));
        rd_class  = reg_class_e'($urandom_range(REG_NONZERO, REG_ZERO));

        rs1 = choose_reg(rs1_class);
        rs2 = choose_reg(rs2_class);
        rd  = choose_reg(rd_class);

        tr.set_instr(
          i,
          encode_operation(op, rd, rs1, rs2)
        );

        `uvm_info(
          get_type_name(),
          $sformatf(
            "RANDOM[%0d] op=%0d rd=x%0d rs1=x%0d rs2=x%0d instr=0x%08h",
            i,
            op,
            rd,
            rs1,
            rs2,
            tr.instr_mem[i]
          ),
          UVM_HIGH
        )
      end

      `uvm_info(
        get_type_name(),
        $sformatf("Generated %0d legal RV32I R-type instructions",
                  PROGRAM_LEN),
        UVM_MEDIUM
      )

      start_item(tr);
      finish_item(tr);

    endtask

  endclass

endpackage
