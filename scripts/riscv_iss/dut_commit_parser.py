#!/usr/bin/env python3

import re

from iss_contract import ISSCommit


DUT_COMMIT_RE = re.compile(
    r"^DUT_COMMIT\s+"
    r"(?P<pc>[0-9a-fA-F]{8})\s+"
    r"(?P<instruction>[0-9a-fA-F]{8})\s+"
    r"x(?P<rd>\d+)\s+"
    r"(?P<value>[0-9a-fA-F]{8})$"
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
            rd = int(match.group("rd"))
            value = int(match.group("value"), 16)

            commits.append(
                ISSCommit(
                    pc=pc,
                    instruction=instruction,
                    rd_valid=True,
                    rd=rd,
                    value=value,
                )
            )

    if not commits:
        raise RuntimeError("DUT architectural trace is empty")

    return tuple(commits)
