`ifndef RISCV_REG_BLOCK_SV
`define RISCV_REG_BLOCK_SV

class riscv_reg_block extends uvm_reg_block;

    `uvm_object_utils(riscv_reg_block)

    riscv_reg x[32];
    riscv_reg f[32];

    uvm_reg_map default_map;

    function new(string name = "riscv_reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();

        default_map = create_map(
            "default_map",
            0,
            4,
            UVM_LITTLE_ENDIAN,
            1
        );

        for (int i = 0; i < 32; i++) begin

            x[i] = riscv_reg::type_id::create(
                $sformatf("x%0d", i)
            );

            x[i].configure(this);

            if (i == 0)
                x[i].build("RO");
            else
                x[i].build("RW");

            default_map.add_reg(
                x[i],
                i * 4,
                (i == 0) ? "RO" : "RW"
            );
        end

        for (int i = 0; i < 32; i++) begin

            f[i] = riscv_reg::type_id::create(
                $sformatf("f%0d", i)
            );

            f[i].configure(this);
            f[i].build("RW");

            default_map.add_reg(
                f[i],
                32'h80 + (i * 4),
                "RW"
            );
        end

        lock_model();

    endfunction

endclass

`endif
