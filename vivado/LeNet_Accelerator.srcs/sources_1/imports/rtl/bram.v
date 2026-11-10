`timescale 1ns/10ps

module bram #(
    parameter INIT_FILE = "",
    parameter DEPTH = 1024 // Default depth to save space during synthesis
)(
    input wire clk,
    input wire rst,           // Required by cnn.v port mapping
    input wire [3:0] wen,     // 4-bit write enable from cnn.v
    input wire [31:0] addr,   // 32-bit byte-aligned address
    input wire en,            // Read/Write enable signal
    input wire [31:0] din,    // 32-bit data in
    output reg [31:0] dout    // 32-bit data out
);

    // Dynamic memory array sizing based on the DEPTH parameter
    reg [31:0] mem [0:DEPTH-1];

    // Load the hex weights/inputs if a filename is provided
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    // Synchronous Read/Write Logic
    always @(posedge clk) begin
        if (en) begin
            if (|wen) begin 
                // Shift address right by 2 (addr >> 2) to convert 
                // byte-addressing into 32-bit word-addressing
                mem[addr >> 2] <= din;
            end
            dout <= mem[addr >> 2];
        end
    end

endmodule