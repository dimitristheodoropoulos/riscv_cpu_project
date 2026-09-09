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


# Patch 3 architectural differential program:
#
# x1 = 0x80002000
# x2 = 7
#
# 0x00: ADD x3, x1, x2
# 0x04: BEQ x2, x2, +8   -> taken, skips 0x08
# 0x08: ADD x20, x1, x2  -> skipped
# 0x0c: SW  x2, 0(x1)
# 0x10: LW  x4, 0(x1)
#
# Expected architectural commits:
#   ADD, BEQ, SW, LW
#
# Expected final PC:
#   0x14
#
# Spike runs the same program at 0x80000000 and the
# differential layer normalizes Spike PCs back to DUT-relative PCs.

PROGRAM = (
    0x002081B3,  # ADD x3, x1, x2
    0x00210463,  # BEQ x2, x2, +8
    0x00208A33,  # ADD x20, x1, x2 (skipped)
    0x0020A023,  # SW x2, 0(x1)
    0x0000A203,  # LW x4, 0(x1)
)

INITIAL_REGS = [0] * 32
INITIAL_REGS[1] = 0x80002000
INITIAL_REGS[2] = 7


def make_request():
    program = PROGRAM + (0,) * (64 - len(PROGRAM))

    return ISSRequest(
        program=program,
        program_word_count=len(PROGRAM),
        initial_int_regs=tuple(INITIAL_REGS),
        execution_limit=4,
    )


def test_real_dut_matches_real_spike():
    assert DUT_TRACE.exists(), (
        f"missing DUT trace: {DUT_TRACE}"
    )

    dut_trace = parse_trace(DUT_TRACE)

    backend = SpikeBackend(
        spike_path="/home/dimitris/tools/riscv-isa-sim/build/spike",
        gcc_path="/usr/bin/riscv64-unknown-elf-gcc",
    )

    spike_result = backend.execute(make_request())

    assert spike_result.status == ISSStatus.PASS, (
        "Spike backend failed: "
        f"{spike_result.error}"
    )

    spike_trace = normalize_spike_trace(
        spike_result.trace
    )

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

    assert len(dut_trace) == 4
    assert len(spike_trace) == 4

    assert dut_trace[-1].pc == 0x10
    assert spike_trace[-1].pc == 0x10


if __name__ == "__main__":
    test_real_dut_matches_real_spike()
    print("[PASS] real DUT ↔ Spike differential integration")
