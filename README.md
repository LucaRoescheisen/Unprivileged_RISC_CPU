# RV32IM 32-bit RISC-V CPU

---

## Overview

This project implements a 32-bit RV32IM CPU supporting the full base integer instruction set plus multiplication and division instructions.  
It features a simple 5-stage pipeline with hazard detection, forwarding and stalling.  
The CPU is designed to be synthesizable on FPGA and fully verifiable using assembly test programs and simulation testbenches.

---

## Features

- Supports RV32I base integer instructions and RV32M multiplication/division instructions
- 5-stage pipeline: IF, ID, EX, MEM, WB
- Hazard detection, data forwarding, and stalling logic
- Branch handling with pipeline flush on taken branches and jumps
- Machine-mode CSRs implemented: `mstatus`, `mtvec`, `mepc`, `mcause`, `mscratch`
- Bootloader workflow: programs compiled, linked, and uploaded via `.memh` files
- Verified with assembly test programs and simulation testbenches

---

## Design Overview

**Pipeline stages:**

- **IF:** Instruction fetch  
- **ID:** Instruction decode and register read  
- **EX:** ALU operations and divider  
- **MEM:** Memory access (load/store)  
- **WB:** Writeback to register file  

**Data forwarding:**

- Implements forwarding from EX/MEM and MEM/WB stages
- Reduces stalls caused by read-after-write hazards

**Control logic:**

- Flushes pipeline on taken branches or jumps
- Supports CSR updates and trap handling

---

## Verification

- Functional correctness verified using assembly test programs
- Simulated with Verilog testbenches
- PC behavior checked for loops, jumps, and pipeline synchronization

