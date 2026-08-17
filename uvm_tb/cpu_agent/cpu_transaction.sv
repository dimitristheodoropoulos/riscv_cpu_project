`ifndef CPU_TRANSACTION_SV
`define CPU_TRANSACTION_SV

`include "uvm_macros.svh"

package cpu_pkg;

    import uvm_pkg::*;

    // ------------------------------------------------------------
    // CPU transaction
    //
    // Contains:
    //
    //   Input / stimulus:
    //     - instruction memory image
    //     - initial integer register state
    //     - initial floating-point register state
    //     - instruction count
    //
    //   Expected architectural state:
    //     - expected PC
    //     - expected integer registers
    //     - expected data memory
    //
    //   Observed architectural state:
    //     - observed PC
    //     - observed result
    //     - observed integer registers
    //     - observed data memory
    //
    // The monitor fills ONLY the observed fields.
    // The scoreboard/reference model owns the expected fields.
    // ------------------------------------------------------------

    class cpu_transaction extends uvm_sequence_item;

        // --------------------------------------------------------
        // Program image
        // --------------------------------------------------------

        bit [31:0] instr_mem [0:63];

        // Explicit number of valid instructions.
        int unsigned instr_count;

        // --------------------------------------------------------
        // Initial architectural state
        // --------------------------------------------------------

        bit [31:0] init_int_regs [0:31];
        bit [31:0] init_fp_regs  [0:31];

        // --------------------------------------------------------
        // Expected architectural state
        // --------------------------------------------------------

        bit [31:0] exp_int_regs [0:31];
        bit [31:0] exp_mem      [0:255];

        bit [31:0] expected_pc;

        // --------------------------------------------------------
        // Observed architectural state
        // --------------------------------------------------------

        bit [31:0] observed_pc;
        bit [31:0] observed_result;

        bit [31:0] observed_int_regs [0:31];
        bit [31:0] observed_mem      [0:255];

        `uvm_object_utils(cpu_transaction)

        // --------------------------------------------------------
        // Constructor
        // --------------------------------------------------------

        function new(string name = "cpu_transaction");

            super.new(name);

            reset_transaction();

        endfunction

        // --------------------------------------------------------
        // Reset / initialize transaction contents
        // --------------------------------------------------------

        function void reset_transaction();

            // Program image
            foreach (instr_mem[i])
                instr_mem[i] = 32'h00000000;

            instr_count = 0;

            // Initial registers
            foreach (init_int_regs[i])
                init_int_regs[i] = 32'h00000000;

            foreach (init_fp_regs[i])
                init_fp_regs[i] = 32'h00000000;

            // Expected state
            foreach (exp_int_regs[i])
                exp_int_regs[i] = 32'h00000000;

            foreach (exp_mem[i])
                exp_mem[i] = 32'h00000000;

            expected_pc = 32'h00000000;

            // Observed state
            observed_pc     = 32'h00000000;
            observed_result = 32'h00000000;

            foreach (observed_int_regs[i])
                observed_int_regs[i] = 32'h00000000;

            foreach (observed_mem[i])
                observed_mem[i] = 32'h00000000;

        endfunction

        // --------------------------------------------------------
        // Instruction helpers
        // --------------------------------------------------------

        function void set_instr(
            int idx,
            bit [31:0] instr
        );

            if ((idx >= 0) && (idx < 64)) begin

                instr_mem[idx] = instr;

                if (idx + 1 > instr_count)
                    instr_count = idx + 1;

                // The architectural PC after sequential execution
                // of the valid instruction image is 4 bytes per
                // instruction.
                expected_pc = instr_count * 4;

            end
            else begin

                `uvm_error(
                    "CPU_TR_IDX",
                    $sformatf(
                        "Instruction index %0d out of range",
                        idx
                    )
                )

            end

        endfunction

        // --------------------------------------------------------
        // Initial register helper
        // --------------------------------------------------------

        function void set_init_reg(
            int idx,
            bit [31:0] val
        );

            if ((idx >= 0) && (idx < 32)) begin

                init_int_regs[idx] = val;

            end
            else begin

                `uvm_error(
                    "CPU_TR_REG_IDX",
                    $sformatf(
                        "Initial register index %0d out of range",
                        idx
                    )
                )

            end

        endfunction

        // --------------------------------------------------------
        // Expected register helper
        // --------------------------------------------------------

        function void set_expected_reg(
            int idx,
            bit [31:0] val
        );

            if ((idx >= 0) && (idx < 32)) begin

                exp_int_regs[idx] = val;

            end
            else begin

                `uvm_error(
                    "CPU_TR_EXP_REG_IDX",
                    $sformatf(
                        "Expected register index %0d out of range",
                        idx
                    )
                )

            end

        endfunction

        // --------------------------------------------------------
        // Expected memory helper
        // --------------------------------------------------------

        function void set_expected_mem(
            int idx,
            bit [31:0] val
        );

            if ((idx >= 0) && (idx < 256)) begin

                exp_mem[idx] = val;

            end
            else begin

                `uvm_error(
                    "CPU_TR_EXP_MEM_IDX",
                    $sformatf(
                        "Expected memory index %0d out of range",
                        idx
                    )
                )

            end

        endfunction

        // --------------------------------------------------------
        // Expected PC helper
        // --------------------------------------------------------

        function void set_expected_pc(
            bit [31:0] pc
        );

            expected_pc = pc;

        endfunction

        // --------------------------------------------------------
        // UVM copy
        //
        // Explicitly copy all unpacked arrays and scalar fields.
        // This is important because the transaction contains
        // unpacked arrays which are not handled by field automation.
        // --------------------------------------------------------

        function void do_copy(
            uvm_object rhs
        );

            cpu_transaction rhs_tr;

            super.do_copy(rhs);

            if (!$cast(rhs_tr, rhs)) begin

                `uvm_fatal(
                    "CPU_TR_COPY",
                    "Failed to cast rhs to cpu_transaction"
                )

            end

            // Program image
            foreach (instr_mem[i])
                instr_mem[i] = rhs_tr.instr_mem[i];

            instr_count = rhs_tr.instr_count;

            // Initial registers
            foreach (init_int_regs[i])
                init_int_regs[i] = rhs_tr.init_int_regs[i];

            foreach (init_fp_regs[i])
                init_fp_regs[i] = rhs_tr.init_fp_regs[i];

            // Expected state
            foreach (exp_int_regs[i])
                exp_int_regs[i] = rhs_tr.exp_int_regs[i];

            foreach (exp_mem[i])
                exp_mem[i] = rhs_tr.exp_mem[i];

            expected_pc = rhs_tr.expected_pc;

            // Observed state
            observed_pc     = rhs_tr.observed_pc;
            observed_result = rhs_tr.observed_result;

            foreach (observed_int_regs[i])
                observed_int_regs[i] = rhs_tr.observed_int_regs[i];

            foreach (observed_mem[i])
                observed_mem[i] = rhs_tr.observed_mem[i];

        endfunction

        // --------------------------------------------------------
        // UVM compare
        //
        // Explicit comparison of all transaction state.
        // Useful for transaction-level debugging.
        // --------------------------------------------------------

        function bit do_compare(
            uvm_object rhs,
            uvm_comparer comparer
        );

            cpu_transaction rhs_tr;

            if (!$cast(rhs_tr, rhs))
                return 0;

            if (!super.do_compare(rhs, comparer))
                return 0;

            if (instr_count != rhs_tr.instr_count)
                return 0;

            if (expected_pc != rhs_tr.expected_pc)
                return 0;

            if (observed_pc != rhs_tr.observed_pc)
                return 0;

            if (observed_result != rhs_tr.observed_result)
                return 0;

            foreach (instr_mem[i]) begin
                if (instr_mem[i] != rhs_tr.instr_mem[i])
                    return 0;
            end

            foreach (init_int_regs[i]) begin
                if (init_int_regs[i] != rhs_tr.init_int_regs[i])
                    return 0;
            end

            foreach (init_fp_regs[i]) begin
                if (init_fp_regs[i] != rhs_tr.init_fp_regs[i])
                    return 0;
            end

            foreach (exp_int_regs[i]) begin
                if (exp_int_regs[i] != rhs_tr.exp_int_regs[i])
                    return 0;
            end

            foreach (exp_mem[i]) begin
                if (exp_mem[i] != rhs_tr.exp_mem[i])
                    return 0;
            end

            foreach (observed_int_regs[i]) begin
                if (observed_int_regs[i] != rhs_tr.observed_int_regs[i])
                    return 0;
            end

            foreach (observed_mem[i]) begin
                if (observed_mem[i] != rhs_tr.observed_mem[i])
                    return 0;
            end

            return 1;

        endfunction

    endclass

endpackage

`endif