`timescale 1ns/10ps

module bram #(
    parameter INIT_FILE = "" // Allows us to pass the .hex filename from the top module
)(
    input wire clk,
    input wire rst,           // Required by cnn.v
    input wire [3:0] wen,     // 4-bit write enable required by cnn.v
    input wire [31:0] addr,   // 32-bit byte address
    input wire en,            // Required by cnn.v
    input wire [31:0] din,    // 32-bit data in
    output reg [31:0] dout    // 32-bit data out
);

    // 32-bit wide memory, 32,768 deep to fit Conv3
    reg [31:0] mem [0:32767];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    always @(posedge clk) begin
        if (en) begin
            if (|wen) begin // If any bit of the 4-bit write-enable is high
                // Shift address by 2 to convert byte-address to word-address
                mem[addr >> 2] <= din;
            end
            dout <= mem[addr >> 2];
        end
    end

endmodule
