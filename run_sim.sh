#!/bin/bash
set -e

TARGET="${1:-alu}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$PROJECT_ROOT/sim/work"

echo "1. Καθαρισμός προηγούμενου work directory..."
rm -rf "$WORK_DIR"
mkdir -p "$PROJECT_ROOT/sim/output"

echo "2. Δημιουργία vlib..."
cd "$PROJECT_ROOT/sim"
vlib work
vmap work work

if [ "$TARGET" == "alu" ]; then
    echo "3. Compile ALU block RTL + UVM testbench (με code coverage)..."
    vlog -sv +cover=bcesf \
        +incdir+"$PROJECT_ROOT/uvm_tb/alu_agent" \
        +incdir+"$PROJECT_ROOT/uvm_tb/env" \
        +incdir+"$PROJECT_ROOT/uvm_tb/sequences" \
        +incdir+"$PROJECT_ROOT/uvm_tb/tests" \
        "$PROJECT_ROOT/rtl/alu.sv" \
        "$PROJECT_ROOT/uvm_tb/alu_agent/alu_if.sv" \
        "$PROJECT_ROOT/uvm_tb/tb_top.sv"
    TOP="tb_top"
    TESTNAME="alu_test"
elif [ "$TARGET" == "cu" ]; then
    echo "3. Compile CU block RTL + UVM testbench (με code coverage)..."
    vlog -sv +cover=bcesf \
        +incdir+"$PROJECT_ROOT/uvm_tb/cu_agent" \
        +incdir+"$PROJECT_ROOT/uvm_tb/env" \
        +incdir+"$PROJECT_ROOT/uvm_tb/sequences" \
        +incdir+"$PROJECT_ROOT/uvm_tb/tests" \
        "$PROJECT_ROOT/rtl/cu.sv" \
        "$PROJECT_ROOT/uvm_tb/cu_agent/cu_if.sv" \
        "$PROJECT_ROOT/uvm_tb/tb_top_cu.sv"
    TOP="tb_top_cu"
    TESTNAME="cu_test"
else
    echo "Άγνωστο target: $TARGET (χρησιμοποίησε 'alu' ή 'cu')"
    exit 1
fi

echo "4. Εκτέλεση simulation (με coverage collection)..."
vsim -c work.$TOP -coverage -do "coverage save -onexit $PROJECT_ROOT/sim/output/${TARGET}.ucdb; run -all; quit -f" \
    +UVM_TESTNAME=$TESTNAME

echo "5. Δημιουργία code coverage report..."
vcover report -details "$PROJECT_ROOT/sim/output/${TARGET}.ucdb" \
    > "$PROJECT_ROOT/sim/output/${TARGET}_coverage_report.txt"

echo "Coverage report: sim/output/${TARGET}_coverage_report.txt"
echo "Ολοκληρώθηκε."