#!/usr/bin/env python3

import subprocess
import tempfile
from pathlib import Path

from iss_contract import (
    ISSBackend,
    ISSCommit,
    ISSRequest,
    ISSResult,
    ISSStatus,
)


PROGRAM_BASE = 0x80000000
SETUP_BASE = 0x80001000

# Spike executes a fixed five-instruction runtime/boot sequence before
# transferring control to the ELF entry point under the current backend
# invocation contract.
SPIKE_BOOT_INSTRUCTION_COUNT = 5


class SpikeBackend(ISSBackend):
    """Spike implementation of the generic ISSBackend contract.

    Current Patch 2A scope:
      - RV32I
      - sequential program image
      - register/ALU architectural state
      - no memory, branches, exceptions, or CSRs
    """

    def __init__(self, spike_path: str, gcc_path: str):
        self.spike_path = Path(spike_path)
        self.gcc_path = Path(gcc_path)

    def execute(self, request: ISSRequest) -> ISSResult:
        try:
            self._validate_request_scope(request)
            self._validate_tools()

            with tempfile.TemporaryDirectory(prefix="riscv_iss_") as temp_dir:
                work = Path(temp_dir)

                asm_path = work / "program.S"
                linker_path = work / "program.ld"
                elf_path = work / "program.elf"
                log_path = work / "spike.log"
                expected_path = work / "expected.trace"

                self._write_assembly(
                    request,
                    asm_path,
                )
                self._write_linker_script(linker_path)
                self._write_expected_trace(request, expected_path)

                self._build_elf(
                    asm_path,
                    linker_path,
                    elf_path,
                )

                setup_instruction_count = self._count_setup_instructions(
                    elf_path,
                )

                spike_instruction_limit = (
                    SPIKE_BOOT_INSTRUCTION_COUNT
                    + setup_instruction_count
                    + request.execution_limit
                )

                self._run_spike(
                    elf_path,
                    log_path,
                    spike_instruction_limit,
                )

                trace = self._parse_trace(
                    log_path,
                    expected_path,
                    request,
                )

                regs = list(request.initial_int_regs)

                for commit in trace:
                    if commit.rd_valid and commit.rd != 0:
                        regs[commit.rd] = commit.value

                regs[0] = 0

                final_pc = self._derive_final_pc(trace)

                return ISSResult(
                    status=ISSStatus.PASS,
                    final_pc=final_pc,
                    final_int_regs=tuple(regs),
                    executed_count=len(trace),
                    trace=tuple(trace),
                )

        except (OSError, RuntimeError, ValueError) as exc:
            return ISSResult(
                status=ISSStatus.FAIL,
                final_pc=None,
                final_int_regs=None,
                executed_count=0,
                trace=tuple(),
                error=str(exc),
            )

    @staticmethod
    def _validate_request_scope(request: ISSRequest):
        if request.program_word_count <= 0:
            raise ValueError("Spike backend requires a non-empty program")

        for index in range(request.program_word_count):
            instruction = request.program[index]
            opcode = instruction & 0x7F

            # Differential smoke scope covers basic RV32I integer,
            # branch, and load/store instructions.
            if opcode not in (0x03, 0x13, 0x23, 0x33, 0x63):
                raise ValueError(
                    "Spike differential backend supports only "
                    "basic RV32I integer/branch/load-store instructions; "
                    f"program[{index}] "
                    f"has opcode 0x{opcode:02x}"
                )

    def _validate_tools(self):
        if not self.spike_path.is_file():
            raise RuntimeError(
                f"Spike executable not found: {self.spike_path}"
            )

        if not self.gcc_path.is_file():
            raise RuntimeError(
                f"RISC-V GCC executable not found: {self.gcc_path}"
            )

    @staticmethod
    def _write_assembly(request: ISSRequest, path: Path):
        lines = [
            ".section .text.setup",
            ".globl _start",
            "_start:",
        ]

        # Initial-state setup lives outside the architectural program range.
        # The setup code jumps to PROGRAM_BASE before user instructions execute.
        for reg in range(1, 32):
            value = request.initial_int_regs[reg]

            if value != 0:
                lines.append(
                    f"    li x{reg}, 0x{value:08x}"
                )

        lines.extend(
            [
                "    jal x0, __riscv_program_start",
                "",
                ".section .text.program",
                ".globl __riscv_program_start",
                "__riscv_program_start:",
            ]
        )

        for index in range(request.program_word_count):
            lines.append(
                f"    .word 0x{request.program[index]:08x}"
            )

        lines.extend(
            [
                "",
                ".section .data",
                ".globl __riscv_diff_data",
                "__riscv_diff_data:",
                "    .word 0x00000000",
                "",
                "1:",
                "    jal x0, 1b",
                "",
            ]
        )

        path.write_text("\n".join(lines), encoding="utf-8")

    @staticmethod
    def _count_setup_instructions(elf_path: Path) -> int:
        result = subprocess.run(
            [
                "objdump",
                "-h",
                str(elf_path),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        if result.returncode != 0:
            raise RuntimeError(
                "Failed to inspect RISC-V ELF sections: "
                + result.stderr.strip()
            )

        for line in result.stdout.splitlines():
            fields = line.split()

            if len(fields) >= 3 and fields[1] == ".text.setup":
                size = int(fields[2], 16)

                if size % 4 != 0:
                    raise RuntimeError(
                        "RISC-V .text.setup size is not instruction-aligned: "
                        f"{size} bytes"
                    )

                return size // 4

        raise RuntimeError(
            "RISC-V ELF does not contain required .text.setup section"
        )

    @staticmethod
    def _write_linker_script(path: Path):
        path.write_text(
            f"""ENTRY(_start)

SECTIONS
{{
    . = 0x{SETUP_BASE:08x};

    .text.setup : ALIGN(4)
    {{
        *(.text.setup)
    }}

    . = 0x{PROGRAM_BASE:08x};

    .text.program : ALIGN(4)
    {{
        *(.text.program)
    }}

    . = 0x80002000;

    .data : ALIGN(4)
    {{
        *(.data)
    }}
}}
""",
            encoding="utf-8",
        )

    @staticmethod
    def _write_expected_trace(
        request: ISSRequest,
        path: Path,
    ):
        lines = []

        for index in range(request.program_word_count):
            pc = PROGRAM_BASE + index * 4
            instruction = request.program[index]
            lines.append(
                f"0x{pc:08x} 0x{instruction:08x}"
            )

        path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    def _build_elf(
        self,
        asm_path: Path,
        linker_path: Path,
        elf_path: Path,
    ):
        command = [
            str(self.gcc_path),
            "-march=rv32i",
            "-mabi=ilp32",
            "-nostdlib",
            "-nostartfiles",
            "-nodefaultlibs",
            "-Wl,-T",
            str(linker_path),
            "-o",
            str(elf_path),
            str(asm_path),
        ]

        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        if result.returncode != 0:
            raise RuntimeError(
                "RISC-V ELF build failed: "
                + result.stderr.strip()
            )

    def _run_spike(
        self,
        elf_path: Path,
        log_path: Path,
        execution_limit: int,
    ):
        command = [
            str(self.spike_path),
            "--isa=rv32i",
            f"--instructions={execution_limit}",
            "--log-commits",
            f"--log={log_path}",
            str(elf_path),
        ]

        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        if result.returncode != 0:
            raise RuntimeError(
                "Spike failed with status "
                f"{result.returncode}: "
                f"{result.stderr.strip()}"
            )

    @staticmethod
    def _parse_trace(
        log_path: Path,
        expected_path: Path,
        request: ISSRequest,
    ):
        # Reuse the validated Patch 1 parser implementation.
        import spike_commit_parser

        _, raw_trace = spike_commit_parser.parse_log(
            str(log_path),
            PROGRAM_BASE,
            PROGRAM_BASE + request.program_word_count * 4,
            spike_commit_parser.load_expected_trace(
                str(expected_path)
            ),
        )

        trace = []

        for item in raw_trace:
            trace.append(
                ISSCommit(
                    pc=item["pc"],
                    instruction=item["instruction"],
                    rd_valid=item["rd"] is not None,
                    rd=item["rd"],
                    value=item["value"],
                )
            )

        return trace

    @staticmethod
    def _derive_final_pc(trace):
        if not trace:
            raise RuntimeError(
                "cannot derive final PC from empty trace"
            )

        # Patch 2A is explicitly sequential-only.
        return trace[-1].pc + 4
