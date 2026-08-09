#!/bin/bash
set -uo pipefail  # όχι -e, θέλουμε να συνεχίσουμε ακόμα κι αν κάποιο seed αποτύχει

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-alu}"
NUM_SEEDS="${2:-10}"
REPORT_FILE="$PROJECT_ROOT/sim/output/${TARGET}_regression_report.txt"

echo "Regression: target=$TARGET, seeds=$NUM_SEEDS"
echo "Target: $TARGET | Seeds: $NUM_SEEDS | Date: $(date)" > "$REPORT_FILE"
echo "----------------------------------------" >> "$REPORT_FILE"

PASS_COUNT=0
FAIL_COUNT=0

for i in $(seq 1 "$NUM_SEEDS"); do
    SEED=$((RANDOM * RANDOM))
    LOG="$PROJECT_ROOT/sim/output/${TARGET}_seed${SEED}.log"

    cd "$PROJECT_ROOT/sim"
    vlib work > /dev/null 2>&1
    vmap work work > /dev/null 2>&1

    if [ "$TARGET" == "alu" ]; then
        vlog -sv \
            +incdir+"$PROJECT_ROOT/uvm_tb/alu_agent" \
            +incdir+"$PROJECT_ROOT/uvm_tb/env" \
            +incdir+"$PROJECT_ROOT/uvm_tb/sequences" \
            +incdir+"$PROJECT_ROOT/uvm_tb/tests" \
            "$PROJECT_ROOT/rtl/alu.sv" \
            "$PROJECT_ROOT/uvm_tb/alu_agent/alu_if.sv" \
            "$PROJECT_ROOT/uvm_tb/tb_top.sv" > /dev/null 2>&1
        TOP="tb_top"; TESTNAME="alu_test"
    else
        vlog -sv \
            +incdir+"$PROJECT_ROOT/uvm_tb/cu_agent" \
            +incdir+"$PROJECT_ROOT/uvm_tb/env" \
            +incdir+"$PROJECT_ROOT/uvm_tb/sequences" \
            +incdir+"$PROJECT_ROOT/uvm_tb/tests" \
            "$PROJECT_ROOT/rtl/cu.sv" \
            "$PROJECT_ROOT/uvm_tb/cu_agent/cu_if.sv" \
            "$PROJECT_ROOT/uvm_tb/tb_top_cu.sv" > /dev/null 2>&1
        TOP="tb_top_cu"; TESTNAME="cu_test"
    fi

    vsim -c work.$TOP -sv_seed $SEED -do "run -all; quit -f" \
        +UVM_TESTNAME=$TESTNAME > "$LOG" 2>&1

    if grep -q "UVM_ERROR :    0" "$LOG"; then
        echo "Seed $SEED: PASS" | tee -a "$REPORT_FILE"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "Seed $SEED: FAIL (βλ. $LOG)" | tee -a "$REPORT_FILE"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

echo "----------------------------------------" >> "$REPORT_FILE"
echo "Σύνοψη: $PASS_COUNT PASS / $FAIL_COUNT FAIL από $NUM_SEEDS seeds" | tee -a "$REPORT_FILE"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi