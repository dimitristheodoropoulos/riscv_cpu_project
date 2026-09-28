`ifndef RISCV_RAL_SEMANTIC_TEST_SV
`define RISCV_RAL_SEMANTIC_TEST_SV

`include "uvm_macros.svh"

package riscv_ral_semantic_test_pkg;

    import uvm_pkg::*;

    `include "riscv_reg.sv"
    `include "riscv_reg_block.sv"

    class riscv_ral_semantic_test extends uvm_test;

        `uvm_component_utils(riscv_ral_semantic_test)

        riscv_reg_block ral;

        function new(
            string name = "riscv_ral_semantic_test",
            uvm_component parent = null
        );
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);

            super.build_phase(phase);

            ral = riscv_reg_block::type_id::create("ral");
            ral.build();

        endfunction

        virtual task run_phase(uvm_phase phase);

            phase.raise_objection(this);

            check_integer_registers();
            check_fp_registers();
            check_boundary_registers();
            check_map_reverse_lookup();

            `uvm_info(
                "RAL_M4",
                "M4 RAL semantic verification completed",
                UVM_LOW
            )

            phase.drop_objection(this);

        endtask

        virtual task check_integer_registers();

            for (int i = 0; i < 32; i++) begin

                string expected_access;
                uvm_reg_addr_t expected_address;

                expected_access =
                    (i == 0) ? "RO" : "RW";

                expected_address = i * 4;

                if (ral.x[i].get_rights(ral.default_map)
                    != expected_access) begin

                    `uvm_error(
                        "RAL_M4",
                        $sformatf(
                            "x%0d access mismatch: expected=%s actual=%s",
                            i,
                            expected_access,
                            ral.x[i].get_rights(ral.default_map)
                        )
                    )
                end

                if (ral.x[i].get_address(ral.default_map)
                    != expected_address) begin

                    `uvm_error(
                        "RAL_M4",
                        $sformatf(
                            "x%0d address mismatch: expected=0x%0h actual=0x%0h",
                            i,
                            expected_address,
                            ral.x[i].get_address(ral.default_map)
                        )
                    )
                end

                check_register_common(
                    ral.x[i],
                    $sformatf("x%0d", i)
                );

            end

        endtask

        virtual task check_fp_registers();

            for (int i = 0; i < 32; i++) begin

                uvm_reg_addr_t expected_address;

                expected_address =
                    32'h80 + (i * 4);

                if (ral.f[i].get_rights(ral.default_map)
                    != "RW") begin

                    `uvm_error(
                        "RAL_M4",
                        $sformatf(
                            "f%0d access mismatch: expected=RW actual=%s",
                            i,
                            ral.f[i].get_rights(ral.default_map)
                        )
                    )
                end

                if (ral.f[i].get_address(ral.default_map)
                    != expected_address) begin

                    `uvm_error(
                        "RAL_M4",
                        $sformatf(
                            "f%0d address mismatch: expected=0x%0h actual=0x%0h",
                            i,
                            expected_address,
                            ral.f[i].get_address(ral.default_map)
                        )
                    )
                end

                check_register_common(
                    ral.f[i],
                    $sformatf("f%0d", i)
                );

            end

        endtask

        virtual task check_register_common(
            riscv_reg rg,
            string name
        );

            if (rg.get_n_bits() != 32) begin

                `uvm_error(
                    "RAL_M4",
                    $sformatf(
                        "%s width mismatch: expected=32 actual=%0d",
                        name,
                        rg.get_n_bits()
                    )
                )

            end

            if (rg.get_reset() != 32'h00000000) begin

                `uvm_error(
                    "RAL_M4",
                    $sformatf(
                        "%s reset mismatch: expected=0x00000000 actual=0x%08h",
                        name,
                        rg.get_reset()
                    )
                )

            end

            if (rg.data.get_access(ral.default_map)
                != rg.get_rights(ral.default_map)) begin

                `uvm_error(
                    "RAL_M4",
                    $sformatf(
                        "%s field/register access mismatch: register=%s field=%s",
                        name,
                        rg.get_rights(ral.default_map),
                        rg.data.get_access(ral.default_map)
                    )
                )

            end

            if (rg.data.get_n_bits() != 32) begin

                `uvm_error(
                    "RAL_M4",
                    $sformatf(
                        "%s field width mismatch: expected=32 actual=%0d",
                        name,
                        rg.data.get_n_bits()
                    )
                )

            end

            if (rg.data.get_lsb_pos() != 0) begin

                `uvm_error(
                    "RAL_M4",
                    $sformatf(
                        "%s field LSB mismatch: expected=0 actual=%0d",
                        name,
                        rg.data.get_lsb_pos()
                    )
                )

            end

            if (rg.data.get_reset() != 32'h00000000) begin

                `uvm_error(
                    "RAL_M4",
                    $sformatf(
                        "%s field reset mismatch: expected=0x00000000 actual=0x%08h",
                        name,
                        rg.data.get_reset()
                    )
                )

            end

        endtask

        virtual task check_boundary_registers();

            check_address(
                ral.x[0],
                32'h000,
                "x0"
            );

            check_address(
                ral.x[31],
                32'h07C,
                "x31"
            );

            check_address(
                ral.f[0],
                32'h080,
                "f0"
            );

            check_address(
                ral.f[31],
                32'h0FC,
                "f31"
            );

        endtask

        virtual task check_address(
            riscv_reg rg,
            uvm_reg_addr_t expected_address,
            string name
        );

            if (rg.get_offset(ral.default_map)
                != expected_address) begin

                `uvm_error(
                    "RAL_M4",
                    $sformatf(
                        "%s offset mismatch: expected=0x%0h actual=0x%0h",
                        name,
                        expected_address,
                        rg.get_offset(ral.default_map)
                    )
                )

            end

        endtask

        virtual task check_map_reverse_lookup();

            for (int i = 0; i < 32; i++) begin

                uvm_reg found_x;
                uvm_reg found_f;

                found_x =
                    ral.default_map.get_reg_by_offset(
                        i * 4
                    );

                found_f =
                    ral.default_map.get_reg_by_offset(
                        32'h80 + (i * 4)
                    );

                if (found_x != ral.x[i]) begin

                    `uvm_error(
                        "RAL_M4",
                        $sformatf(
                            "Reverse map lookup mismatch for x%0d",
                            i
                        )
                    )

                end

                if (found_f != ral.f[i]) begin

                    `uvm_error(
                        "RAL_M4",
                        $sformatf(
                            "Reverse map lookup mismatch for f%0d",
                            i
                        )
                    )

                end

            end

        endtask

    endclass

endpackage

`endif
