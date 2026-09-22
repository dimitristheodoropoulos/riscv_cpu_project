#!/usr/bin/env python3

from iss_contract import (
    INTEGER_REGISTER_COUNT,
    UINT32_MASK,
    ISSBackend,
    ISSCommit,
    ISSRequest,
    ISSResult,
    ISSStatus,
)


class RV32IEmulatorBackend(ISSBackend):
    """Small independent RV32I architectural reference model.

    E2 scope:
      - E1 ALU instructions
      - BEQ
      - LW
      - SW
      - architectural PC-relative branch execution
      - sparse aligned 32-bit word memory
    """

    def execute(self, request: ISSRequest) -> ISSResult:
        try:
            self._validate_request_scope(request)

            regs = list(request.initial_int_regs)
            regs[0] = 0

            memory = {}
            pc = 0
            trace = []

            while len(trace) < request.execution_limit:
                if pc % 4 != 0:
                    raise ValueError(
                        f"PC is not 4-byte aligned: 0x{pc:08x}"
                    )

                index = pc // 4

                if index >= request.program_word_count:
                    break

                instruction = request.program[index]

                commit, next_pc = self._execute_instruction(
                    instruction=instruction,
                    pc=pc,
                    regs=regs,
                    memory=memory,
                )

                trace.append(commit)
                regs[0] = 0
                pc = next_pc

            return ISSResult(
                status=ISSStatus.PASS,
                final_pc=pc,
                final_int_regs=tuple(regs),
                executed_count=len(trace),
                trace=tuple(trace),
            )

        except (ValueError, IndexError) as exc:
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
            raise ValueError(
                "RV32I emulator requires a non-empty program"
            )

        for index in range(request.program_word_count):
            instruction = request.program[index]
            opcode = instruction & 0x7F
            funct3 = (instruction >> 12) & 0x7
            funct7 = (instruction >> 25) & 0x7F

            if opcode == 0x13:
                if funct3 != 0x0:
                    raise ValueError(
                        "RV32I emulator E2 supports only ADDI "
                        f"for OP-IMM; program[{index}] has "
                        f"funct3=0x{funct3:x}"
                    )

            elif opcode == 0x33:
                supported = {
                    (0x0, 0x00),
                    (0x0, 0x20),
                    (0x7, 0x00),
                    (0x6, 0x00),
                    (0x4, 0x00),
                    (0x1, 0x00),
                    (0x5, 0x20),
                    (0x2, 0x00),
                }

                if (funct3, funct7) not in supported:
                    raise ValueError(
                        "RV32I emulator E2 does not support "
                        f"program[{index}] encoding "
                        f"funct7=0x{funct7:02x}, "
                        f"funct3=0x{funct3:x}"
                    )

            elif opcode == 0x63:
                if funct3 != 0x0:
                    raise ValueError(
                        "RV32I emulator E2 supports only BEQ "
                        f"for BRANCH; program[{index}] has "
                        f"funct3=0x{funct3:x}"
                    )

            elif opcode == 0x03:
                if funct3 != 0x2:
                    raise ValueError(
                        "RV32I emulator E2 supports only LW "
                        f"for LOAD; program[{index}] has "
                        f"funct3=0x{funct3:x}"
                    )

            elif opcode == 0x23:
                if funct3 != 0x2:
                    raise ValueError(
                        "RV32I emulator E2 supports only SW "
                        f"for STORE; program[{index}] has "
                        f"funct3=0x{funct3:x}"
                    )

            else:
                raise ValueError(
                    "RV32I emulator E2 does not support "
                    f"program[{index}] opcode 0x{opcode:02x}"
                )

    @classmethod
    def _execute_instruction(cls, instruction, pc, regs, memory):
        opcode = instruction & 0x7F
        rd = (instruction >> 7) & 0x1F
        funct3 = (instruction >> 12) & 0x7
        rs1 = (instruction >> 15) & 0x1F
        rs2 = (instruction >> 20) & 0x1F
        funct7 = (instruction >> 25) & 0x7F

        next_pc = pc + 4

        if opcode == 0x13:
            imm = cls._sign_extend(instruction >> 20, 12)
            result = cls._u32(regs[rs1] + imm)

            if rd != 0:
                regs[rd] = result

            return (
                ISSCommit(
                    pc=pc,
                    instruction=instruction,
                    rd_valid=True,
                    rd=rd,
                    value=0 if rd == 0 else result,
                ),
                next_pc,
            )

        if opcode == 0x33:
            left = regs[rs1]
            right = regs[rs2]
            shift = right & 0x1F

            if funct3 == 0x0 and funct7 == 0x00:
                result = left + right
            elif funct3 == 0x0 and funct7 == 0x20:
                result = left - right
            elif funct3 == 0x7 and funct7 == 0x00:
                result = left & right
            elif funct3 == 0x6 and funct7 == 0x00:
                result = left | right
            elif funct3 == 0x4 and funct7 == 0x00:
                result = left ^ right
            elif funct3 == 0x1 and funct7 == 0x00:
                result = left << shift
            elif funct3 == 0x5 and funct7 == 0x20:
                result = cls._signed32(left) >> shift
            elif funct3 == 0x2 and funct7 == 0x00:
                result = int(
                    cls._signed32(left) < cls._signed32(right)
                )
            else:
                raise ValueError(
                    f"Unsupported R-type instruction: "
                    f"0x{instruction:08x}"
                )

            result = cls._u32(result)

            if rd != 0:
                regs[rd] = result

            return (
                ISSCommit(
                    pc=pc,
                    instruction=instruction,
                    rd_valid=True,
                    rd=rd,
                    value=0 if rd == 0 else result,
                ),
                next_pc,
            )

        if opcode == 0x63 and funct3 == 0x0:
            branch_imm = (
                (((instruction >> 31) & 0x1) << 12)
                | (((instruction >> 7) & 0x1) << 11)
                | (((instruction >> 25) & 0x3F) << 5)
                | (((instruction >> 8) & 0xF) << 1)
            )
            branch_imm = cls._sign_extend(branch_imm, 13)

            if regs[rs1] == regs[rs2]:
                next_pc = cls._u32(pc + branch_imm)

            return (
                ISSCommit(
                    pc=pc,
                    instruction=instruction,
                    rd_valid=False,
                    rd=None,
                    value=None,
                ),
                next_pc,
            )

        if opcode == 0x03 and funct3 == 0x2:
            imm = cls._sign_extend(instruction >> 20, 12)
            address = cls._u32(regs[rs1] + imm)
            cls._validate_word_address(address)

            value = memory.get(address, 0)
            value = cls._u32(value)

            if rd != 0:
                regs[rd] = value

            return (
                ISSCommit(
                    pc=pc,
                    instruction=instruction,
                    rd_valid=True,
                    rd=rd,
                    value=0 if rd == 0 else value,
                ),
                next_pc,
            )

        if opcode == 0x23 and funct3 == 0x2:
            imm = (
                (((instruction >> 25) & 0x7F) << 5)
                | ((instruction >> 7) & 0x1F)
            )
            imm = cls._sign_extend(imm, 12)

            address = cls._u32(regs[rs1] + imm)
            cls._validate_word_address(address)

            memory[address] = cls._u32(regs[rs2])

            return (
                ISSCommit(
                    pc=pc,
                    instruction=instruction,
                    rd_valid=False,
                    rd=None,
                    value=None,
                ),
                next_pc,
            )

        raise ValueError(
            f"Unsupported instruction: 0x{instruction:08x}"
        )

    @staticmethod
    def _validate_word_address(address):
        if address & 0x3:
            raise ValueError(
                f"misaligned 32-bit memory access at "
                f"0x{address:08x}"
            )

    @staticmethod
    def _u32(value):
        return value & UINT32_MASK

    @staticmethod
    def _signed32(value):
        value &= UINT32_MASK

        if value & 0x80000000:
            return value - 0x100000000

        return value

    @staticmethod
    def _sign_extend(value, width):
        sign_bit = 1 << (width - 1)

        if value & sign_bit:
            return value - (1 << width)

        return value
