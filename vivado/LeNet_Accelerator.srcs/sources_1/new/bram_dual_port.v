`timescale 1ns/10ps

module bram_dual_port #(
    parameter INIT_FILE = "",
    parameter DEPTH = 1024
)(
    // ================= PORT A: ARM Processor (AXI) =================
    input wire clk_a,
    input wire en_a,
    input wire [3:0] we_a,    // 4-bit byte-enable for writing
    input wire [31:0] addr_a, // 32-bit byte-aligned address
    input wire [31:0] din_a,  // Pixels coming FROM ARM
    output reg [31:0] dout_a, // Data going TO ARM

    // ================= PORT B: CNN Logic (cnn.v) =================
    input wire clk_b,
    input wire en_b,
    input wire [3:0] we_b,
    input wire [31:0] addr_b,
    input wire [31:0] din_b,
    output reg [31:0] dout_b
);

    // The shared physical memory array
    reg [31:0] mem [0:DEPTH-1];

    // Optional: Load initial weights/images for testing
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    // Port A Operation (Independent)
    always @(posedge clk_a) begin
        if (en_a) begin
            if (|we_a) begin
                mem[addr_a >> 2] <= din_a;
            end
            dout_a <= mem[addr_a >> 2];
        end
    end

    // Port B Operation (Independent)
    always @(posedge clk_b) begin
        if (en_b) begin
            if (|we_b) begin
                mem[addr_b >> 2] <= din_b;
            end
            dout_b <= mem[addr_b >> 2];
        end
    end

endmodule