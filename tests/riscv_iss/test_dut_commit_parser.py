#!/usr/bin/env python3

import sys
from pathlib import Path

SCRIPT_DIR = (
    Path(__file__).resolve().parents[2]
    / "scripts"
    / "riscv_iss"
)

sys.path.insert(0, str(SCRIPT_DIR))

from dut_commit_parser import parse_trace  # noqa: E402


def write_trace(tmp_path, text):
    path = tmp_path / "dut.trace"
    path.write_text(text, encoding="utf-8")
    return path


def test_valid_dut_trace(tmp_path):
    path = write_trace(
        tmp_path,
        """
DUT_COMMIT 00000000 002081b3 x3 00000011
DUT_COMMIT 00000004 40218233 x4 0000000a
DUT_COMMIT 00000008 006202b3 x5 0000000f
DUT_FINAL_PC 0000000c
""",
    )

    trace = parse_trace(path)

    assert len(trace) == 3
    assert trace[0].pc == 0
    assert trace[0].instruction == 0x002081B3
    assert trace[0].rd == 3
    assert trace[0].value == 17
    assert trace[-1].pc == 8


def test_final_pc_is_not_a_commit(tmp_path):
    path = write_trace(
        tmp_path,
        "DUT_FINAL_PC 0000000c\n"
        "DUT_COMMIT 00000000 002081b3 x3 00000011\n",
    )

    trace = parse_trace(path)

    assert len(trace) == 1


def test_malformed_commit_is_rejected(tmp_path):
    path = write_trace(
        tmp_path,
        "DUT_COMMIT 00000000 002081b3 x3\n",
    )

    try:
        parse_trace(path)
    except RuntimeError as exc:
        assert "invalid DUT trace" in str(exc)
        return

    raise AssertionError("malformed DUT trace was accepted")


def test_empty_trace_is_rejected(tmp_path):
    path = write_trace(
        tmp_path,
        "DUT_FINAL_PC 0000000c\n",
    )

    try:
        parse_trace(path)
    except RuntimeError as exc:
        assert "empty" in str(exc)
        return

    raise AssertionError("empty DUT trace was accepted")


def test_invalid_register_is_rejected_by_contract(tmp_path):
    path = write_trace(
        tmp_path,
        "DUT_COMMIT 00000000 002081b3 x32 00000011\n",
    )

    try:
        parse_trace(path)
    except ValueError:
        return

    raise AssertionError("invalid destination register was accepted")
