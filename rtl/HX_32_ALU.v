
`timescale 1ns / 1ps

module HX32_ALU(
    input  [31:0] A,
    input  [31:0] B,
    input  [4:0]  opcode,
    output reg [63:0] result,
    output reg        zero,
    output reg        carry,
    output reg        overflow,
    output reg        negative,
    output reg        parity_flag
);

    // SECTION 1 : Adder / Subtractor
    
    wire [32:0] add_res = {1'b0, A} + {1'b0, B};
    wire [32:0] sub_res = {1'b0, A} + {1'b0, ~B} + 1'b1;

    // SECTION 2 : Multiplier

    wire [63:0] mul_res = A * B;

    // SECTION 3 : Divider (restoring algorithm)
    reg [31:0] dq, dr;
    reg [63:0] partial;
    integer    idx;

    always @(*) begin
        dq      = 32'b0;
        dr      = 32'b0;
        partial = 64'b0;

        if (B != 32'b0) begin
            for (idx = 31; idx >= 0; idx = idx - 1) begin
                partial = (partial << 1) | {{63{1'b0}}, A[idx]};
                if (partial[31:0] >= B) begin
                    partial[31:0] = partial[31:0] - B;
                    dq[idx]       = 1'b1;
                end
            end
            dr = partial[31:0];
        end
    end

    // SECTION 4 : POPCNT (count set bits)

    reg [5:0] popcnt_r;
    integer   p;

    always @(*) begin
        popcnt_r = 6'b0;
        for (p = 0; p < 32; p = p + 1)
            popcnt_r = popcnt_r + {5'b0, A[p]};
    end

    // SECTION 5 : CLZ (count leading zeros)
 
    reg [5:0] clz_r;
    integer   c;

    always @(*) begin
        clz_r = 6'd32;
        for (c = 31; c >= 0; c = c - 1)
            if (A[c] == 1'b1)
                clz_r = 6'd31 - c[5:0];
    end


    // SECTION 6 : CRC8 (polynomial 0x07)

    reg [7:0] crc8_r;
    reg [7:0] crc_byte;
    integer   b, bt;

    always @(*) begin
        crc8_r = 8'hFF;
        for (bt = 0; bt < 4; bt = bt + 1) begin
            crc_byte = A[bt*8 +: 8];
            crc8_r   = crc8_r ^ crc_byte;
            for (b = 0; b < 8; b = b + 1) begin
                if (crc8_r[7])
                    crc8_r = (crc8_r << 1) ^ 8'h07;
                else
                    crc8_r = (crc8_r << 1);
            end
        end
    end


    // SECTION 7 : Main operation selector

    always @(*) begin

        //  default all outputs 
        result      = 64'b0;
        carry       = 1'b0;
        overflow    = 1'b0;
        parity_flag = 1'b0;

        case (opcode)

            
            // ARITHMETIC
            
            5'b00000: begin                              // ADD
                result   = {32'b0, add_res[31:0]};
                carry    = add_res[32];
                overflow = (~A[31] & ~B[31] &  result[31]) |
                           ( A[31] &  B[31] & ~result[31]);
            end

            5'b00001: begin                              // SUB
                result   = {32'b0, sub_res[31:0]};
                carry    = sub_res[32];
                overflow = ( A[31] & ~B[31] & ~result[31]) |
                           (~A[31] &  B[31] &  result[31]);
            end

            5'b00010: begin                              // MUL
                result = mul_res;
            end

            5'b00011: begin                              // DIV
                if (B == 32'b0) begin
                    result   = 64'hFFFF_FFFF_FFFF_FFFF;
                    overflow = 1'b1;
                end
                else begin
                    result = {dr, dq};
                end
            end

            5'b00100: begin                              // ADI
                result   = {32'b0, add_res[31:0]};
                carry    = add_res[32];
                overflow = (~A[31] & ~B[31] &  result[31]) |
                           ( A[31] &  B[31] & ~result[31]);
            end

            5'b00101: begin                              // SUI
                result   = {32'b0, sub_res[31:0]};
                carry    = sub_res[32];
                overflow = ( A[31] & ~B[31] & ~result[31]) |
                           (~A[31] &  B[31] &  result[31]);
            end

            
            // LOGICAL
            
            5'b00110: result = {32'b0, A & B};          // AND
            5'b00111: result = {32'b0, A | B};          // OR
            5'b01000: result = {32'b0, A ^ B};          // XOR
            5'b01001: result = {32'b0, ~A};              // NOT
            5'b01010: result = {32'b0, ~(A & B)};       // NAND
            5'b01011: result = {32'b0, ~(A | B)};       // NOR

            
            // COMPARE
            
            5'b01100: begin                              // CMP
                result   = {32'b0, sub_res[31:0]};
                carry    = sub_res[32];
                overflow = ( A[31] & ~B[31] & ~sub_res[31]) |
                           (~A[31] &  B[31] &  sub_res[31]);
            end

            5'b01101: begin                              // SLT
                result = ($signed(A) < $signed(B)) ?
                          64'd1 : 64'd0;
            end

            5'b01110: begin                              // SLTU
                result = (A < B) ? 64'd1 : 64'd0;
            end

            
            // SHIFT
            
            5'b01111: result = {32'b0, A << B[4:0]};   // SLL
            5'b10000: result = {32'b0, A >> B[4:0]};   // SRL
            5'b10001: result = {32'b0,
                               $signed(A) >>> B[4:0]};  // SRA

            
            // HX32 NOVEL EXTENSIONS
            
            5'b10010: result = {32'b0,                  // ROL
                               (A << B[4:0]) |
                               (A >> (6'd32 - {1'b0, B[4:0]}))};

            5'b10011: result = {32'b0,                  // ROR
                               (A >> B[4:0]) |
                               (A << (6'd32 - {1'b0, B[4:0]}))};

            5'b10100: result = {58'b0, popcnt_r};       // POPCNT

            5'b10101: result = {58'b0, clz_r};          // CLZ

            5'b10110: begin                              // PARITY
                result      = {63'b0, ^A};
                parity_flag = ^A;
            end

            5'b10111: result = {56'b0, crc8_r};         // CRC8

            default:  result = 64'b0;

        endcase

        //---------------------------------------
        // GLOBAL FLAGS (after result is settled)
        //---------------------------------------
        negative = result[31];
        zero     = (opcode == 5'b00010) ?
                   (result == 64'b0) :
                   (result[31:0] == 32'b0);

    end

endmodule