.section .text.main
.globl main
main:
# ── 1. ALU OPS ────────────────────────────────
    addi x1, x0, 12        # x1 = 12
    addi x2, x0, 3         # x2 = 3
    add  x3, x1, x2        # x3 = 15
    sub  x4, x1, x2        # x4 = 9
    and  x5, x1, x2        # x5 = 0  (1100 & 0011)
    or   x6, x1, x2        # x6 = 15 (1100 | 0011)
    xor  x7, x1, x2        # x7 = 15 (1100 ^ 0011)
    sll  x8, x2, x2        # x8 = 24
    srl  x9, x1, x2        # x9 = 1  (12 >> 3)
    slt  x10, x2, x1       # x10 = 1 (3 < 12)

# ── 2. M-EXTENSION ────────────────────────────
    mul  x11, x1, x2       # x11 = 36
    div  x12, x1, x2       # x12 = 4
    rem  x13, x1, x2       # x13 = 0  (12 % 3)
    addi x14, x0, 7
    rem  x15, x14, x2      # x15 = 1  (7 % 3)

# ── 3. BRANCH NOT TAKEN ───────────────────────
    addi x1, x0, 5
    addi x2, x0, 9
    beq  x1, x2, skip_nt   # NOT taken  (5 ≠ 9)
    addi x3, x0, 0xAA      # ← should execute: x3 = 0xAA
    j    branch_taken_test
skip_nt:
    addi x3, x0, 0xBB      # should NOT execute

# ── 4. BRANCH TAKEN ────────────────────────────
branch_taken_test:
    addi x1, x0, 5
    addi x2, x0, 5
    beq  x1, x2, taken_ok   # taken (5 == 5)
    addi x4, x0, 0xCC       # should NOT execute
    j    load_store_test
taken_ok:
    addi x4, x0, 0xDD       # should execute: x4 = 0xDD

# ── 5. LOAD / STORE ───────────────────────────
load_store_test:
    li   x1, 0x1FF0        # address near stack
    addi x2, x0, 0x42
    sw   x2, 0(x1)         # mem[0x1FF0] = 0x42
    lw   x3, 0(x1)         # x3 = 0x42  (should match x2)

    addi x2, x0, 0xAB
    sb   x2, 4(x1)         # mem[0x7FF4] = 0xAB (byte)
    lb   x3, 4(x1)         # x3 = 0xFFFFFFAB

# ── 6. CSR READ/WRITE ─────────────────────────
    li   x1, 0xDEAD
    csrw mscratch, x1      # mscratch = 0xDEAD
    csrr x2, mscratch      # x2 = 0xDEAD  (should match x1)

# ── 7. LOOP / COUNTER ─────────────────────────
    addi x1, x0, 0         # accumulator
    addi x2, x0, 5         # loop count
loop:
    add  x1, x1, x2        # x1 += x2
    addi x2, x2, -1        # x2--
    bne  x2, x0, loop      # loop until x2 == 0
    # x1 = 5+4+3+2+1 = 15

done:
    j done