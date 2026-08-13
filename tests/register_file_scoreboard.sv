// ========================================================
// REGISTER FILE SCOREBOARD
//
// Compares DUT outputs against an independent reference
// model.
//
// Icarus-compatible:
//   - module based
//   - no SystemVerilog classes
//   - independent reference model
//   - explicit PASS/FAIL accounting
//
// ========================================================

module register_file_scoreboard;

    // ----------------------------------------------------
    // Independent reference model
    // ----------------------------------------------------

    register_file_reference_model model();

    // ----------------------------------------------------
    // Statistics
    // ----------------------------------------------------

    integer checks;
    integer passed;
    integer failed;

    reg last_check_pass;

    // ----------------------------------------------------
    // Initialization
    // ----------------------------------------------------

    initial begin
        checks = 0;
        passed = 0;
        failed = 0;
        last_check_pass = 1'b0;
    end

    // ----------------------------------------------------
    // Reset reference model
    // ----------------------------------------------------

    task reset;
        begin
            model.reset();
        end
    endtask

    // ----------------------------------------------------
    // Observe write transaction
    // ----------------------------------------------------

    task observe_write;

        input [4:0]  addr;
        input [31:0] data;
        input        fp;
        input        enable;

        begin

            model.write(
                addr,
                data,
                fp,
                enable
            );

        end

    endtask

    // ----------------------------------------------------
    // Check DUT read outputs
    // ----------------------------------------------------

    task check_read;

        input [4:0]    addr1;
        input [4:0]    addr2;
        input          fp;

        input [31:0]   actual1;
        input [31:0]   actual2;

        input [1023:0] test_name;

        reg [31:0] expected1;
        reg [31:0] expected2;

        begin

            checks = checks + 1;

            // ------------------------------------------------
            // Obtain expected values from independent model.
            // ------------------------------------------------

            expected1 = model.predict_read1(
                addr1,
                fp
            );

            expected2 = model.predict_read2(
                addr2,
                fp
            );

            // ------------------------------------------------
            // Compare DUT against reference model.
            // ------------------------------------------------

            if ((actual1 === expected1) &&
                (actual2 === expected2)) begin

                passed = passed + 1;
                last_check_pass = 1'b1;

                $display(
                    "PASS: %0s | r1=%0d expected=%0d got=%0d | r2=%0d expected=%0d got=%0d",
                    test_name,
                    addr1,
                    expected1,
                    actual1,
                    addr2,
                    expected2,
                    actual2
                );

            end
            else begin

                failed = failed + 1;
                last_check_pass = 1'b0;

                $display(
                    "FAIL: %0s | r1=%0d expected=%0d got=%0d | r2=%0d expected=%0d got=%0d",
                    test_name,
                    addr1,
                    expected1,
                    actual1,
                    addr2,
                    expected2,
                    actual2
                );

            end

        end

    endtask

    // ----------------------------------------------------
    // Report
    // ----------------------------------------------------

    task report;

        begin

            $display("");
            $display("========================================");
            $display("REGISTER FILE SCOREBOARD SUMMARY");
            $display("========================================");

            $display(
                "Checks : %0d",
                checks
            );

            $display(
                "Passed : %0d",
                passed
            );

            $display(
                "Failed : %0d",
                failed
            );

            if (failed == 0)
                $display("Scoreboard: PASSED");
            else
                $display("Scoreboard: FAILED");

            $display("========================================");

        end

    endtask

endmodule