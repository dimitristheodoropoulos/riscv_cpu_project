`include "uvm_macros.svh"

package fpu_pkg;

import uvm_pkg::*;


// ============================================================
// Transaction
// ============================================================
class fpu_transaction extends uvm_sequence_item;

    rand bit [31:0] a;
    rand bit [31:0] b;
    rand bit [2:0]  op;

    bit [31:0] result;
    bit        ready;

    `uvm_object_utils(fpu_transaction)

    function new(string name = "fpu_transaction");
        super.new(name);
    endfunction

    function void randomize_manual();
        a  = $urandom();
        b  = $urandom();
        op = $urandom_range(0, 3);
    endfunction

endclass


// ============================================================
// Constrained-random sequence
// ============================================================
class fpu_constrained_sequence extends uvm_sequence #(fpu_transaction);

    `uvm_object_utils(fpu_constrained_sequence)

    int num_transactions = 1000;

    typedef enum {
        CAT_ZERO,
        CAT_SUBNORMAL,
        CAT_NORMAL,
        CAT_INFINITY,
        CAT_NAN
    } operand_category_t;


    function new(string name = "fpu_constrained_sequence");
        super.new(name);
    endfunction


    function bit [31:0] generate_operand(
        operand_category_t category
    );

        bit        sign;
        bit [7:0]  exp;
        bit [22:0] frac;

        sign = $urandom_range(0, 1);

        case (category)

            CAT_ZERO: begin
                exp  = 8'd0;
                frac = 23'd0;
            end

            CAT_SUBNORMAL: begin
                exp  = 8'd0;
                frac = $urandom_range(1, 23'h7FFFFF);
            end

            CAT_NORMAL: begin
                exp = $urandom_range(1, 254);

                if ($urandom_range(0, 9) == 0)
                    frac = 23'd0;
                else if ($urandom_range(0, 9) == 0)
                    frac = 23'h7FFFFF;
                else
                    frac = $urandom();
            end

            CAT_INFINITY: begin
                exp  = 8'hFF;
                frac = 23'd0;
            end

            CAT_NAN: begin
                exp  = 8'hFF;
                frac = $urandom_range(1, 23'h7FFFFF);
            end

            default: begin
                exp  = 8'd0;
                frac = 23'd0;
            end

        endcase

        return {sign, exp, frac};

    endfunction


    function bit [2:0] random_op();
        return $urandom_range(0, 3);
    endfunction


    virtual task body();

        fpu_transaction tx;

        int i;
        int rand_val;

        operand_category_t cat_a;
        operand_category_t cat_b;

        // --------------------------------------------------------
        // 16 targeted architectural / IEEE-754 pairs
        // --------------------------------------------------------
        bit [31:0] targeted_pairs[0:15][0:2] = '{

            '{32'h7F7FFFFF, 32'h00800000, 0},
            '{32'h00800000, 32'h7F7FFFFF, 1},
            '{32'h00800000, 32'h00800000, 2},
            '{32'h7F7FFFFF, 32'h00800000, 3},

            '{32'h3F800000, 32'h3EAAAAAB, 3},
            '{32'h3EAAAAAB, 32'h3F800000, 3},

            '{32'h00000001, 32'h00000001, 0},
            '{32'h00000001, 32'h00000001, 2},

            '{32'h00800000, 32'h00000001, 0},
            '{32'h00800000, 32'h00000001, 3},

            '{32'h3F800000, 32'h00000000, 3},
            '{32'h00000000, 32'h3F800000, 3},

            '{32'h7F800000, 32'h3F800000, 0},
            '{32'h7F800000, 32'h3F800000, 2},

            '{32'h7F800000, 32'h7F800000, 0},
            '{32'h7FC00000, 32'h3F800000, 0}
        };


        foreach (targeted_pairs[i]) begin

            tx = fpu_transaction::type_id::create("tx");

            tx.a  = targeted_pairs[i][0];
            tx.b  = targeted_pairs[i][1];
            tx.op = targeted_pairs[i][2];

            start_item(tx);
            finish_item(tx);

        end


        // --------------------------------------------------------
        // Constrained-random transactions
        // --------------------------------------------------------
        repeat (num_transactions) begin

            tx = fpu_transaction::type_id::create("tx");

            rand_val = $urandom_range(0, 99);

            if (rand_val < 40) begin

                cat_a = CAT_NORMAL;
                cat_b = CAT_NORMAL;

            end
            else if (rand_val < 55) begin

                cat_a = CAT_NORMAL;
                cat_b = CAT_SUBNORMAL;

            end
            else if (rand_val < 65) begin

                cat_a = CAT_SUBNORMAL;
                cat_b = CAT_NORMAL;

            end
            else if (rand_val < 70) begin

                cat_a = CAT_ZERO;
                cat_b = CAT_NORMAL;

            end
            else if (rand_val < 75) begin

                cat_a = CAT_NORMAL;
                cat_b = CAT_ZERO;

            end
            else if (rand_val < 80) begin

                cat_a = CAT_INFINITY;
                cat_b = CAT_NORMAL;

            end
            else if (rand_val < 85) begin

                cat_a = CAT_NORMAL;
                cat_b = CAT_INFINITY;

            end
            else if (rand_val < 90) begin

                cat_a = CAT_NAN;
                cat_b = CAT_NORMAL;

            end
            else if (rand_val < 95) begin

                cat_a = CAT_NORMAL;
                cat_b = CAT_NAN;

            end
            else begin

                cat_a = CAT_SUBNORMAL;
                cat_b = CAT_SUBNORMAL;

            end


            tx.a  = generate_operand(cat_a);
            tx.b  = generate_operand(cat_b);
            tx.op = random_op();

            start_item(tx);
            finish_item(tx);

        end

    endtask

endclass


// ============================================================
// Directed IEEE-754 corner-case sequence
// ============================================================
class fpu_corner_case_sequence extends uvm_sequence #(fpu_transaction);

    `uvm_object_utils(fpu_corner_case_sequence)

    function new(string name = "fpu_corner_case_sequence");
        super.new(name);
    endfunction


    virtual task body();

        fpu_transaction tx;


        // --------------------------------------------------------
        // +0, -0
        // --------------------------------------------------------

        tx = fpu_transaction::type_id::create("tx");
        tx.a  = 32'h00000000;
        tx.b  = 32'h3F800000;
        tx.op = 0;
        start_item(tx);
        finish_item(tx);


        tx = fpu_transaction::type_id::create("tx");
        tx.a  = 32'h80000000;
        tx.b  = 32'h3F800000;
        tx.op = 0;
        start_item(tx);
        finish_item(tx);


        // --------------------------------------------------------
        // Smallest subnormal / normal
        // --------------------------------------------------------

        tx = fpu_transaction::type_id::create("tx");
        tx.a  = 32'h00000001;
        tx.b  = 32'h00800000;
        tx.op = 2;
        start_item(tx);
        finish_item(tx);


        // --------------------------------------------------------
        // Largest subnormal / normal
        // --------------------------------------------------------

        tx = fpu_transaction::type_id::create("tx");
        tx.a  = 32'h007FFFFF;
        tx.b  = 32'h00800000;
        tx.op = 2;
        start_item(tx);
        finish_item(tx);


        // --------------------------------------------------------
        // Smallest normal / normal
        // --------------------------------------------------------

        tx = fpu_transaction::type_id::create("tx");
        tx.a  = 32'h00800000;
        tx.b  = 32'h40800000;
        tx.op = 3;
        start_item(tx);
        finish_item(tx);


        // --------------------------------------------------------
        // Largest normal / normal
        // --------------------------------------------------------

        tx = fpu_transaction::type_id::create("tx");
        tx.a  = 32'h7F7FFFFF;
        tx.b  = 32'h3F800000;
        tx.op = 3;
        start_item(tx);
        finish_item(tx);


        // --------------------------------------------------------
        // Max finite + max finite -> overflow
        // --------------------------------------------------------

        tx = fpu_transaction::type_id::create("tx");
        tx.a  = 32'h7F7FFFFF;
        tx.b  = 32'h7F7FFFFF;
        tx.op = 0;
        start_item(tx);
        finish_item(tx);


        // --------------------------------------------------------
        // Max finite * 2.0 -> overflow
        // --------------------------------------------------------

        tx = fpu_transaction::type_id::create("tx");
        tx.a  = 32'h7F7FFFFF;
        tx.b  = 32'h40000000;
        tx.op = 2;
        start_item(tx);
        finish_item(tx);


        // --------------------------------------------------------
        // 1.0 / 3.0
        // --------------------------------------------------------

        tx = fpu_transaction::type_id::create("tx");
        tx.a  = 32'h3F800000;
        tx.b  = 32'h40400000;
        tx.op = 3;
        start_item(tx);
        finish_item(tx);


        // --------------------------------------------------------
        // 1.0 / 10.0
        // --------------------------------------------------------

        tx = fpu_transaction::type_id::create("tx");
        tx.a  = 32'h3F800000;
        tx.b  = 32'h41200000;
        tx.op = 3;
        start_item(tx);
        finish_item(tx);


        // --------------------------------------------------------
        // RNE tie case
        // --------------------------------------------------------

        tx = fpu_transaction::type_id::create("tx");
        tx.a  = 32'h3F800000;
        tx.b  = 32'h34000000;
        tx.op = 0;
        start_item(tx);
        finish_item(tx);


        // --------------------------------------------------------
        // Subnormal rounding to normal boundary
        // --------------------------------------------------------

        tx = fpu_transaction::type_id::create("tx");
        tx.a  = 32'h007FFFFF;
        tx.b  = 32'h00000001;
        tx.op = 0;
        start_item(tx);
        finish_item(tx);

    endtask

endclass


// ============================================================
// Original sequence
// ============================================================
class fpu_sequence extends uvm_sequence #(fpu_transaction);

    `uvm_object_utils(fpu_sequence)

    int num_transactions = 1000;

    function new(string name = "fpu_sequence");
        super.new(name);
    endfunction


    virtual task body();

        fpu_transaction tx;

        repeat (num_transactions) begin

            tx = fpu_transaction::type_id::create("tx");

            start_item(tx);

            tx.randomize_manual();

            finish_item(tx);

        end

    endtask

endclass


// ============================================================
// Driver
// ============================================================
class fpu_driver extends uvm_driver #(fpu_transaction);

    `uvm_component_utils(fpu_driver)

    virtual fpu_if vif;


    function new(
        string name = "fpu_driver",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db #(virtual fpu_if)::get(
                this,
                "",
                "vif",
                vif
        )) begin

            `uvm_fatal(
                "NOVIF",
                "fpu_driver: virtual interface not set"
            )

        end

    endfunction


    virtual task run_phase(uvm_phase phase);

        fpu_transaction tx;

        forever begin

            seq_item_port.get_next_item(tx);

            vif.a  <= tx.a;
            vif.b  <= tx.b;
            vif.op <= tx.op;

            @(posedge vif.clk);

            seq_item_port.item_done();

        end

    endtask

endclass


// ============================================================
// Monitor
//
// Registered DUT, 1-cycle latency.
// ============================================================
class fpu_monitor extends uvm_monitor;

    `uvm_component_utils(fpu_monitor)

    virtual fpu_if vif;

    uvm_analysis_port #(fpu_transaction) ap;


    function new(
        string name = "fpu_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

        ap = new("ap", this);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db #(virtual fpu_if)::get(
                this,
                "",
                "vif",
                vif
        )) begin

            `uvm_fatal(
                "NOVIF",
                "fpu_monitor: virtual interface not set"
            )

        end

    endfunction


    virtual task run_phase(uvm_phase phase);

        fpu_transaction tx;

        bit [31:0] prev_a;
        bit [31:0] prev_b;
        bit [2:0]  prev_op;

        bit have_prev = 0;


        forever begin

            @(posedge vif.clk);

            if (vif.rst) begin

                have_prev = 0;

            end
            else begin

                #1;

                if (have_prev) begin

                    tx = fpu_transaction::type_id::create("tx");

                    tx.a      = prev_a;
                    tx.b      = prev_b;
                    tx.op     = prev_op;
                    tx.result = vif.result;
                    tx.ready  = vif.ready;


                    if (!tx.ready) begin

                        `uvm_error(
                            "MON",
                            "Expected ready=1"
                        )

                    end


                    ap.write(tx);

                end


                prev_a    = vif.a;
                prev_b    = vif.b;
                prev_op   = vif.op;
                have_prev = 1'b1;

            end

        end

    endtask

endclass


// ============================================================
// Agent
// ============================================================
class fpu_agent extends uvm_agent;

    `uvm_component_utils(fpu_agent)

    fpu_driver driver;
    fpu_monitor monitor;

    uvm_sequencer #(fpu_transaction) sequencer;


    function new(
        string name = "fpu_agent",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        driver = fpu_driver::type_id::create(
            "driver",
            this
        );

        monitor = fpu_monitor::type_id::create(
            "monitor",
            this
        );

        sequencer =
            uvm_sequencer #(fpu_transaction)::type_id::create(
                "sequencer",
                this
            );

    endfunction


    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        driver.seq_item_port.connect(
            sequencer.seq_item_export
        );

    endfunction

endclass


// ============================================================
// Scoreboard
//
// Deterministic, objection-controlled.
// ============================================================
class fpu_scoreboard extends uvm_component;

    `uvm_component_utils(fpu_scoreboard)

    uvm_tlm_analysis_fifo #(fpu_transaction) mon_fifo;

    fpu_transaction tx_queue[$];

    int num_expected = 100;

    string input_file  = "scoreboard_in.txt";
    string output_file = "scoreboard_out.txt";

    string script_path =
        "../reference/scoreboard_bridge.py";


    function new(
        string name = "fpu_scoreboard",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        mon_fifo = new(
            "mon_fifo",
            this
        );

    endfunction


    virtual task run_phase(uvm_phase phase);

        fpu_transaction tx;

        int received = 0;


        phase.raise_objection(this);

        #25;


        while (received < num_expected) begin

            mon_fifo.get(tx);

            tx_queue.push_back(tx);

            received++;

        end


        compare_all();


        phase.drop_objection(this);

    endtask


    virtual task compare_all();

        int fd_in;
        int fd_res;
        int ret;

        string cmd;
        string line_expected;

        int mismatches = 0;
        int unsupported = 0;

        int total = tx_queue.size();

        bit [31:0] expected_val;


        if (total == 0)
            return;


        fd_in = $fopen(
            input_file,
            "w"
        );


        if (!fd_in) begin

            `uvm_error(
                "SCRD",
                "Cannot open input file"
            )

            return;

        end


        foreach (tx_queue[i]) begin

            $fwrite(
                fd_in,
                "%h %h %h\n",
                tx_queue[i].a,
                tx_queue[i].b,
                tx_queue[i].op
            );

        end


        $fclose(fd_in);


        cmd = $sformatf(
            "python3 %s %s %s",
            script_path,
            input_file,
            output_file
        );


        `uvm_info(
            "SCRD",
            $sformatf(
                "Running: %s",
                cmd
            ),
            UVM_MEDIUM
        )


        ret = $system(cmd);


        if (ret != 0) begin

            `uvm_error(
                "SCRD",
                "Python bridge returned non-zero status"
            );

            return;

        end


        fd_res = $fopen(
            output_file,
            "r"
        );


        if (!fd_res) begin

            `uvm_error(
                "SCRD",
                "Cannot open output file"
            );

            return;

        end


        foreach (tx_queue[i]) begin

            ret = $fgets(
                line_expected,
                fd_res
            );


            if (ret == 0) begin

                `uvm_error(
                    "SCRD",
                    "Missing expected result"
                );

                break;

            end


            while (
                line_expected.len() > 0 &&
                (
                    line_expected[
                        line_expected.len()-1
                    ] == "\n" ||

                    line_expected[
                        line_expected.len()-1
                    ] == "\r"
                )
            ) begin

                line_expected =
                    line_expected.substr(
                        0,
                        line_expected.len()-2
                    );

            end


            if (line_expected == "UNSUPPORTED") begin

                unsupported++;

                continue;

            end


            if (
                $sscanf(
                    line_expected,
                    "%h",
                    expected_val
                ) != 1
            ) begin

                `uvm_error(
                    "SCRD",
                    $sformatf(
                        "Bad expected line: %s",
                        line_expected
                    )
                );

                continue;

            end


            if (
                tx_queue[i].result !== expected_val
            ) begin

                `uvm_error(
                    "SCRD",
                    $sformatf(
                        "Mismatch: a=%h b=%h op=%h DUT=%h expected=%h",
                        tx_queue[i].a,
                        tx_queue[i].b,
                        tx_queue[i].op,
                        tx_queue[i].result,
                        expected_val
                    )
                );

                mismatches++;

            end

        end


        $fclose(fd_res);


        `uvm_info(
            "SCRD",
            $sformatf(
                "Scoreboard: total %0d, compared %0d, unsupported %0d, mismatches %0d",
                total,
                total - unsupported,
                unsupported,
                mismatches
            ),
            UVM_LOW
        )

    endtask

endclass


// ============================================================
// Functional Coverage Component
//
// Manual coverage because Questa Starter does not provide the
// required covergroup functionality for this project.
// ============================================================
class fpu_coverage extends uvm_component;

    `uvm_component_utils(fpu_coverage)

    uvm_tlm_analysis_fifo #(fpu_transaction) cov_fifo;


    int op_hit[bit [2:0]];

    // --------------------------------------------------------
    // Invalid opcode coverage.
    //
    // Legal FPU operations are 0..3.
    // Opcodes 4..7 reach the top-level default case.
    // --------------------------------------------------------
    int invalid_op_hit;


    int a_category_hit[string];
    int b_category_hit[string];
    int result_category_hit[string];

    int sign_a_hit[bit];
    int sign_b_hit[bit];

    int exp_a_region_hit[string];
    int exp_b_region_hit[string];


    function new(
        string name = "fpu_coverage",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        cov_fifo = new(
            "cov_fifo",
            this
        );


        // --------------------------------------------------------
        // Operation bins
        // --------------------------------------------------------

        op_hit[0] = 0;
        op_hit[1] = 0;
        op_hit[2] = 0;
        op_hit[3] = 0;

        invalid_op_hit = 0;


        // --------------------------------------------------------
        // Sign bins
        // --------------------------------------------------------

        sign_a_hit[0] = 0;
        sign_a_hit[1] = 0;

        sign_b_hit[0] = 0;
        sign_b_hit[1] = 0;


        // --------------------------------------------------------
        // Operand A categories
        // --------------------------------------------------------

        a_category_hit["ZERO"]      = 0;
        a_category_hit["SUBNORMAL"] = 0;
        a_category_hit["NORMAL"]    = 0;
        a_category_hit["INFINITY"]  = 0;
        a_category_hit["NAN"]       = 0;


        // --------------------------------------------------------
        // Operand B categories
        // --------------------------------------------------------

        b_category_hit["ZERO"]      = 0;
        b_category_hit["SUBNORMAL"] = 0;
        b_category_hit["NORMAL"]    = 0;
        b_category_hit["INFINITY"]  = 0;
        b_category_hit["NAN"]       = 0;


        // --------------------------------------------------------
        // Result categories
        // --------------------------------------------------------

        result_category_hit["ZERO"]      = 0;
        result_category_hit["SUBNORMAL"] = 0;
        result_category_hit["NORMAL"]    = 0;
        result_category_hit["INFINITY"]  = 0;
        result_category_hit["NAN"]       = 0;


        // --------------------------------------------------------
        // Exponent regions A
        // --------------------------------------------------------

        exp_a_region_hit["ZERO/SUB"]   = 0;
        exp_a_region_hit["MIN_NORMAL"] = 0;
        exp_a_region_hit["MAX_NORMAL"] = 0;
        exp_a_region_hit["INF/NAN"]    = 0;
        exp_a_region_hit["LOW"]        = 0;
        exp_a_region_hit["MID"]        = 0;
        exp_a_region_hit["HIGH"]       = 0;


        // --------------------------------------------------------
        // Exponent regions B
        // --------------------------------------------------------

        exp_b_region_hit["ZERO/SUB"]   = 0;
        exp_b_region_hit["MIN_NORMAL"] = 0;
        exp_b_region_hit["MAX_NORMAL"] = 0;
        exp_b_region_hit["INF/NAN"]    = 0;
        exp_b_region_hit["LOW"]        = 0;
        exp_b_region_hit["MID"]        = 0;
        exp_b_region_hit["HIGH"]       = 0;

    endfunction


    virtual task run_phase(uvm_phase phase);

        fpu_transaction tx;

        forever begin

            cov_fifo.get(tx);

            sample_transaction(tx);

        end

    endtask


    function string classify_operand(
        bit [31:0] val
    );

        bit [7:0]  exp  = val[30:23];
        bit [22:0] frac = val[22:0];


        if (exp == 0 && frac == 0)
            return "ZERO";


        if (exp == 0 && frac != 0)
            return "SUBNORMAL";


        if (exp == 8'hFF && frac == 0)
            return "INFINITY";


        if (exp == 8'hFF && frac != 0)
            return "NAN";


        return "NORMAL";

    endfunction


    function string classify_exponent_region(
        bit [7:0] exp
    );

        if (exp == 0)
            return "ZERO/SUB";


        if (exp == 1)
            return "MIN_NORMAL";


        if (exp == 254)
            return "MAX_NORMAL";


        if (exp == 255)
            return "INF/NAN";


        if (exp <= 64)
            return "LOW";


        if (exp <= 192)
            return "MID";


        return "HIGH";

    endfunction


    function void sample_transaction(
        fpu_transaction tx
    );

        string cat_a;
        string cat_b;
        string cat_res;

        string region_a;
        string region_b;


        // --------------------------------------------------------
        // IMPORTANT:
        //
        // Legal opcodes are only 0..3.
        // The closure test intentionally sends op=7 to reach
        // the default case in fpu.sv.
        //
        // Do NOT access op_hit[4..7], because those entries do
        // not exist in the associative array.
        // --------------------------------------------------------

        if (tx.op <= 3) begin

            op_hit[tx.op]++;

        end
        else begin

            invalid_op_hit++;

        end


        cat_a   = classify_operand(tx.a);
        cat_b   = classify_operand(tx.b);
        cat_res = classify_operand(tx.result);


        a_category_hit[cat_a]++;
        b_category_hit[cat_b]++;
        result_category_hit[cat_res]++;


        sign_a_hit[tx.a[31]]++;
        sign_b_hit[tx.b[31]]++;


        region_a =
            classify_exponent_region(
                tx.a[30:23]
            );

        region_b =
            classify_exponent_region(
                tx.b[30:23]
            );


        exp_a_region_hit[region_a]++;
        exp_b_region_hit[region_b]++;

    endfunction


    virtual function void report_phase(
        uvm_phase phase
    );

        string op_names[0:3] =
            '{"ADD", "SUB", "MUL", "DIV"};


        `uvm_info(
            "COVERAGE",
            "===== FPU FUNCTIONAL COVERAGE REPORT =====",
            UVM_LOW
        )


        `uvm_info(
            "COVERAGE",
            "Operations:",
            UVM_LOW
        )


        foreach (op_names[i])

            `uvm_info(
                "COVERAGE",
                $sformatf(
                    "  %4s : %0d",
                    op_names[i],
                    op_hit[i]
                ),
                UVM_LOW
            )


        `uvm_info(
            "COVERAGE",
            $sformatf(
                "  INVALID : %0d",
                invalid_op_hit
            ),
            UVM_LOW
        )


        `uvm_info(
            "COVERAGE",
            "Operand A categories:",
            UVM_LOW
        )


        foreach (a_category_hit[cat])

            `uvm_info(
                "COVERAGE",
                $sformatf(
                    "  %10s : %0d",
                    cat,
                    a_category_hit[cat]
                ),
                UVM_LOW
            )


        `uvm_info(
            "COVERAGE",
            "Operand B categories:",
            UVM_LOW
        )


        foreach (b_category_hit[cat])

            `uvm_info(
                "COVERAGE",
                $sformatf(
                    "  %10s : %0d",
                    cat,
                    b_category_hit[cat]
                ),
                UVM_LOW
            )


        `uvm_info(
            "COVERAGE",
            "Result categories:",
            UVM_LOW
        )


        foreach (result_category_hit[cat])

            `uvm_info(
                "COVERAGE",
                $sformatf(
                    "  %10s : %0d",
                    cat,
                    result_category_hit[cat]
                ),
                UVM_LOW
            )


        `uvm_info(
            "COVERAGE",
            $sformatf(
                "Sign A: pos=%0d neg=%0d",
                sign_a_hit[0],
                sign_a_hit[1]
            ),
            UVM_LOW
        )


        `uvm_info(
            "COVERAGE",
            $sformatf(
                "Sign B: pos=%0d neg=%0d",
                sign_b_hit[0],
                sign_b_hit[1]
            ),
            UVM_LOW
        )


        `uvm_info(
            "COVERAGE",
            "Exponent regions for A:",
            UVM_LOW
        )


        foreach (exp_a_region_hit[region])

            `uvm_info(
                "COVERAGE",
                $sformatf(
                    "  %10s : %0d",
                    region,
                    exp_a_region_hit[region]
                ),
                UVM_LOW
            )


        `uvm_info(
            "COVERAGE",
            "Exponent regions for B:",
            UVM_LOW
        )


        foreach (exp_b_region_hit[region])

            `uvm_info(
                "COVERAGE",
                $sformatf(
                    "  %10s : %0d",
                    region,
                    exp_b_region_hit[region]
                ),
                UVM_LOW
            )


        `uvm_info(
            "COVERAGE",
            "=============================================",
            UVM_LOW
        )

    endfunction

endclass


// ============================================================
// Regression Test
//
// 16 targeted + 1000 random = 1016 vectors.
// ============================================================
class fpu_regression_test extends uvm_test;

    `uvm_component_utils(fpu_regression_test)

    fpu_agent      agent;
    fpu_scoreboard scoreboard;
    fpu_coverage   coverage;


    function new(
        string name = "fpu_regression_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);

        agent =
            fpu_agent::type_id::create(
                "agent",
                this
            );

        scoreboard =
            fpu_scoreboard::type_id::create(
                "scoreboard",
                this
            );

        coverage =
            fpu_coverage::type_id::create(
                "coverage",
                this
            );


        scoreboard.num_expected = 1016;

    endfunction


    virtual function void connect_phase(
        uvm_phase phase
    );

        super.connect_phase(phase);

        agent.monitor.ap.connect(
            scoreboard.mon_fifo.analysis_export
        );

        agent.monitor.ap.connect(
            coverage.cov_fifo.analysis_export
        );

    endfunction


    virtual task run_phase(
        uvm_phase phase
    );

        fpu_constrained_sequence seq;


        phase.raise_objection(this);

        #25;


        seq =
            fpu_constrained_sequence::type_id::create(
                "seq"
            );

        seq.num_transactions = 1000;

        seq.start(
            agent.sequencer
        );


        phase.drop_objection(this);

    endtask

endclass


// ============================================================
// Corner-Case Test
//
// Exactly 12 vectors.
// ============================================================
class fpu_corner_case_test extends uvm_test;

    `uvm_component_utils(fpu_corner_case_test)

    fpu_agent      agent;
    fpu_scoreboard scoreboard;
    fpu_coverage   coverage;


    function new(
        string name = "fpu_corner_case_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);


        agent =
            fpu_agent::type_id::create(
                "agent",
                this
            );

        scoreboard =
            fpu_scoreboard::type_id::create(
                "scoreboard",
                this
            );

        coverage =
            fpu_coverage::type_id::create(
                "coverage",
                this
            );


        scoreboard.num_expected = 12;

    endfunction


    virtual function void connect_phase(
        uvm_phase phase
    );

        super.connect_phase(phase);


        agent.monitor.ap.connect(
            scoreboard.mon_fifo.analysis_export
        );

        agent.monitor.ap.connect(
            coverage.cov_fifo.analysis_export
        );

    endfunction


    virtual task run_phase(
        uvm_phase phase
    );

        fpu_corner_case_sequence seq;


        phase.raise_objection(this);

        #25;


        seq =
            fpu_corner_case_sequence::type_id::create(
                "seq"
            );


        seq.start(
            agent.sequencer
        );


        phase.drop_objection(this);

    endtask

endclass


// ============================================================
// Long Regression Test
//
// 16 targeted + 10,000 random = 10,016 vectors.
// ============================================================
class fpu_long_regression_test extends uvm_test;

    `uvm_component_utils(fpu_long_regression_test)

    fpu_agent      agent;
    fpu_scoreboard scoreboard;
    fpu_coverage   coverage;


    function new(
        string name = "fpu_long_regression_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);


        agent =
            fpu_agent::type_id::create(
                "agent",
                this
            );

        scoreboard =
            fpu_scoreboard::type_id::create(
                "scoreboard",
                this
            );

        coverage =
            fpu_coverage::type_id::create(
                "coverage",
                this
            );


        scoreboard.num_expected = 10016;

    endfunction


    virtual function void connect_phase(
        uvm_phase phase
    );

        super.connect_phase(phase);


        agent.monitor.ap.connect(
            scoreboard.mon_fifo.analysis_export
        );

        agent.monitor.ap.connect(
            coverage.cov_fifo.analysis_export
        );

    endfunction


    virtual task run_phase(
        uvm_phase phase
    );

        fpu_constrained_sequence seq;


        phase.raise_objection(this);

        #25;


        seq =
            fpu_constrained_sequence::type_id::create(
                "seq"
            );


        seq.num_transactions = 10000;


        seq.start(
            agent.sequencer
        );


        phase.drop_objection(this);

    endtask

endclass


// ============================================================
// Coverage Closure Sequence
//
// Total = 31 vectors:
//
//   1-3   : original MUL/DIV closure
//   4-24  : ADD closure
//   25    : top-level SUB closure
//   26    : top-level invalid opcode closure
//   27    : MUL branch closure
//   28    : DIV exponent overflow closure
//   29    : DIV subnormal shift saturation closure
//   30    : MUL reverse Inf * 0 closure
//   31    : DIV subnormal -> smallest normal after rounding
// ============================================================
class fpu_closure_sequence extends uvm_sequence #(fpu_transaction);

    `uvm_object_utils(fpu_closure_sequence)


    function new(
        string name = "fpu_closure_sequence"
    );

        super.new(name);

    endfunction


    virtual task body();

        fpu_transaction tx;


        // ========================================================
        // 1) MUL rounding overflow
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3F7FFFFE;
        tx.b  = 32'h3F800001;
        tx.op = 2;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 2) MUL subnormal shift
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h00000002;
        tx.b  = 32'h00000003;
        tx.op = 2;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 3) DIV subnormal sticky accumulation
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h00000001;
        tx.b  = 32'h7F7FFFFF;
        tx.op = 3;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 4) DIV subnormal result / shift_cnt = 11
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h00800000;
        tx.b  = 32'h40800000;
        tx.op = 3;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 5) NaN in A
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h7FC00000;
        tx.b  = 32'h3F800000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 6) NaN in B
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3F800000;
        tx.b  = 32'h7FC00000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 7) +Inf + -Inf = NaN
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h7F800000;
        tx.b  = 32'hFF800000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 8) +Inf + +Inf = +Inf
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h7F800000;
        tx.b  = 32'h7F800000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 9) A = Inf
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h7F800000;
        tx.b  = 32'h3F800000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 10) B = Inf
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3F800000;
        tx.b  = 32'h7F800000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 11) +0 + +0
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h00000000;
        tx.b  = 32'h00000000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 12) 0 + finite
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h00000000;
        tx.b  = 32'h3F800000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 13) finite + 0
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3F800000;
        tx.b  = 32'h00000000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 14) A has larger exponent
        //     2.0 + 1.0
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h40000000;
        tx.b  = 32'h3F800000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 15) B has larger exponent
        //     1.0 + 2.0
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3F800000;
        tx.b  = 32'h40000000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 16) Same exponent, A mantissa >= B mantissa
        //     1.5 + 1.0
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3FC00000;
        tx.b  = 32'h3F800000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 17) Same exponent, A mantissa < B mantissa
        //     1.0 + 1.5
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3F800000;
        tx.b  = 32'h3FC00000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 18) Addition without significand carry
        //     1.0 + 0.5 = 1.5
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3F800000;
        tx.b  = 32'h3F000000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 19) Addition with significand carry
        //     1.0 + 1.0 = 2.0
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3F800000;
        tx.b  = 32'h3F800000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 20) Exact cancellation
        //     1.0 + (-1.0) = +0
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3F800000;
        tx.b  = 32'hBF800000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 21) Non-zero subtraction / normalization
        //     1.5 + (-1.0) = 0.5
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3FC00000;
        tx.b  = 32'hBF800000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 22) Rounding carry into exponent
        //
        //     A = 0x3FFFFFFF
        //       = 2.0 - 2^-24
        //
        //     B = 0x33800000
        //       = 2^-24
        //
        //     Result = 2.0
        //
        //     Target:
        //
        //       if (mant_rounded_ext[24])
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3FFFFFFF;
        tx.b  = 32'h33800000;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 23) Addition carry + discarded-bit sticky path
        //
        //     A = 0x3FFFFFFF
        //     B = 0x3F800001
        //
        //     Exact result = 3.0
        //
        //     Expected = 0x40400000
        //
        //     Targets:
        //
        //       if (mant_sum_ext[27])
        //       if (mant_sum_ext[0])
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3FFFFFFF;
        tx.b  = 32'h3F800001;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 24) Alignment with discarded 1-bit sticky
        //
        //     A = 0x3FFFFFFF
        //     B = 0x3D800001
        //
        //     Exponent difference = 4.
        //
        //     Targets shift_right_sticky():
        //
        //       if (value[i])
        //       if (sticky)
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3FFFFFFF;
        tx.b  = 32'h3D800001;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 25) ADD exponent overflow
        //
        //     MAX_FINITE + MAX_FINITE
        //
        //     Expected:
        //
        //       +Inf = 0x7F800000
        //
        //     Target:
        //
        //       if (exp_result >= 8'hFF)
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h7F7FFFFF;
        tx.b  = 32'h7F7FFFFF;
        tx.op = 0;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 26) Top-level SUB closure
        //
        //     4.0 - 2.0 = 2.0
        //
        //     Target:
        //       fpu.sv top-level CASE -> op = 3'b001
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h40800000;
        tx.b  = 32'h40000000;
        tx.op = 1;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 27) Top-level invalid opcode closure
        //
        //     Target:
        //       fpu.sv top-level CASE -> default
        //
        //     Expected result = 0
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h3F800000;
        tx.b  = 32'h40000000;
        tx.op = 7;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 28) MUL branch closure
        //
        //     Infinity * Zero -> NaN
        //
        //     A = +Inf
        //     B = +0
        //
        //     Expected:
        //
        //       NaN = 0x7FC00000
        //
        //     Target:
        //
        //       (a_is_inf && b_is_zero) ||
        //       (b_is_inf && a_is_zero)
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h7F800000;
        tx.b  = 32'h00000000;
        tx.op = 2;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 29) DIV exponent overflow
        //
        //     MAX_FINITE / MIN_NORMAL
        //
        //     A = 0x7F7FFFFF
        //     B = 0x00800000
        //
        //     Expected:
        //
        //       +Inf = 0x7F800000
        //
        //     Target:
        //
        //       if (exp_unbiased > 14'sd127)
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h7F7FFFFF;
        tx.b  = 32'h00800000;
        tx.op = 3;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 30) DIV subnormal shift saturation
        //
        //     MIN_NORMAL / MAX_FINITE
        //
        //     A = 0x00800000
        //     B = 0x7F7FFFFF
        //
        //     Expected:
        //
        //       +0 = 0x00000000
        //
        //     Target:
        //
        //       if (shift_cnt >= QWIDTH)
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h00800000;
        tx.b  = 32'h7F7FFFFF;
        tx.op = 3;

        start_item(tx);
        finish_item(tx);


        // ========================================================
        // 31) DIV subnormal -> smallest normal after rounding
        //
        //     Largest subnormal / 2.0
        //
        //     A = 0x00FFFFFF
        //     B = 0x40000000
        //
        //     Expected:
        //
        //       smallest normal = 0x00800000
        //
        //     Target:
        //
        //       if (sig_rounded[23])
        //
        //     This is the reachable boundary case where a
        //     rounded subnormal result becomes the smallest
        //     normal binary32 value.
        // ========================================================

        tx =
            fpu_transaction::type_id::create("tx");

        tx.a  = 32'h00FFFFFF;
        tx.b  = 32'h40000000;
        tx.op = 3;

        start_item(tx);
        finish_item(tx);

    endtask

endclass


// ============================================================
// Coverage Closure Test
//
// Exactly 31 vectors.
// ============================================================
class fpu_closure_test extends uvm_test;

    `uvm_component_utils(fpu_closure_test)

    fpu_agent      agent;
    fpu_scoreboard scoreboard;
    fpu_coverage   coverage;


    function new(
        string name = "fpu_closure_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    virtual function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);


        agent =
            fpu_agent::type_id::create(
                "agent",
                this
            );


        scoreboard =
            fpu_scoreboard::type_id::create(
                "scoreboard",
                this
            );


        coverage =
            fpu_coverage::type_id::create(
                "coverage",
                this
            );


        // --------------------------------------------------------
        // Closure sequence contains exactly 31 vectors.
        // --------------------------------------------------------

        scoreboard.num_expected = 31;

    endfunction


    virtual function void connect_phase(
        uvm_phase phase
    );

        super.connect_phase(phase);


        agent.monitor.ap.connect(
            scoreboard.mon_fifo.analysis_export
        );


        agent.monitor.ap.connect(
            coverage.cov_fifo.analysis_export
        );

    endfunction


    virtual task run_phase(
        uvm_phase phase
    );

        fpu_closure_sequence seq;


        phase.raise_objection(this);

        #25;


        seq =
            fpu_closure_sequence::type_id::create(
                "seq"
            );


        seq.start(
            agent.sequencer
        );


        phase.drop_objection(this);

    endtask

endclass


endpackage