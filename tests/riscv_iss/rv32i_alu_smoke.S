.section .text
.globl _start

_start:
    addi x1,  x0, 5
    addi x2,  x0, 7
    add  x3,  x1, x2
    sub  x4,  x3, x1
    and  x5,  x3, x2
    or   x6,  x1, x2
    xor  x7,  x1, x2
    sll  x8,  x1, x2
    sra  x9,  x4, x1
    slt  x10, x4, x3

1:
    jal  x0, 1b
