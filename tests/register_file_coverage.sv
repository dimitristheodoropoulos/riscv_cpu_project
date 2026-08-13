// ============================================================
// Register File Functional Coverage Model
// ============================================================
//
// Manual functional coverage.
//
// No covergroup / coverpoint constructs are used.
//
// Coverage categories:
//   - Integer register accesses
//   - Floating-point register accesses
//   - Read operations
//   - Write operations
//   - x0 read
//   - x0 write attempt
//   - Representative register address bins
// ============================================================

module register_file_coverage;

    // --------------------------------------------------------
    // Transaction counters
    // --------------------------------------------------------
    integer read_transactions;
    integer write_transactions;

    integer integer_transactions;
    integer fp_transactions;

    // --------------------------------------------------------
    // Operation bins
    // --------------------------------------------------------
    integer read_bin;
    integer write_bin;

    // --------------------------------------------------------
    // x0 behavior bins
    // --------------------------------------------------------
    integer x0_read_bin;
    integer x0_write_bin;

    // --------------------------------------------------------
    // Representative register address bins
    // --------------------------------------------------------
    integer reg_0_bin;
    integer reg_1_bin;
    integer reg_15_bin;
    integer reg_16_bin;
    integer reg_31_bin;

    // --------------------------------------------------------
    // Initialization
    // --------------------------------------------------------
    initial begin

        read_transactions  = 0;
        write_transactions = 0;

        integer_transactions = 0;
        fp_transactions      = 0;

        read_bin  = 0;
        write_bin = 0;

        x0_read_bin  = 0;
        x0_write_bin = 0;

        reg_0_bin  = 0;
        reg_1_bin  = 0;
        reg_15_bin = 0;
        reg_16_bin = 0;
        reg_31_bin = 0;

    end

    // --------------------------------------------------------
    // Sample register address
    // --------------------------------------------------------
    task sample_register_address;
        input [4:0] addr;

        begin

            case (addr)

                5'd0:
                    reg_0_bin = 1;

                5'd1:
                    reg_1_bin = 1;

                5'd15:
                    reg_15_bin = 1;

                5'd16:
                    reg_16_bin = 1;

                5'd31:
                    reg_31_bin = 1;

                default:
                    begin
                    end

            endcase

        end

    endtask

    // --------------------------------------------------------
    // Sample READ transaction
    // --------------------------------------------------------
    task sample_read;
        input [4:0] addr1;
        input [4:0] addr2;
        input       fp;

        begin

            read_transactions = read_transactions + 1;
            read_bin = 1;

            if (fp)
                fp_transactions = fp_transactions + 1;
            else
                integer_transactions = integer_transactions + 1;

            if (!fp) begin

                if ((addr1 == 5'd0) || (addr2 == 5'd0))
                    x0_read_bin = 1;

            end

            sample_register_address(addr1);
            sample_register_address(addr2);

        end

    endtask

    // --------------------------------------------------------
    // Sample WRITE transaction
    // --------------------------------------------------------
    task sample_write;
        input [4:0] addr;
        input       fp;

        begin

            write_transactions = write_transactions + 1;
            write_bin = 1;

            if (fp)
                fp_transactions = fp_transactions + 1;
            else
                integer_transactions = integer_transactions + 1;

            if (!fp && (addr == 5'd0))
                x0_write_bin = 1;

            sample_register_address(addr);

        end

    endtask

    // --------------------------------------------------------
    // Coverage report
    // --------------------------------------------------------
    task report;

        integer operation_bins_hit;
        integer register_type_bins_hit;
        integer x0_bins_hit;
        integer address_bins_hit;

        integer coverage_bins_hit;
        integer total_coverage_bins;

        begin

            operation_bins_hit = 0;

            if (read_bin)
                operation_bins_hit = operation_bins_hit + 1;

            if (write_bin)
                operation_bins_hit = operation_bins_hit + 1;


            register_type_bins_hit = 0;

            if (integer_transactions > 0)
                register_type_bins_hit =
                    register_type_bins_hit + 1;

            if (fp_transactions > 0)
                register_type_bins_hit =
                    register_type_bins_hit + 1;


            x0_bins_hit = 0;

            if (x0_read_bin)
                x0_bins_hit = x0_bins_hit + 1;

            if (x0_write_bin)
                x0_bins_hit = x0_bins_hit + 1;


            address_bins_hit =
                    reg_0_bin +
                    reg_1_bin +
                    reg_15_bin +
                    reg_16_bin +
                    reg_31_bin;


            // 2 operation bins
            // 2 register-type bins
            // 2 x0 behavior bins
            // 5 address bins
            total_coverage_bins = 11;

            coverage_bins_hit =
                    operation_bins_hit +
                    register_type_bins_hit +
                    x0_bins_hit +
                    address_bins_hit;


            $display("");
            $display("========================================");
            $display("REGISTER FILE FUNCTIONAL COVERAGE");
            $display("========================================");

            $display("Read transactions    : %0d",
                     read_transactions);

            $display("Write transactions   : %0d",
                     write_transactions);

            $display("");
            $display("Operation coverage   : %0d / 2",
                     operation_bins_hit);

            $display("  READ               : %s",
                     read_bin ? "HIT" : "MISS");

            $display("  WRITE              : %s",
                     write_bin ? "HIT" : "MISS");

            $display("");
            $display("Register type        : %0d / 2",
                     register_type_bins_hit);

            $display("  INTEGER            : %s",
                     (integer_transactions > 0)
                     ? "HIT" : "MISS");

            $display("  FLOATING-POINT     : %s",
                     (fp_transactions > 0)
                     ? "HIT" : "MISS");

            $display("");
            $display("x0 behavior coverage : %0d / 2",
                     x0_bins_hit);

            $display("  x0 READ            : %s",
                     x0_read_bin ? "HIT" : "MISS");

            $display("  x0 WRITE           : %s",
                     x0_write_bin ? "HIT" : "MISS");

            $display("");
            $display("Address coverage     : %0d / 5",
                     address_bins_hit);

            $display("  Register 0         : %s",
                     reg_0_bin ? "HIT" : "MISS");

            $display("  Register 1         : %s",
                     reg_1_bin ? "HIT" : "MISS");

            $display("  Register 15        : %s",
                     reg_15_bin ? "HIT" : "MISS");

            $display("  Register 16        : %s",
                     reg_16_bin ? "HIT" : "MISS");

            $display("  Register 31        : %s",
                     reg_31_bin ? "HIT" : "MISS");

            $display("");
            $display("Coverage bins hit    : %0d / %0d",
                     coverage_bins_hit,
                     total_coverage_bins);

            if (coverage_bins_hit == total_coverage_bins)
                $display("Functional coverage  : 100%%");
            else
                $display("Functional coverage  : INCOMPLETE");

            $display("========================================");

        end

    endtask

endmodule
