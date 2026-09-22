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


def normalize_spike_result(result):
    return type(result)(
        status=result.status,
        final_pc=(result.final_pc - PROGRAM_BASE) & UINT32_MASK
        if result.final_pc is not None
        else None,
        final_int_regs=result.final_int_regs,
        executed_count=result.executed_count,
        trace=normalize_spike_trace(result.trace),
        error=result.error,
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


def compare_results(expected, observed):
    mismatches = list(
        compare_traces(expected.trace, observed.trace).mismatches
    )

    if expected.final_pc != observed.final_pc:
        mismatches.append(
            DifferentialMismatch(
                commit_index=-1,
                field="final_pc",
                expected=expected.final_pc,
                observed=observed.final_pc,
            )
        )

    if expected.final_int_regs != observed.final_int_regs:
        if (
            expected.final_int_regs is not None
            and observed.final_int_regs is not None
        ):
            for index, (expected_value, observed_value) in enumerate(
                zip(expected.final_int_regs, observed.final_int_regs)
            ):
                if expected_value != observed_value:
                    mismatches.append(
                        DifferentialMismatch(
                            commit_index=-1,
                            field=f"final_int_regs[{index}]",
                            expected=expected_value,
                            observed=observed_value,
                        )
                    )
        else:
            mismatches.append(
                DifferentialMismatch(
                    commit_index=-1,
                    field="final_int_regs",
                    expected=expected.final_int_regs,
                    observed=observed.final_int_regs,
                )
            )

    return DifferentialResult(
        passed=not mismatches,
        mismatches=tuple(mismatches),
    )