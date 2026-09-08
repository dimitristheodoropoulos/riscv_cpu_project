#!/usr/bin/env python3

import sys
from pathlib import Path

SCRIPT_DIR = (
    Path(__file__).resolve().parents[2]
    / "scripts"
    / "riscv_iss"
)

sys.path.insert(0, str(SCRIPT_DIR))

from dut_commit_parser import parse_trace
from differential_compare import compare_traces
from iss_contract import ISSCommit


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DUT_TRACE = PROJECT_ROOT / "dut_spike_diff.trace"

CORRUPTED_VALUE = 0xDEADBEEF


def test_deliberate_architectural_value_mismatch_is_localized(tmp_path):
    assert DUT_TRACE.exists(), (
        f"DUT trace not found: {DUT_TRACE}"
    )

    original_trace = parse_trace(DUT_TRACE)

    corrupted_trace = list(original_trace)

    target = corrupted_trace[1]

    corrupted_trace[1] = ISSCommit(
        pc=target.pc,
        instruction=target.instruction,
        rd_valid=target.rd_valid,
        rd=target.rd,
        value=CORRUPTED_VALUE,
    )

    result = compare_traces(
        expected=original_trace,
        observed=tuple(corrupted_trace),
    )

    assert not result.passed
    assert len(result.mismatches) == 1

    mismatch = result.mismatches[0]

    assert mismatch.commit_index == 1
    assert mismatch.field == "value"
    assert mismatch.expected == original_trace[1].value
    assert mismatch.observed == CORRUPTED_VALUE


if __name__ == "__main__":
    test_deliberate_architectural_value_mismatch_is_localized(None)
    print("[PASS] deliberate differential fault injection detected")
