`timescale 1ns / 1ps

// ============================================================
// HX32 CPU
// 32-bit Single Cycle Harvard Architecture Processor
// ============================================================

module HX32_CPU #(
    parameter IMEM_WORDS = 256,
    parameter DMEM_BYTES = 1024,
    parameter RESET_PC   = 32'h00000000
)(
    input wire clk,
    input wire rst_n,

    // external input port
    input wire [31:0] in_port,

    // output port
    output reg [31:0] out_port,
    output reg out_valid,

    // debug signals
    output wire [31:0] pc_out,
    output wire [31:0] sp_out,
    output wire halted,

    input wire [4:0] dbg_reg_addr,
    output wire [31:0] dbg_reg_data
);

// ------------------------------------------------------------
// Opcode Map
// ------------------------------------------------------------
localparam [5:0]
    OP_RTYPE = 6'h00,

    // arithmetic immediate
    OP_ADDI  = 6'h01,
    OP_SUBI  = 6'h02,
    OP_MULI  = 6'h03,
    OP_DIVI  = 6'h04,
    OP_MODI  = 6'h05,

    // logic immediate
    OP_ANDI  = 6'h06,
    OP_ORI   = 6'h07,
    OP_XORI  = 6'h08,

    // compare immediate
    OP_SLTI  = 6'h09,
    OP_SLTIU = 6'h0A,

    // shift immediate
    OP_SLLI  = 6'h0B,
    OP_SRLI  = 6'h0C,
    OP_SRAI  = 6'h0D,

    // min/max immediate
    OP_MINI  = 6'h0E,
    OP_MAXI  = 6'h0F,

    // memory
    OP_LOAD  = 6'h10,
    OP_STORE = 6'h11,

    // branches
    OP_BEQ   = 6'h12,
    OP_BNE   = 6'h13,
    OP_BLT   = 6'h14,
    OP_BGE   = 6'h15,
    OP_BLTU  = 6'h16,
    OP_BGEU  = 6'h17,
    OP_BZ    = 6'h18,
    OP_BNZ   = 6'h19,

    // jumps
    OP_JAL   = 6'h1A,
    OP_JALR  = 6'h1B,

    // stack
    OP_PUSH  = 6'h1C,
    OP_POP   = 6'h1D,
    OP_CALL  = 6'h1E,
    OP_RET   = 6'h1F,

    // misc
    OP_MOV   = 6'h20,
    OP_MOVI  = 6'h21,
    OP_LUI   = 6'h22,
    OP_AUIPC = 6'h23,
    OP_IN    = 6'h24,
    OP_OUT   = 6'h25,

    OP_NOP   = 6'h3E,
    OP_HALT  = 6'h3F;

// ------------------------------------------------------------
// Core State
// ------------------------------------------------------------
reg [31:0] pc;
reg [31:0] sp;

reg [31:0] regfile [0:31];

reg [31:0] imem [0:IMEM_WORDS-1];
reg [7:0]  dmem [0:DMEM_BYTES-1];

reg halted_r;

// ------------------------------------------------------------
// Debug Outputs
// ------------------------------------------------------------
assign pc_out = pc;
assign sp_out = sp;
assign halted = halted_r;

assign dbg_reg_data =
    (dbg_reg_addr == 5'd0)
    ? 32'b0
    : regfile[dbg_reg_addr];

// ------------------------------------------------------------
// Instruction Fetch
// ------------------------------------------------------------
wire [31:0] instr;

assign instr = imem[pc[9:2]];

// ------------------------------------------------------------
// Instruction Decode
// ------------------------------------------------------------
wire [5:0] opcode;
wire [4:0] rd;
wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] alu_op;

assign opcode = instr[31:26];
assign rd     = instr[25:21];
assign rs1    = instr[20:16];
assign rs2    = instr[15:11];
assign alu_op = instr[10:6];

wire [15:0] imm16;

assign imm16 = instr[15:0];

wire [31:0] imm_s;
wire [31:0] imm_z;

assign imm_s = {{16{imm16[15]}}, imm16};
assign imm_z = {16'b0, imm16};
// ------------------------------------------------------------
// Register Read Stage
// x0 is hardwired to zero
// ------------------------------------------------------------
wire [31:0] rdata_rs1;
wire [31:0] rdata_rs2;
wire [31:0] rdata_rd;

assign rdata_rs1 =
    (rs1 == 5'd0)
    ? 32'b0
    : regfile[rs1];

assign rdata_rs2 =
    (rs2 == 5'd0)
    ? 32'b0
    : regfile[rs2];

assign rdata_rd =
    (rd == 5'd0)
    ? 32'b0
    : regfile[rd];

// ------------------------------------------------------------
// ALU Operand Selection
// ------------------------------------------------------------
reg [31:0] alu_a;
reg [31:0] alu_b;
reg [4:0]  alu_opcode;

always @(*) begin

    // default : R-type instruction
    alu_a      = rdata_rs1;
    alu_b      = rdata_rs2;
    alu_opcode = alu_op;

    case(opcode)

        // arithmetic immediates
        OP_ADDI: begin
            alu_b      = imm_s;
            alu_opcode = 5'd0;
        end

        OP_SUBI: begin
            alu_b      = imm_s;
            alu_opcode = 5'd1;
        end

        OP_MULI: begin
            alu_b      = imm_s;
            alu_opcode = 5'd2;
        end

        OP_DIVI: begin
            alu_b      = imm_s;
            alu_opcode = 5'd3;
        end

        OP_MODI: begin
            alu_b      = imm_s;
            alu_opcode = 5'd4;
        end

        // logic immediates
        OP_ANDI: begin
            alu_b      = imm_z;
            alu_opcode = 5'd5;
        end

        OP_ORI: begin
            alu_b      = imm_z;
            alu_opcode = 5'd6;
        end

        OP_XORI: begin
            alu_b      = imm_z;
            alu_opcode = 5'd7;
        end

        // compare immediates
        OP_SLTI: begin
            alu_b      = imm_s;
            alu_opcode = 5'd12;
        end

        OP_SLTIU: begin
            alu_b      = imm_s;
            alu_opcode = 5'd13;
        end

        // shift immediates
        OP_SLLI: begin
            alu_b      = imm_z;
            alu_opcode = 5'd14;
        end

        OP_SRLI: begin
            alu_b      = imm_z;
            alu_opcode = 5'd15;
        end

        OP_SRAI: begin
            alu_b      = imm_z;
            alu_opcode = 5'd16;
        end

        // min/max immediates
        OP_MINI: begin
            alu_b      = imm_s;
            alu_opcode = 5'd26;
        end

        OP_MAXI: begin
            alu_b      = imm_s;
            alu_opcode = 5'd27;
        end

        // address generation
        OP_LOAD,
        OP_STORE,
        OP_JALR:
        begin
            alu_b      = imm_s;
            alu_opcode = 5'd0;
        end

        default: begin
            alu_b      = rdata_rs2;
            alu_opcode = alu_op;
        end

    endcase
end

// ------------------------------------------------------------
// ALU Interface
// ------------------------------------------------------------
wire [63:0] alu_result64;

wire alu_zero;
wire alu_carry;
wire alu_overflow;
wire alu_negative;
wire alu_parity;

// shared ALU instance
HX32_ALU alu0(
    .A(alu_a),
    .B(alu_b),
    .opcode(alu_opcode),
    .result(alu_result64),
    .zero(alu_zero),
    .carry(alu_carry),
    .overflow(alu_overflow),
    .negative(alu_negative),
    .parity_flag(alu_parity)
);

wire [31:0] alu_result;

assign alu_result = alu_result64[31:0];
// ------------------------------------------------------------
// Memory Interface
// ------------------------------------------------------------
wire [31:0] mem_addr;

assign mem_addr = alu_result;

// little endian 32-bit load
wire [31:0] load_data;

assign load_data = {
    dmem[mem_addr + 3],
    dmem[mem_addr + 2],
    dmem[mem_addr + 1],
    dmem[mem_addr + 0]
};

// stack read
wire [31:0] stack_data;

assign stack_data = {
    dmem[sp + 3],
    dmem[sp + 2],
    dmem[sp + 1],
    dmem[sp + 0]
};

// ------------------------------------------------------------
// Branch Unit
// ------------------------------------------------------------
reg branch_taken;

always @(*) begin

    branch_taken = 1'b0;

    case(opcode)

        OP_BEQ:
            branch_taken = (rdata_rd == rdata_rs1);

        OP_BNE:
            branch_taken = (rdata_rd != rdata_rs1);

        OP_BLT:
            branch_taken =
                ($signed(rdata_rd) < $signed(rdata_rs1));

        OP_BGE:
            branch_taken =
                ($signed(rdata_rd) >= $signed(rdata_rs1));

        OP_BLTU:
            branch_taken =
                (rdata_rd < rdata_rs1);

        OP_BGEU:
            branch_taken =
                (rdata_rd >= rdata_rs1);

        OP_BZ:
            branch_taken = (rdata_rd == 32'b0);

        OP_BNZ:
            branch_taken = (rdata_rd != 32'b0);

        default:
            branch_taken = 1'b0;

    endcase
end

// ------------------------------------------------------------
// PC Generation
// ------------------------------------------------------------
wire [31:0] pc_plus4;

assign pc_plus4 = pc + 32'd4;

reg [31:0] next_pc;

always @(*) begin

    next_pc = pc_plus4;

    if(opcode == OP_JAL)
        next_pc = pc + imm_s;

    else if(opcode == OP_JALR)
        next_pc = alu_result;

    else if(opcode == OP_CALL)
        next_pc = pc + imm_s;

    else if(opcode == OP_RET)
        next_pc = stack_data;

    else if(branch_taken)
        next_pc = pc + imm_s;

end

// ------------------------------------------------------------
// Writeback Mux
// ------------------------------------------------------------
reg [31:0] wb_data;

always @(*) begin

    wb_data = alu_result;

    case(opcode)

        OP_LOAD:
            wb_data = load_data;

        OP_MOV:
            wb_data = rdata_rs1;

        OP_MOVI:
            wb_data = imm_s;

        OP_LUI:
            wb_data = {imm16,16'b0};

        OP_AUIPC:
            wb_data = pc + {imm16,16'b0};

        OP_IN:
            wb_data = in_port;

        OP_POP:
            wb_data = stack_data;

        OP_JAL,
        OP_JALR:
            wb_data = pc_plus4;

        default:
            wb_data = alu_result;

    endcase
end

// ------------------------------------------------------------
// Register Write Enable
// ------------------------------------------------------------
wire write_enable;

assign write_enable =

        (opcode == OP_RTYPE) ||

        (opcode == OP_ADDI ) ||
        (opcode == OP_SUBI ) ||
        (opcode == OP_MULI ) ||
        (opcode == OP_DIVI ) ||
        (opcode == OP_MODI ) ||

        (opcode == OP_ANDI ) ||
        (opcode == OP_ORI  ) ||
        (opcode == OP_XORI ) ||

        (opcode == OP_SLTI ) ||
        (opcode == OP_SLTIU) ||

        (opcode == OP_SLLI ) ||
        (opcode == OP_SRLI ) ||
        (opcode == OP_SRAI ) ||

        (opcode == OP_MINI ) ||
        (opcode == OP_MAXI ) ||

        (opcode == OP_LOAD ) ||

        (opcode == OP_MOV  ) ||
        (opcode == OP_MOVI ) ||

        (opcode == OP_LUI  ) ||
        (opcode == OP_AUIPC) ||

        (opcode == OP_IN   ) ||

        (opcode == OP_POP  ) ||

        (opcode == OP_JAL  ) ||
        (opcode == OP_JALR );

        // ------------------------------------------------------------
// Sequential Commit Stage
// ------------------------------------------------------------
integer i;

always @(posedge clk or negedge rst_n) begin

    if(!rst_n) begin

        pc <= RESET_PC;
        sp <= DMEM_BYTES;

        halted_r <= 1'b0;

        out_port  <= 32'b0;
        out_valid <= 1'b0;

        for(i=0;i<32;i=i+1)
            regfile[i] <= 32'b0;

    end

    else if(!halted_r) begin

        // clear output strobe
        out_valid <= 1'b0;

        // advance PC
        pc <= next_pc;

        // register writeback
        if(write_enable && (rd != 5'd0))
            regfile[rd] <= wb_data;

        case(opcode)

            // ------------------------------------------------
            // STORE
            // ------------------------------------------------
            OP_STORE: begin

                dmem[mem_addr + 0] <= rdata_rd[7:0];
                dmem[mem_addr + 1] <= rdata_rd[15:8];
                dmem[mem_addr + 2] <= rdata_rd[23:16];
                dmem[mem_addr + 3] <= rdata_rd[31:24];

            end

            // ------------------------------------------------
            // PUSH
            // stack grows downward
            // ------------------------------------------------
            OP_PUSH: begin

                sp <= sp - 32'd4;

                dmem[sp-4] <= rdata_rd[7:0];
                dmem[sp-3] <= rdata_rd[15:8];
                dmem[sp-2] <= rdata_rd[23:16];
                dmem[sp-1] <= rdata_rd[31:24];

            end

            // ------------------------------------------------
            // CALL
            // push return address
            // ------------------------------------------------
            OP_CALL: begin

                sp <= sp - 32'd4;

                dmem[sp-4] <= pc_plus4[7:0];
                dmem[sp-3] <= pc_plus4[15:8];
                dmem[sp-2] <= pc_plus4[23:16];
                dmem[sp-1] <= pc_plus4[31:24];

            end

            // ------------------------------------------------
            // POP
            // ------------------------------------------------
            OP_POP: begin

                sp <= sp + 32'd4;

            end

            // ------------------------------------------------
            // RET
            // ------------------------------------------------
            OP_RET: begin

                sp <= sp + 32'd4;

            end

            // ------------------------------------------------
            // OUT
            // ------------------------------------------------
            OP_OUT: begin

                out_port  <= rdata_rd;
                out_valid <= 1'b1;

            end

            // ------------------------------------------------
            // HALT
            // ------------------------------------------------
            OP_HALT: begin

                halted_r <= 1'b1;

            end

            default: begin
            end

        endcase

        // x0 is always zero
        regfile[0] <= 32'b0;

    end
end

// ------------------------------------------------------------
// Memory Initialization
// ------------------------------------------------------------
integer k;

initial begin

    // Load the compiled assembly program into Instruction Memory
    $readmemh("program.mem", imem);

    // Initialize Data Memory to zero
    for(k=0;k<DMEM_BYTES;k=k+1)
        dmem[k] = 8'h00;

end

endmodule