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
    PROGRAM_BASE,
    compare_results,
    compare_traces,
    normalize_spike_trace,
)
from iss_contract import ISSCommit, ISSResult, ISSStatus  # noqa: E402


def dut_trace():
    return (
        ISSCommit(
            pc=0x00000000,
            instruction=0x002081B3,
            rd_valid=True,
            rd=3,
            value=0x11,
        ),
        ISSCommit(
            pc=0x00000004,
            instruction=0x40218233,
            rd_valid=True,
            rd=4,
            value=0x0A,
        ),
        ISSCommit(
            pc=0x00000008,
            instruction=0x006202B3,
            rd_valid=True,
            rd=5,
            value=0x0F,
        ),
    )


def spike_trace():
    return tuple(
        ISSCommit(
            pc=PROGRAM_BASE + index * 4,
            instruction=commit.instruction,
            rd_valid=commit.rd_valid,
            rd=commit.rd,
            value=commit.value,
        )
        for index, commit in enumerate(dut_trace())
    )


def test_spike_pc_normalization():
    normalized = normalize_spike_trace(spike_trace())

    assert normalized == dut_trace()


def test_matching_traces_pass():
    expected = dut_trace()
    observed = normalize_spike_trace(spike_trace())

    result = compare_traces(expected, observed)

    assert result.passed
    assert result.mismatches == ()


def test_commit_count_mismatch():
    expected = dut_trace()
    observed = expected[:2]

    result = compare_traces(expected, observed)

    assert not result.passed
    assert result.mismatches[0].field == "commit_count"
    assert result.mismatches[0].expected == 3
    assert result.mismatches[0].observed == 2


def test_pc_mismatch():
    expected = dut_trace()
    observed = list(dut_trace())

    observed[1] = ISSCommit(
        pc=0x00000008,
        instruction=observed[1].instruction,
        rd_valid=observed[1].rd_valid,
        rd=observed[1].rd,
        value=observed[1].value,
    )

    result = compare_traces(expected, tuple(observed))

    assert not result.passed
    assert result.mismatches[0].commit_index == 1
    assert result.mismatches[0].field == "pc"


def test_instruction_mismatch():
    expected = dut_trace()
    observed = list(dut_trace())

    observed[1] = ISSCommit(
        pc=observed[1].pc,
        instruction=0x40118233,
        rd_valid=observed[1].rd_valid,
        rd=observed[1].rd,
        value=observed[1].value,
    )

    result = compare_traces(expected, tuple(observed))

    assert not result.passed
    assert result.mismatches[0].field == "instruction"


def test_destination_register_mismatch():
    expected = dut_trace()
    observed = list(dut_trace())

    observed[1] = ISSCommit(
        pc=observed[1].pc,
        instruction=observed[1].instruction,
        rd_valid=True,
        rd=5,
        value=observed[1].value,
    )

    result = compare_traces(expected, tuple(observed))

    assert not result.passed
    assert result.mismatches[0].field == "rd"


def test_value_mismatch():
    expected = dut_trace()
    observed = list(dut_trace())

    observed[1] = ISSCommit(
        pc=observed[1].pc,
        instruction=observed[1].instruction,
        rd_valid=True,
        rd=observed[1].rd,
        value=0x12345678,
    )

    result = compare_traces(expected, tuple(observed))

    assert not result.passed
    assert result.mismatches[0].field == "value"


def result_from_trace(trace, final_pc=0x0000000C):
    final_int_regs = [0] * 32

    for commit in trace:
        if commit.rd_valid and commit.rd != 0:
            final_int_regs[commit.rd] = commit.value

    return ISSResult(
        status=ISSStatus.PASS,
        final_pc=final_pc,
        final_int_regs=tuple(final_int_regs),
        executed_count=len(trace),
        trace=trace,
    )


def test_matching_results_pass():
    expected = result_from_trace(dut_trace())
    observed = result_from_trace(dut_trace())

    result = compare_results(expected, observed)

    assert result.passed
    assert result.mismatches == ()


def test_final_pc_mismatch():
    expected = result_from_trace(dut_trace(), final_pc=0x0000000C)
    observed = result_from_trace(dut_trace(), final_pc=0x00000010)

    result = compare_results(expected, observed)

    assert not result.passed
    assert result.mismatches[0].field == "final_pc"
    assert result.mismatches[0].expected == 0x0000000C
    assert result.mismatches[0].observed == 0x00000010


def test_final_register_mismatch():
    expected = result_from_trace(dut_trace())
    observed_regs = list(expected.final_int_regs)
    observed_regs[5] = 0xDEADBEEF

    observed = ISSResult(
        status=ISSStatus.PASS,
        final_pc=expected.final_pc,
        final_int_regs=tuple(observed_regs),
        executed_count=expected.executed_count,
        trace=expected.trace,
    )

    result = compare_results(expected, observed)

    assert not result.passed
    assert result.mismatches[0].field == "final_int_regs[5]"
    assert result.mismatches[0].expected == 0x0F
    assert result.mismatches[0].observed == 0xDEADBEEF


def test_compare_results_preserves_trace_mismatch_detection():
    expected = result_from_trace(dut_trace())
    observed_trace = list(dut_trace())
    observed_trace[1] = ISSCommit(
        pc=observed_trace[1].pc,
        instruction=observed_trace[1].instruction,
        rd_valid=True,
        rd=5,
        value=observed_trace[1].value,
    )
    observed = result_from_trace(tuple(observed_trace))

    result = compare_results(expected, observed)

    assert not result.passed
    assert result.mismatches[0].field == "rd"
    assert result.mismatches[0].commit_index == 1


if __name__ == "__main__":
    print("[PASS] differential comparator tests")