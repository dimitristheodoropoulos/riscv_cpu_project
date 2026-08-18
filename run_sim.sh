#!/bin/bash

set -euo pipefail

TARGET="${1:-alu}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$PROJECT_ROOT/sim/work"
OUTPUT_DIR="$PROJECT_ROOT/sim/output"

echo "1. Cleaning previous work directory..."
rm -rf "$WORK_DIR"
mkdir -p "$OUTPUT_DIR"

echo "2. Creating simulation library..."
cd "$PROJECT_ROOT/sim"

vlib work
vmap work work

case "$TARGET" in

alu)
    echo "3. Compiling ALU RTL + UVM testbench..."

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
    ;;

cu)
    echo "3. Compiling CU RTL + UVM testbench..."

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
    ;;

cpu)
    echo "3. Compiling CPU integration RTL + testbench..."

    vlog -sv +cover=bcesf \
        "$PROJECT_ROOT/rtl/alu.sv" \
        "$PROJECT_ROOT/rtl/cache.sv" \
        "$PROJECT_ROOT/rtl/mmu.sv" \
        "$PROJECT_ROOT/rtl/register_file.sv" \
        "$PROJECT_ROOT/rtl/cpu_core.sv" \
        "$PROJECT_ROOT/tests/cpu_tb.sv"

    TOP="cpu_tb"
    TESTNAME=""
    ;;

cpu_exec)
    echo "3. Compiling CPU execution datapath + UVM testbench..."

    vlog -sv +cover=bcesf \
        +incdir+"$PROJECT_ROOT/uvm_tb/cpu_agent" \
        +incdir+"$PROJECT_ROOT/uvm_tb/cpu_env" \
        +incdir+"$PROJECT_ROOT/uvm_tb/cpu_model" \
        +incdir+"$PROJECT_ROOT/uvm_tb/sequences" \
        +incdir+"$PROJECT_ROOT/uvm_tb/tests" \
        "$PROJECT_ROOT/rtl/alu.sv" \
        "$PROJECT_ROOT/rtl/cu.sv" \
        "$PROJECT_ROOT/rtl/mmu.sv" \
        "$PROJECT_ROOT/rtl/register_file.sv" \
        "$PROJECT_ROOT/rtl/cpu_exec_core.sv" \
        "$PROJECT_ROOT/uvm_tb/cpu_agent/cpu_exec_assertions.sv" \
        "$PROJECT_ROOT/uvm_tb/cpu_agent/cpu_exec_if.sv" \
        "$PROJECT_ROOT/uvm_tb/cpu_agent/cpu_transaction.sv" \
        "$PROJECT_ROOT/uvm_tb/cpu_agent/cpu_driver.sv" \
        "$PROJECT_ROOT/uvm_tb/cpu_agent/cpu_monitor.sv" \
        "$PROJECT_ROOT/uvm_tb/cpu_agent/cpu_agent.sv" \
        "$PROJECT_ROOT/uvm_tb/cpu_model/cpu_reference_model.sv" \
        "$PROJECT_ROOT/uvm_tb/cpu_agent/cpu_scoreboard.sv" \
        "$PROJECT_ROOT/uvm_tb/cpu_agent/cpu_functional_coverage.sv" \
        "$PROJECT_ROOT/uvm_tb/cpu_env/cpu_env.sv" \
        "$PROJECT_ROOT/uvm_tb/sequences/cpu_exec_sequence.sv" \
        "$PROJECT_ROOT/uvm_tb/tests/cpu_exec_test.sv" \
        "$PROJECT_ROOT/uvm_tb/cpu_agent/cpu_exec_uvm_wrapper.sv" \
        "$PROJECT_ROOT/uvm_tb/tb_top_cpu_exec.sv"

    TOP="tb_top_cpu_exec"
    TESTNAME="cpu_exec_test"
    ;;

fpu)
    echo "3. Compiling FPU RTL + standalone testbench..."

    vlog -sv +cover=bcesf \
        "$PROJECT_ROOT/rtl/fpu_add.sv" \
        "$PROJECT_ROOT/rtl/fpu_sub.sv" \
        "$PROJECT_ROOT/rtl/fpu_mul.sv" \
        "$PROJECT_ROOT/rtl/fpu_div.sv" \
        "$PROJECT_ROOT/rtl/fpu.sv" \
        "$PROJECT_ROOT/tests/fpu_tb.sv"

    TOP="fpu_tb"
    TESTNAME=""
    ;;

fpu_smoke)
    echo "3. Compiling FPU RTL + UVM smoke test + SVA..."

    vlog -sv +cover=bcesf \
        +incdir+"$PROJECT_ROOT/uvm_tb/fpu_agent" \
        +incdir+"$PROJECT_ROOT/uvm_tb/env" \
        +incdir+"$PROJECT_ROOT/uvm_tb/sequences" \
        +incdir+"$PROJECT_ROOT/uvm_tb/tests" \
        "$PROJECT_ROOT/uvm_tb/fpu_agent/fpu_if.sv" \
        "$PROJECT_ROOT/uvm_tb/fpu_agent/fpu_sva.sv" \
        "$PROJECT_ROOT/uvm_tb/fpu_agent/fpu_pkg.sv" \
        "$PROJECT_ROOT/rtl/fpu_add.sv" \
        "$PROJECT_ROOT/rtl/fpu_sub.sv" \
        "$PROJECT_ROOT/rtl/fpu_mul.sv" \
        "$PROJECT_ROOT/rtl/fpu_div.sv" \
        "$PROJECT_ROOT/rtl/fpu.sv" \
        "$PROJECT_ROOT/uvm_tb/tests/fpu_smoke_test.sv" \
        "$PROJECT_ROOT/uvm_tb/tb_top_fpu.sv"

    TOP="tb_top_fpu"
    TESTNAME="fpu_smoke_test"
    ;;

fpu_long)
    echo "3. Compiling FPU RTL + UVM testbench + SVA (long regression)..."

    vlog -sv +cover=bcesf \
        +incdir+"$PROJECT_ROOT/uvm_tb/fpu_agent" \
        +incdir+"$PROJECT_ROOT/uvm_tb/env" \
        +incdir+"$PROJECT_ROOT/uvm_tb/sequences" \
        +incdir+"$PROJECT_ROOT/uvm_tb/tests" \
        "$PROJECT_ROOT/uvm_tb/fpu_agent/fpu_if.sv" \
        "$PROJECT_ROOT/uvm_tb/fpu_agent/fpu_sva.sv" \
        "$PROJECT_ROOT/uvm_tb/fpu_agent/fpu_pkg.sv" \
        "$PROJECT_ROOT/rtl/fpu_add.sv" \
        "$PROJECT_ROOT/rtl/fpu_sub.sv" \
        "$PROJECT_ROOT/rtl/fpu_mul.sv" \
        "$PROJECT_ROOT/rtl/fpu_div.sv" \
        "$PROJECT_ROOT/rtl/fpu.sv" \
        "$PROJECT_ROOT/uvm_tb/tests/fpu_smoke_test.sv" \
        "$PROJECT_ROOT/uvm_tb/tb_top_fpu.sv"

    TOP="tb_top_fpu"
    TESTNAME="fpu_long_regression_test"
    ;;

fpu_diff)
    echo "3. Compiling FPU RTL + differential testbench (coverage)..."

    vlog -sv +cover=bcesf \
        "$PROJECT_ROOT/rtl/fpu_add.sv" \
        "$PROJECT_ROOT/rtl/fpu_sub.sv" \
        "$PROJECT_ROOT/rtl/fpu_mul.sv" \
        "$PROJECT_ROOT/rtl/fpu_div.sv" \
        "$PROJECT_ROOT/rtl/fpu.sv" \
        "$PROJECT_ROOT/tests/fpu_differential_tb.sv"

    TOP="fpu_differential_tb"
    TESTNAME=""
    ;;

fpu_closure)
    echo "3. Compiling FPU RTL + UVM testbench + SVA (coverage closure)..."

    vlog -sv +cover=bcesf \
        +incdir+"$PROJECT_ROOT/uvm_tb/fpu_agent" \
        +incdir+"$PROJECT_ROOT/uvm_tb/env" \
        +incdir+"$PROJECT_ROOT/uvm_tb/sequences" \
        +incdir+"$PROJECT_ROOT/uvm_tb/tests" \
        "$PROJECT_ROOT/uvm_tb/fpu_agent/fpu_if.sv" \
        "$PROJECT_ROOT/uvm_tb/fpu_agent/fpu_sva.sv" \
        "$PROJECT_ROOT/uvm_tb/fpu_agent/fpu_pkg.sv" \
        "$PROJECT_ROOT/rtl/fpu_add.sv" \
        "$PROJECT_ROOT/rtl/fpu_sub.sv" \
        "$PROJECT_ROOT/rtl/fpu_mul.sv" \
        "$PROJECT_ROOT/rtl/fpu_div.sv" \
        "$PROJECT_ROOT/rtl/fpu.sv" \
        "$PROJECT_ROOT/uvm_tb/tests/fpu_smoke_test.sv" \
        "$PROJECT_ROOT/uvm_tb/tb_top_fpu.sv"

    TOP="tb_top_fpu"
    TESTNAME="fpu_closure_test"
    ;;

fpu_sva)
    echo "3. Compiling FPU RTL + UVM testbench + SVA..."

    vlog -sv +cover=bcesf \
        +incdir+"$PROJECT_ROOT/uvm_tb/fpu_agent" \
        +incdir+"$PROJECT_ROOT/uvm_tb/env" \
        +incdir+"$PROJECT_ROOT/uvm_tb/sequences" \
        +incdir+"$PROJECT_ROOT/uvm_tb/tests" \
        "$PROJECT_ROOT/uvm_tb/fpu_agent/fpu_if.sv" \
        "$PROJECT_ROOT/uvm_tb/fpu_agent/fpu_sva.sv" \
        "$PROJECT_ROOT/uvm_tb/fpu_agent/fpu_pkg.sv" \
        "$PROJECT_ROOT/rtl/fpu_add.sv" \
        "$PROJECT_ROOT/rtl/fpu_sub.sv" \
        "$PROJECT_ROOT/rtl/fpu_mul.sv" \
        "$PROJECT_ROOT/rtl/fpu_div.sv" \
        "$PROJECT_ROOT/rtl/fpu.sv" \
        "$PROJECT_ROOT/uvm_tb/tests/fpu_smoke_test.sv" \
        "$PROJECT_ROOT/uvm_tb/tb_top_fpu.sv"

    TOP="tb_top_fpu"
    TESTNAME="fpu_smoke_test"
    ;;

*)
    echo "Unknown target: $TARGET"
    echo ""
    echo "Usage:"
    echo "  ./run_sim.sh alu"
    echo "  ./run_sim.sh cu"
    echo "  ./run_sim.sh cpu"
    echo "  ./run_sim.sh cpu_exec"
    echo "  ./run_sim.sh fpu"
    echo "  ./run_sim.sh fpu_smoke"
    echo "  ./run_sim.sh fpu_long"
    echo "  ./run_sim.sh fpu_diff"
    echo "  ./run_sim.sh fpu_closure"
    echo "  ./run_sim.sh fpu_sva"
    exit 1
    ;;

esac

echo "4. Running simulation..."

if [ -n "$TESTNAME" ]; then

    vsim -c "work.$TOP" \
        -onfinish stop \
        -coverage \
        -voptargs=+cover \
        -do "run -all; coverage save $OUTPUT_DIR/${TARGET}.ucdb; quit -f" \
        "+UVM_TESTNAME=$TESTNAME"

else

    vsim -c "work.$TOP" \
        -onfinish stop \
        -coverage \
        -voptargs=+cover \
        -do "run -all; coverage save $OUTPUT_DIR/${TARGET}.ucdb; quit -f"

fi

echo "5. Creating coverage report..."

UCDB="$OUTPUT_DIR/${TARGET}.ucdb"

if [ -f "$UCDB" ]; then

    vcover report -details \
        "$UCDB" \
        > "$OUTPUT_DIR/${TARGET}_coverage_report.txt"

    echo ""
    echo "Coverage report:"
    echo "  Full: sim/output/${TARGET}_coverage_report.txt"

else

    echo "WARNING: UCDB file was not generated."
    exit 1

fi

echo "Simulation completed successfully."