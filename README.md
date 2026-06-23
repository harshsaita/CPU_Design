# Why I Built This

This project started while I was revisiting Computer Architecture and Computer Arithmetic concepts beyond regular coursework. While studying the lecture notes of Dr. Smruti R. Sarangi (IIT Delhi), I became interested in understanding not only how arithmetic operations work mathematically but also how they are realized at the hardware level.

I explored the algorithms behind addition, subtraction, multiplication, division, and logical operations and wanted to recreate them through RTL design instead of treating them as abstract concepts.

Rather than directly implementing a standard RV32I processor, I decided to begin with the arithmetic core and build something that extends beyond the conventional instruction set.

This ALU supports the fundamental operations inspired by the RV32I ISA and additionally includes a few custom instructions influenced by concepts I encountered in Microcontrollers and Embedded Systems coursework.

Some of the additional operations include:

* ROR (Rotate Right)
* ROL (Rotate Left)
* CRC-related operations for communication-oriented computation

These instructions are commonly associated with low-level embedded and communication workflows and have historically appeared in processor-oriented systems and instruction extensions.

The goal of this project was not only to reproduce existing architecture but to experiment with extending it and understanding the design tradeoffs at the RTL level.

This repository currently contains:

* RTL implementation
* Testbench and simulation environment
* Functional verification
* Design documentation

Future work:
This project will continue evolving beyond an ALU implementation. Additional modules and files will be added to the `rtl/` and `sim/` directories with the long-term objective of developing a more complete custom CPU architecture.
