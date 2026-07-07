# Why I Built This

This project started while I was revisiting Computer Architecture and Computer Arithmetic concepts beyond regular coursework. While studying the lecture notes of Dr. Smruti R. Sarangi (IIT Delhi).
This project help me learn how to build a Custom ISA , Which kind of instructions are neccessary and which are not.


# HX32 CPU

A custom 32-bit single-cycle RISC processor written entirely in Verilog HDL as an exploration into computer architecture, instruction set design and RTL implementation.

HX32 started as a standalone ALU project and gradually evolved into a complete processor featuring a custom ISA, stack support, subroutine handling and an assembler for easier program development and ISA verification.


---

# Processor Overview

| Feature | Description |
|----------|------------|
| Architecture | Single Cycle Harvard Architecture |
| ISA Width | 32-bit |
| Register Width | 32-bit |
| Register Count | 32 General Purpose Registers |
| Register x0 | Hardwired to Zero |
| Program Counter | Dedicated 32-bit PC |
| Stack Pointer | Dedicated 32-bit SP |
| Instruction Memory | Separate from Data Memory |
| Data Memory | Byte Addressable |
| Execution Model | Single Cycle |
| ISA Type | Custom RISC ISA |
| Stack Support | Yes |
| Function Calls | CALL / RET |
| External I/O | IN / OUT Instructions |
| Assembler Support | Yes |

---

# Architectural Overview

HX32 follows a **Harvard Architecture**, meaning that instruction memory and data memory are physically separated.

This allows instruction fetch and data access to occur independently and greatly simplifies the control logic for a single-cycle processor.

The processor consists of the following major blocks:

- Program Counter (PC)
- Instruction Memory (IMEM)
- Instruction Decoder
- Register File
- Arithmetic Logic Unit (ALU)
- Data Memory (DMEM)
- Stack Pointer (SP)
- Control Unit
- Input/Output Interface

---

# Flow of Architecture 
```
                +--------------------+
                |    Assembly Code   |
                +--------------------+
                          |
                          v
                +--------------------+
                |     Assembler      |
                +--------------------+
                          |
                          v
                +--------------------+
                | Program mem file   |
                +---------+----------+
                          |
                          v
                +--------------------+
                | Instruction Memory |
                +---------+----------+
                          |
                          v
                +--------------------+
                | Instruction Decode |
                +---------+----------+
                          |
        +----------------+----------------+
        |                                 |
        v                                 v
+---------------+               +----------------+
| Register File |-------------->|      ALU       |
+-------+-------+               +--------+-------+
        |                                       |
        |           Simply execution            v                               
        |                       +----------------+
        +---------------------->|  Data Memory   |
                                +----------------+

                       +----------------+
                       | Stack Pointer  | Stack Involvement
                       +----------------+

```

---

# Register File

HX32 contains:

- 32 General Purpose Registers
- 32-bit register width
- Register `x0` permanently tied to zero

```
x0  -> constant zero register
x1  -> general purpose
x2  -> general purpose
...
x31 -> general purpose
```

---

# Program Counter

The Program Counter stores the address of the instruction currently being executed.

Normally:

```text
PC = PC + 4
```

However it may be modified by:

- Branch Instructions
- Jumps
- CALL
- RET

---

# Stack Pointer

HX32 contains a dedicated stack pointer register.

The stack:

- grows downward in memory
- uses 32-bit words
- supports nested subroutine calls
- supports local storage

Supported stack instructions:

```text
PUSH
POP
CALL
RET
```

---

# Instruction Format

## R-Type

Used for register-register ALU operations.

```text
31      26 25    21 20    16 15    11 10     6 5      0
+---------+--------+--------+--------+--------+--------+
| OPCODE  |  RD    |  RS1   |  RS2   | ALU OP | UNUSED |
+---------+--------+--------+--------+--------+--------+
```

---

## I-Type

Used for immediate instructions.

```text
31      26 25    21 20    16 15                       0
+---------+--------+--------+-------------------------+
| OPCODE  |  RD    |  RS1   |         IMM16           |
+---------+--------+--------+-------------------------+
```
## J-Type
```text
Used for Branch or Jump Type instruction where there's a need to change the PC by the Branch Target

31            26 25      21 20      16 15                     0
+---------------+----------+----------+-------------------------+
|   OPCODE      |    RD    |   RS1    |        OFFSET           |       // other fields can be zero depending on the instruction
+---------------+----------+----------+-------------------------+
```

---

# Instruction Set

## Arithmetic

```text
ADD
SUB
MUL
DIV
MOD

ADDI
SUBI
MULI
DIVI
MODI
```

---

## Logical

```text
AND
OR
XOR
NOT
NAND
NOR

ANDI
ORI
XORI
```

---

## Comparison

```text
CMP
SLT
SLTU

SLTI
SLTIU
```

---

## Shift and Rotate

```text
SLL
SRL
SRA

SLLI
SRLI
SRAI

ROL
ROR
```

---

## Bit Manipulation

```text
POPCNT
CLZ
CTZ
PARITY
CRC8
NEG
ABS
MIN
MAX

MINI
MAXI
```

---

## Memory Operations

```text
LOAD
STORE

// these are I Type instruction typically represented as LOAD R2 , R3[21] ; 
// here we can see that we have the source(R3) and the destination(R2) regiters and the offset (21)
// which means that load the data stored at the memory location R3 + 21 into R2
```

---

## Stack Operations

```text
PUSH
POP
CALL
RET
```

---

## Branch Instructions

```text
BEQ
BNE
BLT
BGE
BLTU
BGEU
BZ
BNZ
```

---

## Control Flow

```text
JAL
JALR
```

---

## Data Movement

```text
MOV
MOVI
LUI
AUIPC
```

---

## Input / Output

```text
IN
OUT
```

---

## System Instructions

```text
NOP
HALT
```

---

# Memory Organization

## Instruction Memory

- Stores executable instructions
- Word Addressable
- Separate from data memory

## Data Memory

- Stores program data
- Byte Addressable
- Supports stack operations

---

# Assembler

HX32 includes a custom assembler written in Python.

The assembler converts:

```asm

IN x2              # Read input into x2
MOVI x1, 10      # Load immediate 10 into x1



ADD x3, x1, x2   # x3 = x1 + x2
MUL x4, x1, x2   # x4 = x1 * x2
OUT x3            # Output the result of addition


PUSH x4          # Push x4 onto stack
POP x5           # Pop into x5


Loop:
SUBI x1, x1, 1   # Decrement x1
BNZ x1, Loop     # Branch to Loop if x1 != 0
OUT x5            # Output the value popped from stack
HALT             # Stop execution
```

into machine code or .mem file suitable for simulation in Vivado.

This significantly simplifies:

- ISA verification
- Program development
- Debugging
- Testbench creation

---

# Simulation

Simulation was performed using:

- Vivado Simulator
- Verilog 

Verification includes:

- Arithmetic operations
- Immediate operations
- Memory access
- Stack operations
- Function calls
- Branches
- Input/Output instructions

---

# Future Work

Planned improvements include:

- Pipelined architecture
- Hazard detection
- Data forwarding
- Branch prediction
- Interrupt handling
- Memory mapped I/O
- Peripheral integration
- Cache support
- Multi-cycle multiply/divide units

---



# Author

Harsh Saita  
Electronics and Communication Engineering  
IIT Bhilai