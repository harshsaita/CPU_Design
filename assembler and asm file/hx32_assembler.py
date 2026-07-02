import sys
import re

# Opcode Mapping (from your Verilog localparam)
OPCODES = {
    'RTYPE': 0x00, 'ADDI': 0x01, 'SUBI': 0x02, 'MULI': 0x03, 'DIVI': 0x04,
    'MODI': 0x05, 'ANDI': 0x06, 'ORI': 0x07, 'XORI': 0x08, 'SLTI': 0x09,
    'SLTIU': 0x0A, 'SLLI': 0x0B, 'SRLI': 0x0C, 'SRAI': 0x0D, 'MINI': 0x0E,
    'MAXI': 0x0F, 'LOAD': 0x10, 'STORE': 0x11, 'BEQ': 0x12, 'BNE': 0x13,
    'BLT': 0x14, 'BGE': 0x15, 'BLTU': 0x16, 'BGEU': 0x17, 'BZ': 0x18,
    'BNZ': 0x19, 'JAL': 0x1A, 'JALR': 0x1B, 'PUSH': 0x1C, 'POP': 0x1D,
    'CALL': 0x1E, 'RET': 0x1F, 'MOV': 0x20, 'MOVI': 0x21, 'LUI': 0x22,
    'AUIPC': 0x23, 'IN': 0x24, 'OUT': 0x25, 'NOP': 0x3E, 'HALT': 0x3F
}

# ALU R-Type Opcodes mapping
ALU_OPS = {
    'ADD': 0, 'SUB': 1, 'MUL': 2, 'DIV': 3, 'MOD': 4,
    'AND': 5, 'OR': 6, 'XOR': 7, 'NOT': 8, 'NAND': 9, 'NOR': 10,
    'CMP': 11, 'SLT': 12, 'SLTU': 13, 'SLL': 14, 'SRL': 15,
    'SRA': 16, 'ROL': 17, 'ROR': 18, 'POPCNT': 19, 'CLZ': 20,
    'CTZ': 21, 'PARITY': 22, 'CRC8': 23, 'NEG': 24, 'ABS': 25,
    'MIN': 26, 'MAX': 27
}

def parse_register(reg_str):
    if reg_str.startswith('x') or reg_str.startswith('r'):
        return int(reg_str[1:])
    return 0

def assemble(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    # Pass 1: Extract labels and clean code
    labels = {}
    instructions = []
    pc = 0

    for line_num, line in enumerate(lines):
        line = line.split(';')[0].split('#')[0].strip() # Remove comments
        if not line:
            continue
            
        if ':' in line:
            label, rest = line.split(':', 1)
            labels[label.strip()] = pc
            line = rest.strip()
            
        if line:
            instructions.append((pc, line, line_num + 1))
            pc += 4 # PC increments by 4 bytes per instruction

    # Pass 2: Assemble instructions
    machine_code = []
    
    for current_pc, instr, line_num in instructions:
        parts = re.split(r'[\s,]+', instr)
        op = parts[0].upper()
        
        try:
            encoded_instr = 0
            
            # --- R-TYPE INSTRUCTIONS ---
            if op in ALU_OPS:
                opcode = OPCODES['RTYPE']
                alu_op = ALU_OPS[op]
                rd = parse_register(parts[1]) if len(parts) > 1 else 0
                rs1 = parse_register(parts[2]) if len(parts) > 2 else 0
                rs2 = parse_register(parts[3]) if len(parts) > 3 else 0
                encoded_instr = (opcode << 26) | (rd << 21) | (rs1 << 16) | (rs2 << 11) | (alu_op << 6)
            
            # --- MISC ZERO-OPERAND ---
            elif op in ['NOP', 'HALT', 'RET']:
                opcode = OPCODES[op]
                encoded_instr = (opcode << 26)
                
            # --- STACK ONE-OPERAND ---
            elif op in ['PUSH', 'POP', 'IN', 'OUT']:
                opcode = OPCODES[op]
                rd = parse_register(parts[1])
                encoded_instr = (opcode << 26) | (rd << 21)
                
            # --- EVERYTHING ELSE ---
            elif op in OPCODES:
                opcode = OPCODES[op]
                rd = 0; rs1 = 0; imm16 = 0
                
                if op in ['ADDI', 'SUBI', 'MULI', 'DIVI', 'MODI', 'ANDI', 'ORI', 'XORI', 
                          'SLTI', 'SLTIU', 'SLLI', 'SRLI', 'SRAI', 'MINI', 'MAXI']:
                    rd = parse_register(parts[1])
                    rs1 = parse_register(parts[2])
                    imm16 = int(parts[3], 0)
                    
                elif op in ['LOAD', 'STORE']:
                    rd = parse_register(parts[1])
                    rs1 = parse_register(parts[2])
                    imm16 = int(parts[3], 0)
                    
                elif op in ['BEQ', 'BNE', 'BLT', 'BGE', 'BLTU', 'BGEU']:
                    rd = parse_register(parts[1])
                    rs1 = parse_register(parts[2])
                    target = parts[3]
                    imm16 = labels[target] - current_pc if target in labels else int(target, 0)
                        
                elif op in ['BZ', 'BNZ']:
                    rd = parse_register(parts[1])
                    target = parts[2]
                    imm16 = labels[target] - current_pc if target in labels else int(target, 0)
                        
                elif op in ['JAL', 'CALL']:
                    target = parts[1] if op == 'CALL' else parts[2]
                    if op == 'JAL': rd = parse_register(parts[1])
                    imm16 = labels[target] - current_pc if target in labels else int(target, 0)

                elif op == 'MOVI':
                    rd = parse_register(parts[1])
                    imm16 = int(parts[2], 0)

                elif op == 'MOV':
                    rd = parse_register(parts[1])
                    rs1 = parse_register(parts[2])

                if imm16 < 0:
                    imm16 = (1 << 16) + imm16
                imm16 = imm16 & 0xFFFF 
                
                encoded_instr = (opcode << 26) | (rd << 21) | (rs1 << 16) | imm16
                
            else:
                print(f"Error: Unknown instruction '{op}' on line {line_num}")
                sys.exit(1)
                
            machine_code.append(encoded_instr)
            
        except Exception as e:
            print(f"Syntax error on line {line_num}: {instr} -> {e}")
            sys.exit(1)

    # ---------------------------------------------------------
    # NEW: Write Vivado compatible .mem file
    # ---------------------------------------------------------
    with open(output_file, 'w') as f:
        f.write("// HX32 Vivado Memory Initialization File\n")
        f.write("// Format: @<word_address> <32-bit hex_data>\n")
        
        for i, code in enumerate(machine_code):
            # i represents the word address. 
            # In your CPU, pc[9:2] accesses this exact index.
            f.write(f"@{i:04X} {code:08X}\n")
            
    print(f"Assembly complete! {len(machine_code)} instructions written to {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python assembler.py <input.asm> <output.mem>")
    else:
        assemble(sys.argv[1], sys.argv[2])