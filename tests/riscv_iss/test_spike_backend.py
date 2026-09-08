#!/usr/bin/env python3

import sys
from pathlib import Path

SCRIPT_DIR = (
    Path(__file__).resolve().parents[2]
    / "scripts"
    / "riscv_iss"
)

sys.path.insert(0, str(SCRIPT_DIR))

from iss_contract import ISSRequest, ISSStatus  # noqa: E402
from spike_backend import SpikeBackend  # noqa: E402


SPIKE = "/home/dimitris/tools/riscv-isa-sim/build/spike"
GCC = "/usr/bin/riscv64-unknown-elf-gcc"


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


def test_spike_alu_smoke():
    backend = SpikeBackend(
        spike_path=SPIKE,
        gcc_path=GCC,
    )

    result = backend.execute(smoke_request())

    assert result.status is ISSStatus.PASS, result.error
    assert result.executed_count == 10

    assert result.final_pc == 0x80000028

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

    assert result.trace[0].pc == 0x80000000
    assert result.trace[-1].pc == 0x80000024

    print("[PASS] SpikeBackend RV32I ALU integration")


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

    backend = SpikeBackend(
        spike_path=SPIKE,
        gcc_path=GCC,
    )

    result = backend.execute(request)

    assert result.status is ISSStatus.PASS, result.error
    assert result.final_int_regs[31] == 0x12345678

    print("[PASS] initial x31 preserved")


if __name__ == "__main__":
    tests = [
        test_spike_alu_smoke,
        test_initial_x31_preserved,
    ]

    for test in tests:
        test()

    print(
        f"[PASS] SpikeBackend integration tests ({len(tests)} tests)"
    )


def test_execution_limit_counts_program_instructions():
    request = smoke_request()

    request = ISSRequest(
        program=request.program,
        program_word_count=request.program_word_count,
        initial_int_regs=request.initial_int_regs,
        execution_limit=10,
    )

    backend = SpikeBackend(
        spike_path=SPIKE,
        gcc_path=GCC,
    )

    result = backend.execute(request)

    assert result.status is ISSStatus.PASS, result.error
    assert result.executed_count == 10
    assert result.final_pc == 0x80000028

    print(
        "[PASS] execution_limit counts architectural program instructions"
    )


def test_execution_limit_rejects_incomplete_program():
    request = smoke_request()

    request = ISSRequest(
        program=request.program,
        program_word_count=request.program_word_count,
        initial_int_regs=request.initial_int_regs,
        execution_limit=9,
    )

    backend = SpikeBackend(
        spike_path=SPIKE,
        gcc_path=GCC,
    )

    result = backend.execute(request)

    assert result.status is ISSStatus.FAIL
    assert "architectural commit count mismatch" in result.error

    print(
        "[PASS] execution_limit rejects incomplete architectural program"
    )
