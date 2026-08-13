
with open('programs/program.hex', 'r') as f, open('programs/fixed_ram.hex', 'w') as out:
    for line in f:
        if line.startswith('@'):
            # Convert hex address to int, divide by 4, convert back to hex
            byte_addr = int(line[1:], 16)
            word_addr = byte_addr // 4
            out.write(f"@{word_addr:08x}\n")
        else:
            out.write(line)