`ifndef RISCV_REG_SV
`define RISCV_REG_SV

class riscv_reg extends uvm_reg;

    `uvm_object_utils(riscv_reg)

    uvm_reg_field data;

    function new(string name = "riscv_reg");
        super.new(
            name,
            32,
            UVM_NO_COVERAGE
        );
    endfunction

    virtual function void build(
        string access = "RW",
        uvm_reg_data_t reset_value = 32'h00000000
    );

        data = uvm_reg_field::type_id::create("data");

        data.configure(
            this,
            32,
            0,
            access,
            1'b0,
            reset_value,
            1'b1,
            1'b1,
            1'b1
        );

    endfunction

endclass

`endif
