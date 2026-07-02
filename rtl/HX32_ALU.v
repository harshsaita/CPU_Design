`timescale 1ns/1ps

module HX32_ALU(
    input  [31:0] A,
    input  [31:0] B,
    input  [4:0]  opcode,
    output reg [63:0] result,
    output reg zero,
    output reg carry,
    output reg overflow,
    output reg negative,
    output reg parity_flag
);

localparam
    ALU_ADD    = 5'd0,
    ALU_SUB    = 5'd1,
    ALU_MUL    = 5'd2,
    ALU_DIV    = 5'd3,
    ALU_MOD    = 5'd4,

    ALU_AND    = 5'd5,
    ALU_OR     = 5'd6,
    ALU_XOR    = 5'd7,
    ALU_NOT    = 5'd8,
    ALU_NAND   = 5'd9,
    ALU_NOR    = 5'd10,

    ALU_CMP    = 5'd11,
    ALU_SLT    = 5'd12,
    ALU_SLTU   = 5'd13,

    ALU_SLL    = 5'd14,
    ALU_SRL    = 5'd15,
    ALU_SRA    = 5'd16,
    ALU_ROL    = 5'd17,
    ALU_ROR    = 5'd18,

    ALU_POPCNT = 5'd19,
    ALU_CLZ    = 5'd20,
    ALU_CTZ    = 5'd21,
    ALU_PARITY = 5'd22,
    ALU_CRC8   = 5'd23,

    ALU_NEG    = 5'd24,
    ALU_ABS    = 5'd25,
    ALU_MIN    = 5'd26,
    ALU_MAX    = 5'd27;

wire [32:0] add_res = {1'b0,A}+{1'b0,B};
wire [32:0] sub_res = {1'b0,A}+{1'b0,~B}+33'd1;
wire [63:0] mul_res = A*B;
wire [31:0] mod_res = (B==0)?32'hFFFFFFFF:(A%B);
wire [4:0] shamt = B[4:0];

reg [31:0] dq,dr;
reg [63:0] partial;
integer i;

always @(*) begin
    dq=0; dr=0; partial=0;
    if(B!=0) begin
        for(i=31;i>=0;i=i-1) begin
            partial=(partial<<1)|A[i];
            if(partial[31:0]>=B) begin
                partial[31:0]=partial[31:0]-B;
                dq[i]=1'b1;
            end
        end
        dr=partial[31:0];
    end
end

reg [5:0] popcnt_r,clz_r,ctz_r;
integer j;

always @(*) begin
    popcnt_r=0;
    for(j=0;j<32;j=j+1) popcnt_r=popcnt_r+A[j];
end

always @(*) begin
    clz_r=32;
    for(j=31;j>=0;j=j-1)
        if(A[j] && clz_r==32) clz_r=31-j;
end

always @(*) begin
    ctz_r=32;
    for(j=0;j<32;j=j+1)
        if(A[j] && ctz_r==32) ctz_r=j;
end

reg [7:0] crc8_r,crc_byte;
integer b,bt;
always @(*) begin
    crc8_r=8'hFF;
    for(bt=0;bt<4;bt=bt+1) begin
        crc_byte=A[bt*8 +:8];
        crc8_r=crc8_r^crc_byte;
        for(b=0;b<8;b=b+1)
            crc8_r = crc8_r[7] ? ((crc8_r<<1)^8'h07):(crc8_r<<1);
    end
end

always @(*) begin
    result=0; carry=0; overflow=0; parity_flag=0;

    case(opcode)
        ALU_ADD: begin result={32'b0,add_res[31:0]}; carry=add_res[32]; end
        ALU_SUB: begin result={32'b0,sub_res[31:0]}; carry=sub_res[32]; end
        ALU_MUL: result=mul_res;
        ALU_DIV: result=(B==0)?64'hFFFF_FFFF_FFFF_FFFF:{dr,dq};
        ALU_MOD: result={32'b0,mod_res};

        ALU_AND: result={32'b0,A&B};
        ALU_OR : result={32'b0,A|B};
        ALU_XOR: result={32'b0,A^B};
        ALU_NOT: result={32'b0,~A};
        ALU_NAND:result={32'b0,~(A&B)};
        ALU_NOR: result={32'b0,~(A|B)};

        ALU_CMP : begin result={32'b0,sub_res[31:0]}; carry=sub_res[32]; end
        ALU_SLT : result=($signed(A)<$signed(B))?64'd1:64'd0;
        ALU_SLTU: result=(A<B)?64'd1:64'd0;

        ALU_SLL: result={32'b0,A<<shamt};
        ALU_SRL: result={32'b0,A>>shamt};
        ALU_SRA: result={32'b0,$signed(A)>>>shamt};
        ALU_ROL: result={32'b0,(A<<shamt)|(A>>((32-shamt)&31))};
        ALU_ROR: result={32'b0,(A>>shamt)|(A<<((32-shamt)&31))};

        ALU_POPCNT: result={58'b0,popcnt_r};
        ALU_CLZ:    result={58'b0,clz_r};
        ALU_CTZ:    result={58'b0,ctz_r};
        ALU_PARITY: begin result={63'b0,^A}; parity_flag=^A; end
        ALU_CRC8:   result={56'b0,crc8_r};

        ALU_NEG: result={32'b0,-A};
        ALU_ABS: result={32'b0,A[31]?-A:A};
        ALU_MIN: result={32'b0,($signed(A)<$signed(B))?A:B};
        ALU_MAX: result={32'b0,($signed(A)>$signed(B))?A:B};

        default: result=0;
    endcase

    negative=result[31];
    zero=(result==0);

    if(opcode==ALU_ADD)
        overflow=(~A[31]&~B[31]&result[31])|(A[31]&B[31]&~result[31]);

    if(opcode==ALU_SUB || opcode==ALU_CMP)
        overflow=(A[31]&~B[31]&~result[31])|(~A[31]&B[31]&result[31]);
end

endmodule
