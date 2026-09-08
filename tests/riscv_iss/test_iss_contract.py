#!/usr/bin/env python3

import sys
from pathlib import Path

SCRIPT_DIR = (
    Path(__file__).resolve().parents[2]
    / "scripts"
    / "riscv_iss"
)

sys.path.insert(0, str(SCRIPT_DIR))

from iss_contract import (  # noqa: E402
    ISSBackend,
    ISSCommit,
    ISSRequest,
    ISSResult,
    ISSStatus,
)


def valid_request():
    return ISSRequest(
        program=tuple([0] * 64),
        program_word_count=0,
        initial_int_regs=tuple([0] * 32),
        execution_limit=32,
    )


def test_valid_request():
    request = valid_request()

    assert request.program_word_count == 0
    assert request.execution_limit == 32
    assert request.initial_int_regs[0] == 0


def test_invalid_program_size():
    try:
        ISSRequest(
            program=tuple([0] * 63),
            program_word_count=0,
            initial_int_regs=tuple([0] * 32),
            execution_limit=32,
        )
    except ValueError:
        return

    raise AssertionError(
        "invalid program size was accepted"
    )


def test_invalid_register_count():
    try:
        ISSRequest(
            program=tuple([0] * 64),
            program_word_count=0,
            initial_int_regs=tuple([0] * 31),
            execution_limit=32,
        )
    except ValueError:
        return

    raise AssertionError(
        "invalid register count was accepted"
    )


def test_nonzero_initial_x0():
    initial_regs = [0] * 32
    initial_regs[0] = 1

    try:
        ISSRequest(
            program=tuple([0] * 64),
            program_word_count=0,
            initial_int_regs=tuple(initial_regs),
            execution_limit=32,
        )
    except ValueError:
        return

    raise AssertionError(
        "nonzero initial x0 was accepted"
    )


def test_commit_without_destination():
    commit = ISSCommit(
        pc=0x80000000,
        instruction=0x00000013,
        rd_valid=False,
    )

    assert commit.rd is None
    assert commit.value is None


def test_commit_with_destination():
    commit = ISSCommit(
        pc=0x80000000,
        instruction=0x00500093,
        rd_valid=True,
        rd=1,
        value=5,
    )

    assert commit.rd == 1
    assert commit.value == 5


def test_pass_result():
    commit = ISSCommit(
        pc=0x80000000,
        instruction=0x00500093,
        rd_valid=True,
        rd=1,
        value=5,
    )

    regs = [0] * 32
    regs[1] = 5

    result = ISSResult(
        status=ISSStatus.PASS,
        final_pc=0x80000004,
        final_int_regs=tuple(regs),
        executed_count=1,
        trace=(commit,),
    )

    assert result.status is ISSStatus.PASS
    assert result.final_pc == 0x80000004
    assert result.final_int_regs[1] == 5


def test_fail_result_requires_error():
    try:
        ISSResult(
            status=ISSStatus.FAIL,
            final_pc=None,
            final_int_regs=None,
            executed_count=0,
            trace=tuple(),
            error="",
        )
    except ValueError:
        return

    raise AssertionError(
        "FAIL result without error was accepted"
    )


def test_backend_interface_is_defined():
    assert hasattr(ISSBackend, "execute")


if __name__ == "__main__":
    tests = [
        test_valid_request,
        test_invalid_program_size,
        test_invalid_register_count,
        test_nonzero_initial_x0,
        test_commit_without_destination,
        test_commit_with_destination,
        test_pass_result,
        test_fail_result_requires_error,
        test_backend_interface_is_defined,
    ]

    for test in tests:
        test()

    print(
        "[PASS] ISS contract tests "
        f"({len(tests)} tests)"
    )
