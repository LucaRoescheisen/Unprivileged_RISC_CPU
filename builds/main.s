.section .text.main
.globl main
main:
    # Initialize registers
    addi x1, x0, 12       # x1 = 12
    addi x2, x0, 3        # x2 = 3

    # Arithmetic demonstration
    mul  x3, x1, x2       # x3 = 12 * 3 = 36
    div  x4, x1, x2       # x4 = 12 / 3 = 4

    # Branch demo
    addi x6, x0, 0        # Currently not executing
    addi x6, x0, 2        # x6 = 2
    addi x7, x0, 1        # x7 = 1
    beq  x6, x7, skip     # branch not taken
    addi x6, x6, 5        # executes because branch not taken

skip:
    addi x6, x6, 1        # always executes

loop:
    j loop                # infinite loop