`timescale 1ns / 1ps

module tb_HX32_CPU();

    // ------------------------------------------------------------
    // Testbench Signals
    // ------------------------------------------------------------
    reg clk;
    reg rst_n;

    // Inputs to CPU
    reg [31:0] in_port;
    reg [4:0]  dbg_reg_addr;

    // Outputs from CPU
    wire [31:0] out_port;
    wire        out_valid;
    wire [31:0] pc_out;
    wire [31:0] sp_out;
    wire        halted;
    wire [31:0] dbg_reg_data;

    // ------------------------------------------------------------
    // Instantiate the CPU
    // ------------------------------------------------------------
    HX32_CPU #(
        .IMEM_WORDS(256),
        .DMEM_BYTES(1024),
        .RESET_PC(32'h00000000)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .in_port(in_port),
        .out_port(out_port),
        .out_valid(out_valid),
        .pc_out(pc_out),
        .sp_out(sp_out),
        .halted(halted),
        .dbg_reg_addr(dbg_reg_addr),
        .dbg_reg_data(dbg_reg_data)
    );

    // ------------------------------------------------------------
    // Clock Generation (100 MHz)
    // ------------------------------------------------------------
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Simulation Sequence
    // ------------------------------------------------------------
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        in_port = 32'h00000005;
        dbg_reg_addr = 5'd1;

        $display("Starting HX32 CPU Simulation...");

        // Hold reset for 100ns to allow internal states to clear
        #100;
        
        // Release reset (Active low)
        rst_n = 1;

        // Wait dynamically until the CPU sets the 'halted' flag
        wait(halted == 1'b1);
        
        // Give it a few cycles to settle before printing the finish message
        #20;
        $display("----------------------------------------");
        $display("Simulation Finished: CPU Halted!");
        $display("Final PC: %08X", pc_out);
        $display("Final SP: %08X", sp_out);
        $display("----------------------------------------");
        
        // End simulation safely
        $finish;
    end

    // ------------------------------------------------------------
    // Monitor Output Port (Optional but highly recommended)
    // ------------------------------------------------------------
    // This block automatically prints to the Vivado Tcl Console 
    // whenever your assembly code executes an 'OUT' instruction.
    always @(posedge clk) begin
        if (out_valid) begin
            $display("[%0t ns] OUT PORT: %08X (%0d in decimal)", $time, out_port, out_port);
        end
    end

    // ------------------------------------------------------------
    // Timeout Watchdog (Prevents infinite loops)
    // ------------------------------------------------------------
    initial begin
        #10000; // Wait 10,000 ns
        if (!halted) begin
            $display("ERROR: Simulation timeout! CPU did not reach a HALT instruction.");
            $finish;
        end
    end

endmodule