#!/usr/bin/env python3

from dataclasses import dataclass

from iss_contract import ISSCommit, UINT32_MASK


PROGRAM_BASE = 0x80000000


@dataclass(frozen=True)
class DifferentialMismatch:
    commit_index: int
    field: str
    expected: object
    observed: object


@dataclass(frozen=True)
class DifferentialResult:
    passed: bool
    mismatches: tuple[DifferentialMismatch, ...] = ()


def normalize_spike_commit(commit):
    return ISSCommit(
        pc=(commit.pc - PROGRAM_BASE) & UINT32_MASK,
        instruction=commit.instruction,
        rd_valid=commit.rd_valid,
        rd=commit.rd,
        value=commit.value,
    )


def normalize_spike_trace(trace):
    return tuple(
        normalize_spike_commit(commit)
        for commit in trace
    )


def compare_traces(expected, observed):
    mismatches = []

    if len(expected) != len(observed):
        mismatches.append(
            DifferentialMismatch(
                commit_index=min(len(expected), len(observed)),
                field="commit_count",
                expected=len(expected),
                observed=len(observed),
            )
        )

    for index, (expected_commit, observed_commit) in enumerate(
        zip(expected, observed)
    ):
        fields = (
            ("pc", expected_commit.pc, observed_commit.pc),
            (
                "instruction",
                expected_commit.instruction,
                observed_commit.instruction,
            ),
            (
                "rd_valid",
                expected_commit.rd_valid,
                observed_commit.rd_valid,
            ),
            ("rd", expected_commit.rd, observed_commit.rd),
            ("value", expected_commit.value, observed_commit.value),
        )

        for field, expected_value, observed_value in fields:
            if expected_value != observed_value:
                mismatches.append(
                    DifferentialMismatch(
                        commit_index=index,
                        field=field,
                        expected=expected_value,
                        observed=observed_value,
                    )
                )

    return DifferentialResult(
        passed=not mismatches,
        mismatches=tuple(mismatches),
    )
