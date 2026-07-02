
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