#!/bin/bash

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="$PROJECT_ROOT/sim"
OUTPUT_DIR="$SIM_DIR/output"

TARGET="${1:-all}"
NUM_SEEDS="${2:-10}"

mkdir -p "$OUTPUT_DIR"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

run_iverilog_target() {
    local target="$1"
    local top="$2"
    shift 2

    local report_file="$OUTPUT_DIR/${target}_regression_report.txt"
    local log_file="$OUTPUT_DIR/${target}_regression.log"
    local vvp_file="/tmp/${target}_tb.vvp"

    local -a source_files
    source_files=("$@")

    echo ""
    echo "========================================"
    echo "Target: $target"
    echo "========================================"

    {
        echo "Regression: target=$target"
        echo "Date: $(timestamp)"
        echo "----------------------------------------"
    } > "$report_file"

    if ! iverilog -g2012 -Wall \
        -I "$PROJECT_ROOT/tests" \
        -s "$top" \
        -o "$vvp_file" \
        "${source_files[@]}" > "$log_file" 2>&1
    then
        echo "Target $target: COMPILE FAIL"
        echo "COMPILE FAIL" >> "$report_file"
        cat "$log_file"
        return 1
    fi

    if ! vvp "$vvp_file" >> "$log_file" 2>&1; then
        echo "Target $target: SIMULATION FAIL"
        echo "SIMULATION FAIL" >> "$report_file"
        echo "Simulation exited with non-zero status." >> "$report_file"
        cat "$log_file"
        return 1
    fi

    if grep -q "VERIFICATION PASSED" "$log_file"; then
        echo "Target $target: PASS"
        echo "PASS" >> "$report_file"
        return 0
    fi

    echo "Target $target: FAIL"
    echo "FAIL" >> "$report_file"
    echo "Verification completion marker not found." >> "$report_file"
    cat "$log_file"
    return 1
}

run_alu() {
    local report_file="$OUTPUT_DIR/alu_regression_report.txt"

    echo ""
    echo "========================================"
    echo "Target: ALU"
    echo "Seeds: $NUM_SEEDS"
    echo "========================================"

    {
        echo "Regression: target=alu, seeds=$NUM_SEEDS"
        echo "Date: $(timestamp)"
        echo "----------------------------------------"
    } > "$report_file"

    local pass_count=0
    local fail_count=0

    for i in $(seq 1 "$NUM_SEEDS"); do
        local seed=$((RANDOM * RANDOM))
        local log="$OUTPUT_DIR/alu_seed${seed}.log"

        rm -rf "$SIM_DIR/work"

        if ! cd "$SIM_DIR"; then
            echo "Seed $seed: ENVIRONMENT FAIL" | tee -a "$report_file"
            fail_count=$((fail_count + 1))
            continue
        fi

        if ! vlib work > /dev/null 2>&1; then
            echo "Seed $seed: COMPILE FAIL" | tee -a "$report_file"
            fail_count=$((fail_count + 1))
            continue
        fi

        if ! vmap work work > /dev/null 2>&1; then
            echo "Seed $seed: COMPILE FAIL" | tee -a "$report_file"
            fail_count=$((fail_count + 1))
            continue
        fi

        if ! vlog -sv \
            +incdir+"$PROJECT_ROOT/uvm_tb/alu_agent" \
            +incdir+"$PROJECT_ROOT/uvm_tb/env" \
            +incdir+"$PROJECT_ROOT/uvm_tb/sequences" \
            +incdir+"$PROJECT_ROOT/uvm_tb/tests" \
            "$PROJECT_ROOT/rtl/alu.sv" \
            "$PROJECT_ROOT/uvm_tb/alu_agent/alu_if.sv" \
            "$PROJECT_ROOT/uvm_tb/tb_top.sv" \
            > "$log" 2>&1
        then
            echo "Seed $seed: COMPILE FAIL" | tee -a "$report_file"
            fail_count=$((fail_count + 1))
            continue
        fi

        if vsim -c work.tb_top \
            -sv_seed "$seed" \
            -do "run -all; quit -f" \
            +UVM_TESTNAME=alu_test \
            >> "$log" 2>&1
        then
            if grep -q "UVM_ERROR :    0" "$log"; then
                echo "Seed $seed: PASS" | tee -a "$report_file"
                pass_count=$((pass_count + 1))
            else
                echo "Seed $seed: FAIL (see $log)" | tee -a "$report_file"
                fail_count=$((fail_count + 1))
            fi
        else
            echo "Seed $seed: FAIL (see $log)" | tee -a "$report_file"
            fail_count=$((fail_count + 1))
        fi
    done

    cd "$PROJECT_ROOT" || return 1

    echo "----------------------------------------" >> "$report_file"
    echo "Summary: $pass_count PASS / $fail_count FAIL from $NUM_SEEDS seeds" \
        | tee -a "$report_file"

    if [ "$fail_count" -gt 0 ]; then
        return 1
    fi

    return 0
}

run_cu() {
    local report_file="$OUTPUT_DIR/cu_regression_report.txt"

    echo ""
    echo "========================================"
    echo "Target: CU"
    echo "Seeds: $NUM_SEEDS"
    echo "========================================"

    {
        echo "Regression: target=cu, seeds=$NUM_SEEDS"
        echo "Date: $(timestamp)"
        echo "----------------------------------------"
    } > "$report_file"

    local pass_count=0
    local fail_count=0

    for i in $(seq 1 "$NUM_SEEDS"); do
        local seed=$((RANDOM * RANDOM))
        local log="$OUTPUT_DIR/cu_seed${seed}.log"

        rm -rf "$SIM_DIR/work"

        if ! cd "$SIM_DIR"; then
            echo "Seed $seed: ENVIRONMENT FAIL" | tee -a "$report_file"
            fail_count=$((fail_count + 1))
            continue
        fi

        if ! vlib work > /dev/null 2>&1; then
            echo "Seed $seed: COMPILE FAIL" | tee -a "$report_file"
            fail_count=$((fail_count + 1))
            continue
        fi

        if ! vmap work work > /dev/null 2>&1; then
            echo "Seed $seed: COMPILE FAIL" | tee -a "$report_file"
            fail_count=$((fail_count + 1))
            continue
        fi

        if ! vlog -sv \
            +incdir+"$PROJECT_ROOT/uvm_tb/cu_agent" \
            +incdir+"$PROJECT_ROOT/uvm_tb/env" \
            +incdir+"$PROJECT_ROOT/uvm_tb/sequences" \
            +incdir+"$PROJECT_ROOT/uvm_tb/tests" \
            "$PROJECT_ROOT/rtl/cu.sv" \
            "$PROJECT_ROOT/uvm_tb/cu_agent/cu_if.sv" \
            "$PROJECT_ROOT/uvm_tb/tb_top_cu.sv" \
            > "$log" 2>&1
        then
            echo "Seed $seed: COMPILE FAIL" | tee -a "$report_file"
            fail_count=$((fail_count + 1))
            continue
        fi

        if vsim -c work.tb_top_cu \
            -sv_seed "$seed" \
            -do "run -all; quit -f" \
            +UVM_TESTNAME=cu_test \
            >> "$log" 2>&1
        then
            if grep -q "UVM_ERROR :    0" "$log"; then
                echo "Seed $seed: PASS" | tee -a "$report_file"
                pass_count=$((pass_count + 1))
            else
                echo "Seed $seed: FAIL (see $log)" | tee -a "$report_file"
                fail_count=$((fail_count + 1))
            fi
        else
            echo "Seed $seed: FAIL (see $log)" | tee -a "$report_file"
            fail_count=$((fail_count + 1))
        fi
    done

    cd "$PROJECT_ROOT" || return 1

    echo "----------------------------------------" >> "$report_file"
    echo "Summary: $pass_count PASS / $fail_count FAIL from $NUM_SEEDS seeds" \
        | tee -a "$report_file"

    if [ "$fail_count" -gt 0 ]; then
        return 1
    fi

    return 0
}

run_mmu() {
    run_iverilog_target \
        "mmu" \
        "mmu_tb" \
        "$PROJECT_ROOT/rtl/mmu.sv" \
        "$PROJECT_ROOT/tests/mmu_tb.sv"
}

run_register_file() {
    run_iverilog_target \
        "register_file" \
        "register_file_tb" \
        "$PROJECT_ROOT/rtl/register_file.sv" \
        "$PROJECT_ROOT/tests/register_file_tb.sv"
}

run_target() {
    local target="$1"

    case "$target" in
        alu)
            run_alu
            ;;

        cu)
            run_cu
            ;;

        mmu)
            run_mmu
            ;;

        register_file)
            run_register_file
            ;;

        all)
            local alu_status=0
            local cu_status=0
            local mmu_status=0
            local rf_status=0
            local fail_count=0

            run_alu
            alu_status=$?

            run_cu
            cu_status=$?

            run_mmu
            mmu_status=$?

            run_register_file
            rf_status=$?

            echo ""
            echo "========================================"
            echo "MULTI-TARGET REGRESSION SUMMARY"
            echo "========================================"
            echo "ALU            : $([ "$alu_status" -eq 0 ] && echo PASS || echo FAIL)"
            echo "CU             : $([ "$cu_status" -eq 0 ] && echo PASS || echo FAIL)"
            echo "MMU            : $([ "$mmu_status" -eq 0 ] && echo PASS || echo FAIL)"
            echo "REGISTER FILE   : $([ "$rf_status" -eq 0 ] && echo PASS || echo FAIL)"
            echo "========================================"

            [ "$alu_status" -ne 0 ] && fail_count=$((fail_count + 1))
            [ "$cu_status" -ne 0 ] && fail_count=$((fail_count + 1))
            [ "$mmu_status" -ne 0 ] && fail_count=$((fail_count + 1))
            [ "$rf_status" -ne 0 ] && fail_count=$((fail_count + 1))

            if [ "$fail_count" -gt 0 ]; then
                return 1
            fi

            return 0
            ;;

        *)
            echo "Unknown target: $target"
            echo ""
            echo "Usage:"
            echo "  ./run_regression.sh"
            echo "  ./run_regression.sh all"
            echo "  ./run_regression.sh alu [seeds]"
            echo "  ./run_regression.sh cu [seeds]"
            echo "  ./run_regression.sh mmu"
            echo "  ./run_regression.sh register_file"
            return 2
            ;;
    esac
}

run_target "$TARGET"
exit $?
