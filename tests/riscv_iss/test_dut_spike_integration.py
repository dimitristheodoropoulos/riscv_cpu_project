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
from differential_compare import (
    compare_traces,
    normalize_spike_trace,
)
from iss_contract import ISSRequest, ISSStatus
from spike_backend import SpikeBackend


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DUT_TRACE = PROJECT_ROOT / "dut_spike_diff.trace"


PROGRAM = (
    0x002081B3,  # ADD x3, x1, x2
    0x40218233,  # SUB x4, x3, x2
    0x0020F2B3,  # AND x5, x1, x2
    0x0020E3B3,  # OR  x7, x1, x2
    0x0020C433,  # XOR x8, x1, x2
    0x006114B3,  # SLL x9, x2, x6
    0x00112533,  # SLT x10, x2, x1
)

INITIAL_REGS = [0] * 32
INITIAL_REGS[1] = 10
INITIAL_REGS[2] = 7
INITIAL_REGS[6] = 5


def make_request():
    program = PROGRAM + (0,) * (64 - len(PROGRAM))

    return ISSRequest(
        program=program,
        program_word_count=len(PROGRAM),
        initial_int_regs=tuple(INITIAL_REGS),
        execution_limit=7,
    )


def test_real_dut_matches_real_spike():
    assert DUT_TRACE.exists(), (
        f"DUT trace not found: {DUT_TRACE}"
    )

    dut_trace = parse_trace(DUT_TRACE)

    backend = SpikeBackend(
        spike_path="/home/dimitris/tools/riscv-isa-sim/build/spike",
        gcc_path="/usr/bin/riscv64-unknown-elf-gcc",
    )
    spike_result = backend.execute(make_request())

    assert spike_result.status == ISSStatus.PASS, (
        f"Spike execution failed: {spike_result.error}"
    )

    spike_trace = normalize_spike_trace(spike_result.trace)

    result = compare_traces(
        expected=dut_trace,
        observed=spike_trace,
    )

    if not result.passed:
        mismatch = result.mismatches[0]

        raise AssertionError(
            "DUT ↔ Spike differential mismatch: "
            f"commit_index={mismatch.commit_index}, "
            f"field={mismatch.field}, "
            f"expected={mismatch.expected!r}, "
            f"observed={mismatch.observed!r}"
        )

    assert len(dut_trace) == 7
    assert len(spike_trace) == 7


if __name__ == "__main__":
    test_real_dut_matches_real_spike()
    print("[PASS] real DUT ↔ Spike differential integration")
