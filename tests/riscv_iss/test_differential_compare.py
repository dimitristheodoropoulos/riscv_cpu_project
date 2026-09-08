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
    compare_traces,
    normalize_spike_trace,
)
from iss_contract import ISSCommit  # noqa: E402


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


if __name__ == "__main__":
    print("[PASS] differential comparator tests")
