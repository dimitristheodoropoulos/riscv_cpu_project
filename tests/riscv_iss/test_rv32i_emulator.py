#!/usr/bin/env python3

import sys
from pathlib import Path


SCRIPT_DIR = (
    Path(__file__).resolve().parents[2]
    / "scripts"
    / "riscv_iss"
)

sys.path.insert(0, str(SCRIPT_DIR))

from differential_compare import (  # noqa: E402
    compare_results,
    normalize_spike_result,
)
from iss_contract import ISSRequest, ISSStatus  # noqa: E402
from rv32i_emulator_backend import RV32IEmulatorBackend  # noqa: E402
from spike_backend import SpikeBackend  # noqa: E402


def smoke_request():
    program = [0] * 64

    program[0] = 0x00500093  # addi x1, x0, 5
    program[1] = 0x00700113  # addi x2, x0, 7
    program[2] = 0x002081B3  # add  x3, x1, x2
    program[3] = 0x40118233  # sub  x4, x3, x1
    program[4] = 0x0021F2B3  # and  x5, x3, x2
    program[5] = 0x0020E333  # or   x6, x1, x2
    program[6] = 0x0020C3B3  # xor  x7, x1, x2
    program[7] = 0x00209433  # sll  x8, x1, x2
    program[8] = 0x401254B3  # sra  x9, x4, x1
    program[9] = 0x00322533  # slt  x10, x4, x3

    regs = [0] * 32

    return ISSRequest(
        program=tuple(program),
        program_word_count=10,
        initial_int_regs=tuple(regs),
        execution_limit=64,
    )


def test_emulator_matches_spike_alu_smoke():
    request = smoke_request()

    spike = SpikeBackend(
        spike_path="/home/dimitris/tools/riscv-isa-sim/build/spike",
        gcc_path="/usr/bin/riscv64-unknown-elf-gcc",
    )

    spike_result = spike.execute(request)
    emulator_result = RV32IEmulatorBackend().execute(request)

    assert spike_result.status is ISSStatus.PASS, spike_result.error
    assert emulator_result.status is ISSStatus.PASS, emulator_result.error

    normalized_spike_result = normalize_spike_result(spike_result)

    differential = compare_results(
        expected=normalized_spike_result,
        observed=emulator_result,
    )

    assert differential.passed, differential.mismatches

    print("[PASS] Spike ↔ emulator E1 differential cross-check")


def test_emulator_alu_smoke():
    backend = RV32IEmulatorBackend()
    result = backend.execute(smoke_request())

    assert result.status is ISSStatus.PASS, result.error
    assert result.executed_count == 10
    assert result.final_pc == 0x28

    assert result.final_int_regs[0] == 0
    assert result.final_int_regs[1] == 5
    assert result.final_int_regs[2] == 7
    assert result.final_int_regs[3] == 12
    assert result.final_int_regs[4] == 7
    assert result.final_int_regs[5] == 4
    assert result.final_int_regs[6] == 7
    assert result.final_int_regs[7] == 2
    assert result.final_int_regs[8] == 640
    assert result.final_int_regs[9] == 0
    assert result.final_int_regs[10] == 1

    assert len(result.trace) == 10
    assert result.trace[0].pc == 0x00
    assert result.trace[-1].pc == 0x24

    print("[PASS] RV32I emulator E1 ALU smoke")


def test_initial_x31_preserved():
    request = smoke_request()

    regs = list(request.initial_int_regs)
    regs[31] = 0x12345678

    request = ISSRequest(
        program=request.program,
        program_word_count=request.program_word_count,
        initial_int_regs=tuple(regs),
        execution_limit=request.execution_limit,
    )

    backend = RV32IEmulatorBackend()
    result = backend.execute(request)

    assert result.status is ISSStatus.PASS, result.error
    assert result.final_int_regs[31] == 0x12345678

    print("[PASS] emulator initial x31 preserved")


def test_execution_limit_bounds_architectural_execution():
    request = smoke_request()

    request = ISSRequest(
        program=request.program,
        program_word_count=request.program_word_count,
        initial_int_regs=request.initial_int_regs,
        execution_limit=9,
    )

    backend = RV32IEmulatorBackend()
    result = backend.execute(request)

    assert result.status is ISSStatus.PASS, result.error
    assert result.executed_count == 9
    assert result.final_pc == 0x24

    print("[PASS] emulator execution limit")


def test_emulator_e2_branch_store_load_matches_spike():
    program = [0] * 64

    program[0] = 0x002081B3  # ADD x3, x1, x2
    program[1] = 0x00210463  # BEQ x2, x2, +8
    program[2] = 0x00208A33  # ADD x20, x1, x2 (must be skipped)
    program[3] = 0x0020A023  # SW x2, 0(x1)
    program[4] = 0x0000A203  # LW x4, 0(x1)

    regs = [0] * 32
    regs[1] = 0x80002000
    regs[2] = 7

    request = ISSRequest(
        program=tuple(program),
        program_word_count=5,
        initial_int_regs=tuple(regs),
        execution_limit=4,
    )

    spike = SpikeBackend(
        spike_path="/home/dimitris/tools/riscv-isa-sim/build/spike",
        gcc_path="/usr/bin/riscv64-unknown-elf-gcc",
    )

    spike_result = spike.execute(request)
    emulator_result = RV32IEmulatorBackend().execute(request)

    assert spike_result.status is ISSStatus.PASS, spike_result.error
    assert emulator_result.status is ISSStatus.PASS, emulator_result.error

    normalized_spike_result = normalize_spike_result(spike_result)

    differential = compare_results(
        expected=normalized_spike_result,
        observed=emulator_result,
    )

    assert differential.passed, differential.mismatches

    assert emulator_result.executed_count == 4

    assert [commit.pc for commit in emulator_result.trace] == [
        0x00,
        0x04,
        0x0C,
        0x10,
    ]

    assert emulator_result.final_int_regs[3] == 0x80002007
    assert emulator_result.final_int_regs[4] == 7
    assert emulator_result.final_int_regs[20] == 0

    print("[PASS] RV32I emulator E2 branch/store/load differential")

def test_emulator_e2_branch_not_taken():
    program = [0] * 64

    program[0] = 0x00100093  # ADDI x1, x0, 1
    program[1] = 0x00200113  # ADDI x2, x0, 2
    program[2] = 0x00208463  # BEQ x1, x2, +8 (not taken)
    program[3] = 0x00900193  # ADDI x3, x0, 9

    request = ISSRequest(
        program=tuple(program),
        program_word_count=4,
        initial_int_regs=tuple([0] * 32),
        execution_limit=4,
    )

    result = RV32IEmulatorBackend().execute(request)

    assert result.status is ISSStatus.PASS, result.error
    assert result.executed_count == 4
    assert result.final_pc == 0x10
    assert result.final_int_regs[1] == 1
    assert result.final_int_regs[2] == 2
    assert result.final_int_regs[3] == 9

    assert [commit.pc for commit in result.trace] == [
        0x00,
        0x04,
        0x08,
        0x0C,
    ]

    print("[PASS] RV32I emulator E2 BEQ not-taken")


def test_emulator_e2_unwritten_aligned_lw_returns_zero():
    program = [0] * 64

    program[0] = 0x0000A103  # LW x2, 0(x1)

    regs = [0] * 32
    regs[1] = 0x80003000

    request = ISSRequest(
        program=tuple(program),
        program_word_count=1,
        initial_int_regs=tuple(regs),
        execution_limit=1,
    )

    result = RV32IEmulatorBackend().execute(request)

    assert result.status is ISSStatus.PASS, result.error
    assert result.executed_count == 1
    assert result.final_pc == 0x04
    assert result.final_int_regs[2] == 0

    assert result.trace[0].pc == 0x00
    assert result.trace[0].rd_valid is True
    assert result.trace[0].rd == 2
    assert result.trace[0].value == 0

    print("[PASS] RV32I emulator E2 unwritten aligned LW")

def test_emulator_e2_misaligned_lw_fails():
    program = [0] * 64
    program[0] = 0x0000A103  # LW x2, 0(x1)

    regs = [0] * 32
    regs[1] = 0x80003002  # misaligned address

    request = ISSRequest(
        program=tuple(program),
        program_word_count=1,
        initial_int_regs=tuple(regs),
        execution_limit=1,
    )

    result = RV32IEmulatorBackend().execute(request)

    assert result.status is ISSStatus.FAIL
    assert result.error

    print("[PASS] RV32I emulator E2 misaligned LW fails")


def test_emulator_e2_misaligned_sw_fails():
    program = [0] * 64
    program[0] = 0x0020A023  # SW x2, 0(x1)

    regs = [0] * 32
    regs[1] = 0x80003002  # misaligned address
    regs[2] = 0x12345678

    request = ISSRequest(
        program=tuple(program),
        program_word_count=1,
        initial_int_regs=tuple(regs),
        execution_limit=1,
    )

    result = RV32IEmulatorBackend().execute(request)

    assert result.status is ISSStatus.FAIL
    assert result.error

    print("[PASS] RV32I emulator E2 misaligned SW fails")

if __name__ == "__main__":
    tests = [
        test_emulator_matches_spike_alu_smoke,
        test_emulator_alu_smoke,
        test_initial_x31_preserved,
        test_execution_limit_bounds_architectural_execution,
        test_emulator_e2_branch_store_load_matches_spike,
        test_emulator_e2_branch_not_taken,
        test_emulator_e2_unwritten_aligned_lw_returns_zero,
        test_emulator_e2_misaligned_lw_fails,
        test_emulator_e2_misaligned_sw_fails,
    ]

    for test in tests:
        test()

    print(
        f"[PASS] RV32I emulator tests ({len(tests)} tests)"
    )
