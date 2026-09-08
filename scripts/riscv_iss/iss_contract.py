#!/usr/bin/env python3

from dataclasses import dataclass, field
from enum import Enum
from typing import Sequence


PROGRAM_WORD_CAPACITY = 64
INTEGER_REGISTER_COUNT = 32
UINT32_MASK = 0xFFFFFFFF


class ISSStatus(Enum):
    PASS = "PASS"
    FAIL = "FAIL"


@dataclass(frozen=True)
class ISSRequest:
    program: tuple[int, ...]
    program_word_count: int
    initial_int_regs: tuple[int, ...]
    execution_limit: int

    def __post_init__(self):
        if len(self.program) != PROGRAM_WORD_CAPACITY:
            raise ValueError(
                f"program must contain exactly "
                f"{PROGRAM_WORD_CAPACITY} words"
            )

        if len(self.initial_int_regs) != INTEGER_REGISTER_COUNT:
            raise ValueError(
                f"initial_int_regs must contain exactly "
                f"{INTEGER_REGISTER_COUNT} registers"
            )

        if not (0 <= self.program_word_count <= PROGRAM_WORD_CAPACITY):
            raise ValueError(
                "program_word_count must be in range 0..64"
            )

        if self.execution_limit <= 0:
            raise ValueError("execution_limit must be positive")

        for index, value in enumerate(self.program):
            if not (0 <= value <= UINT32_MASK):
                raise ValueError(
                    f"program[{index}] is not a 32-bit unsigned value"
                )

        for index, value in enumerate(self.initial_int_regs):
            if not (0 <= value <= UINT32_MASK):
                raise ValueError(
                    f"initial_int_regs[{index}] is not a "
                    "32-bit unsigned value"
                )

        if self.initial_int_regs[0] != 0:
            raise ValueError("initial_int_regs[0] must be zero")


@dataclass(frozen=True)
class ISSCommit:
    pc: int
    instruction: int
    rd_valid: bool
    rd: int | None = None
    value: int | None = None

    def __post_init__(self):
        if not (0 <= self.pc <= UINT32_MASK):
            raise ValueError("pc must be a 32-bit unsigned value")

        if self.pc & 0x3:
            raise ValueError("pc must be 4-byte aligned")

        if not (0 <= self.instruction <= UINT32_MASK):
            raise ValueError(
                "instruction must be a 32-bit unsigned value"
            )

        if self.rd_valid:
            if self.rd is None:
                raise ValueError("rd is required when rd_valid is true")

            if not (0 <= self.rd < INTEGER_REGISTER_COUNT):
                raise ValueError("rd must be in range 0..31")

            if self.value is None:
                raise ValueError(
                    "value is required when rd_valid is true"
                )

            if not (0 <= self.value <= UINT32_MASK):
                raise ValueError(
                    "value must be a 32-bit unsigned value"
                )
        else:
            if self.rd is not None or self.value is not None:
                raise ValueError(
                    "rd and value must be None when rd_valid is false"
                )


@dataclass(frozen=True)
class ISSResult:
    status: ISSStatus
    final_pc: int | None
    final_int_regs: tuple[int, ...] | None
    executed_count: int
    trace: tuple[ISSCommit, ...] = field(default_factory=tuple)
    error: str = ""

    def __post_init__(self):
        if self.executed_count < 0:
            raise ValueError("executed_count cannot be negative")

        if self.status is ISSStatus.PASS:
            if self.final_pc is None:
                raise ValueError(
                    "PASS result requires final_pc"
                )

            if self.final_int_regs is None:
                raise ValueError(
                    "PASS result requires final_int_regs"
                )

            if len(self.final_int_regs) != INTEGER_REGISTER_COUNT:
                raise ValueError(
                    "final_int_regs must contain exactly 32 registers"
                )

            if self.final_pc & 0x3:
                raise ValueError(
                    "final_pc must be 4-byte aligned"
                )

            for index, value in enumerate(self.final_int_regs):
                if not (0 <= value <= UINT32_MASK):
                    raise ValueError(
                        f"final_int_regs[{index}] is not a "
                        "32-bit unsigned value"
                    )

            if self.final_int_regs[0] != 0:
                raise ValueError(
                    "final_int_regs[0] must be zero"
                )

            if self.executed_count != len(self.trace):
                raise ValueError(
                    "executed_count must equal trace length "
                    "for PASS results"
                )

        elif self.status is ISSStatus.FAIL:
            if not self.error:
                raise ValueError(
                    "FAIL result requires an error message"
                )


class ISSBackend:
    def execute(self, request: ISSRequest) -> ISSResult:
        raise NotImplementedError
