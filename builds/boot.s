
.equ TRAP_HANDLER, 0x100
.equ STACK_TOP, 0x7FFC

.section .text.boot
.globl _start
_start:

  #Setup Trap Vector
  li   t0,   TRAP_HANDLER      #Position of traphandler
  csrw mtvec, t0               #Load position into mtvec

  #Setup Stack Pointer
  li   sp,  STACK_TOP


  #Enable Interrupts
  li   t1,  0x888
  csrs mie, t1                  #Turns on interrupts in MIE

  #Enable Global Interrupts
  li   t2, 0x8
  csrs mstatus, t2

  #Clear mscratch
  li   t0, 0x0
  csrw mscratch, t0

  #Jump to main
  j main


hang:
  j hang