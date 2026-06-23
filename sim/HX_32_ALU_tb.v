`timescale 1ns / 1ps


module HX32_ALU_tb;

    
    // Inputs (reg) and Outputs (wire)
    
    reg  [31:0] A, B;
    reg  [4:0]  opcode;
    wire [63:0] result;
    wire        zero, carry, overflow, negative, parity_flag;

    
    // Instantiate the ALU
    
    HX32_ALU uut (
        .A          (A),
        .B          (B),
        .opcode     (opcode),
        .result     (result),
        .zero       (zero),
        .carry      (carry),
        .overflow   (overflow),
        .negative   (negative),
        .parity_flag(parity_flag)
    );


    // Helper task: print pass/fail

    task check_result;
        input [63:0]  expected;
        input [8*20:1] test_name;
        begin
            #1;
            if (result === expected)
                $display("PASS | %-20s | result = %0d", test_name, result);
            else
                $display("FAIL | %-20s | got = %0d | expected = %0d",
                          test_name, result, expected);
        end
    endtask


    // Test sequence

    initial begin


        
        // ARITHMETIC TESTS
        
        A = 32'd15;  B = 32'd10;  opcode = 5'b00000; #10;
        check_result(64'd25,          "ADD 15+10      ");

        A = 32'd100; B = 32'd100; opcode = 5'b00000; #10;
        $display("     | ADD overflow check     | carry=%b overflow=%b zero=%b",
                  carry, overflow, zero);

        A = 32'd20;  B = 32'd10;  opcode = 5'b00001; #10;
        check_result(64'd10,          "SUB 20-10      ");

        A = 32'd10;  B = 32'd20;  opcode = 5'b00001; #10;
        $display("     | SUB 10-20 (negative)   | result=%0d neg=%b",
                  $signed(result[31:0]), negative);

        A = 32'd12;  B = 32'd12;  opcode = 5'b00010; #10;
        check_result(64'd144,         "MUL 12*12      ");

        A = 32'd100; B = 32'd200; opcode = 5'b00010; #10;
        check_result(64'd20000,       "MUL 100*200    ");

        A = 32'd13;  B = 32'd3;   opcode = 5'b00011; #10;
        $display("     | DIV 13/3              | quot=%0d rem=%0d (expect 4 r 1)",
                  result[31:0], result[63:32]);

        A = 32'd100; B = 32'd0;   opcode = 5'b00011; #10;
        $display("     | DIV by zero           | overflow=%b (expect 1)",
                  overflow);


        // LOGICAL TESTS

        A = 32'hFF00FF00; B = 32'h0F0F0F0F; opcode = 5'b00110; #10;
        check_result(64'h0F000F00,    "AND            ");

        A = 32'hF0F0F0F0; B = 32'h0F0F0F0F; opcode = 5'b00111; #10;
        check_result(64'hFFFFFFFF,    "OR             ");

        A = 32'hFFFFFFFF; B = 32'hFFFFFFFF; opcode = 5'b01000; #10;
        check_result(64'h00000000,    "XOR same=0     ");

        A = 32'hFFFFFFFF; B = 32'b0;        opcode = 5'b01001; #10;
        check_result(64'h00000000,    "NOT 0xFFFF     ");


        // FLAG TESTS

        A = 32'd5;   B = 32'd5;   opcode = 5'b01000; #10;
        $display("     | ZERO flag (XOR same)  | zero=%b (expect 1)", zero);

        A = 32'hFFFFFFFF; B = 32'd1; opcode = 5'b01101; #10;
        $display("     | SLT -1<1 signed       | result=%0d (expect 1)",
                  result[31:0]);

        A = 32'd1; B = 32'hFFFFFFFF; opcode = 5'b01110; #10;
        $display("     | SLTU 1 < big unsigned | result=%0d (expect 1)",
                  result[31:0]);


        // SHIFT TESTS

        A = 32'd1;   B = 32'd4;   opcode = 5'b01111; #10;
        check_result(64'd16,          "SLL 1<<4       ");

        A = 32'd16;  B = 32'd4;   opcode = 5'b10000; #10;
        check_result(64'd1,           "SRL 16>>4      ");

        A = 32'hF0000000; B = 32'd4; opcode = 5'b10001; #10;
        $display("     | SRA arithmetic shift  | result=%h (expect FF000000)",
                  result[31:0]);


        // HX32 NOVEL TESTS

        A = 32'd1;   B = 32'd1;   opcode = 5'b10010; #10;
        check_result(64'd2,           "ROL 1 by 1     ");

        A = 32'd1;   B = 32'd1;   opcode = 5'b10011; #10;
        check_result(64'h80000000,    "ROR 1 by 1     ");

        A = 32'hFF;  B = 32'b0;   opcode = 5'b10100; #10;
        check_result(64'd8,           "POPCNT 0xFF=8  ");

        A = 32'hF0; B = 32'b0;    opcode = 5'b10100; #10;
        check_result(64'd4,           "POPCNT 0xF0=4  ");

        A = 32'h00010000; B = 32'b0; opcode = 5'b10101; #10;
        check_result(64'd15,          "CLZ 0x00010000 ");

        A = 32'h80000000; B = 32'b0; opcode = 5'b10101; #10;
        check_result(64'd0,           "CLZ 0x80000000 ");

        A = 32'b10110001; B = 32'b0; opcode = 5'b10110; #10;
        $display("     | PARITY 10110001       | flag=%b (expect 1=odd)",
                  parity_flag);

        

        $finish;
    end

endmodule
