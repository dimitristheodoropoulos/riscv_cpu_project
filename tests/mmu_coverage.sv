// ============================================================
// MMU Functional Coverage Model
// ============================================================
//
// Free-tool compatible manual functional coverage.
//
// No covergroup / coverpoint constructs are used.
//
// Covered:
//   - READ transactions
//   - WRITE transactions
//   - Address categories
//
// Address bins:
//   - 0
//   - 10
//   - 20
//   - 255
//   - >= 256
//
// ============================================================

module mmu_coverage;

    // --------------------------------------------------------
    // Transaction counters
    // --------------------------------------------------------

    integer read_transactions;
    integer write_transactions;

    // --------------------------------------------------------
    // Address coverage bins
    // --------------------------------------------------------

    integer address_0;
    integer address_10;
    integer address_20;
    integer address_255;
    integer address_256_plus;

    // --------------------------------------------------------
    // Initialization
    // --------------------------------------------------------

    initial begin
        read_transactions  = 0;
        write_transactions = 0;

        address_0        = 0;
        address_10       = 0;
        address_20       = 0;
        address_255      = 0;
        address_256_plus = 0;
    end

    // --------------------------------------------------------
    // Address sampling
    // --------------------------------------------------------

    task sample_address;
        input [31:0] addr;

        begin
            case (addr)

                32'd0:
                    address_0 = 1;

                32'd10:
                    address_10 = 1;

                32'd20:
                    address_20 = 1;

                32'd255:
                    address_255 = 1;

                default:
                    begin
                        if (addr >= 32'd256)
                            address_256_plus = 1;
                    end

            endcase
        end
    endtask

    // --------------------------------------------------------
    // READ transaction sampling
    // --------------------------------------------------------

    task sample_read;
        input [31:0] addr;

        begin
            read_transactions = read_transactions + 1;
            sample_address(addr);
        end
    endtask

    // --------------------------------------------------------
    // WRITE transaction sampling
    // --------------------------------------------------------

    task sample_write;
        input [31:0] addr;

        begin
            write_transactions = write_transactions + 1;
            sample_address(addr);
        end
    endtask

    // --------------------------------------------------------
    // Coverage report
    // --------------------------------------------------------

    task report;

        integer address_bins_hit;
        integer operation_bins_hit;
        integer total_bins;
        integer bins_hit;

        begin

            // Address bins
            address_bins_hit =
                    address_0 +
                    address_10 +
                    address_20 +
                    address_255 +
                    address_256_plus;

            // READ / WRITE bins
            operation_bins_hit = 0;

            if (read_transactions > 0)
                operation_bins_hit = operation_bins_hit + 1;

            if (write_transactions > 0)
                operation_bins_hit = operation_bins_hit + 1;

            // 5 address bins + 2 operation bins
            total_bins = 7;

            bins_hit =
                    address_bins_hit +
                    operation_bins_hit;

            $display("");
            $display("========================================");
            $display("MMU FUNCTIONAL COVERAGE");
            $display("========================================");

            $display("Read transactions   : %0d",
                     read_transactions);

            $display("Write transactions  : %0d",
                     write_transactions);

            $display("");
            $display("Operation coverage  : %0d / 2",
                     operation_bins_hit);

            $display("  READ              : %s",
                     (read_transactions > 0) ? "HIT" : "MISS");

            $display("  WRITE             : %s",
                     (write_transactions > 0) ? "HIT" : "MISS");

            $display("");
            $display("Address coverage    : %0d / 5",
                     address_bins_hit);

            $display("  Address 0         : %s",
                     address_0 ? "HIT" : "MISS");

            $display("  Address 10        : %s",
                     address_10 ? "HIT" : "MISS");

            $display("  Address 20        : %s",
                     address_20 ? "HIT" : "MISS");

            $display("  Address 255       : %s",
                     address_255 ? "HIT" : "MISS");

            $display("  Address >= 256    : %s",
                     address_256_plus ? "HIT" : "MISS");

            $display("");
            $display("Coverage bins hit   : %0d / %0d",
                     bins_hit,
                     total_bins);

            if (bins_hit == total_bins)
                $display("Functional coverage : 100%%");
            else
                $display("Functional coverage : INCOMPLETE");

            $display("========================================");

        end

    endtask

endmodule
