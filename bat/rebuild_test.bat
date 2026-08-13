@echo off
riscv64-unknown-elf-as -march=rv32im -mabi=ilp32 -o programs/boot.o builds/boot.s
riscv64-unknown-elf-as -march=rv32im -mabi=ilp32 -o programs/main.o builds/main.s
riscv64-unknown-elf-as -march=rv32im -mabi=ilp32 -o programs/trap_handler.o builds/trap_handler.s
riscv64-unknown-elf-ld -m elf32lriscv -e main -T builds/linker.ld programs/main.o programs/trap_handler.o -o programs/program.elf
riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 --reverse-bytes=4 -R .riscv.attributes -R .comment programs/program.elf programs/program.hex
python D:/u_risc/programs/addr_fix.py