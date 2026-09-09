#!/usr/bin/env python3

import re

from iss_contract import ISSCommit


DUT_COMMIT_RE = re.compile(
    r"^DUT_COMMIT\s+"
    r"(?P<pc>[0-9a-fA-F]{8})\s+"
    r"(?P<instruction>[0-9a-fA-F]{8})"
    r"(?:\s+x(?P<rd>\d+)\s+"
    r"(?P<value>[0-9a-fA-F]{8}))?$"
)


def parse_trace(path):
    commits = []

    with open(path, "r", encoding="utf-8") as stream:
        for line_number, line in enumerate(stream, start=1):
            stripped = line.strip()

            if not stripped:
                continue

            if stripped.startswith("DUT_FINAL_PC"):
                continue

            match = DUT_COMMIT_RE.fullmatch(stripped)

            if match is None:
                raise RuntimeError(
                    f"invalid DUT trace at line {line_number}: "
                    f"{stripped}"
                )

            pc = int(match.group("pc"), 16)
            instruction = int(match.group("instruction"), 16)

            rd_text = match.group("rd")
            value_text = match.group("value")

            if rd_text is None:
                rd_valid = False
                rd = None
                value = None
            else:
                rd_valid = True
                rd = int(rd_text)
                value = int(value_text, 16)

            commits.append(
                ISSCommit(
                    pc=pc,
                    instruction=instruction,
                    rd_valid=rd_valid,
                    rd=rd,
                    value=value,
                )
            )

    if not commits:
        raise RuntimeError("DUT architectural trace is empty")

    return tuple(commits)
