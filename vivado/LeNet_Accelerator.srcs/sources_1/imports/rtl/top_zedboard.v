`timescale 1ns / 1ps

module top_zedboard(
    // ================= ARM CONTROL PORTS (via AXI GPIO) =================
    input  wire clk,
    input  wire [1:0] arm_ctrl,   // bit 1: start, bit 0: rst
    output wire [8:0] arm_status, // bit 8: done, bits 7:0: result

    // ================= ARM MEMORY PORTS (via AXI BRAM Controller) =================
    input  wire bram_clk_a,
    input  wire bram_en_a,
    input  wire [3:0] bram_we_a,
    input  wire [31:0] bram_addr_a,
    input  wire [31:0] bram_wrdata_a,
    output wire [31:0] bram_rddata_a
);

    // ================= INTERNAL WIRES =================
    wire done_wire;
    wire [7:0] result_wire;
    
    // Map internal wires to the ARM status bus
    assign arm_status = {done_wire, result_wire};

    // BRAM Addressing & Control Wires for CNN (Port B for IF1, normal for others)
    wire [31:0] BRAM_IF1_ADDR, BRAM_IF2_ADDR;
    wire [31:0] BRAM_W1_ADDR, BRAM_W2_ADDR, BRAM_W3_ADDR, BRAM_W4_ADDR, BRAM_W5_ADDR;
    
    wire [3:0] BRAM_IF1_WE, BRAM_IF2_WE;
    wire [3:0] BRAM_W1_WE, BRAM_W2_WE, BRAM_W3_WE, BRAM_W4_WE, BRAM_W5_WE;
    
    wire BRAM_IF1_EN, BRAM_IF2_EN;
    wire BRAM_W1_EN, BRAM_W2_EN, BRAM_W3_EN, BRAM_W4_EN, BRAM_W5_EN;
    
    wire [31:0] BRAM_IF1_DOUT, BRAM_IF2_DOUT;
    wire [31:0] BRAM_W1_DOUT, BRAM_W2_DOUT, BRAM_W3_DOUT, BRAM_W4_DOUT, BRAM_W5_DOUT;
    
    wire [31:0] BRAM_IF1_DIN, BRAM_IF2_DIN;
    wire [31:0] BRAM_W1_DIN, BRAM_W2_DIN, BRAM_W3_DIN, BRAM_W4_DIN, BRAM_W5_DIN;

    // ================= CNN CORE =================
    cnn accelerator_core (
        .clk(clk),
        .rst(arm_ctrl[0]),      // Bit 0 is reset
        .start(arm_ctrl[1]),    // Bit 1 is start
        .ready(1'b1),           // Always ready to output
        .done(done_wire),
        .result(result_wire),
        
        .BRAM_IF1_ADDR(BRAM_IF1_ADDR), .BRAM_IF2_ADDR(BRAM_IF2_ADDR),
        .BRAM_W1_ADDR(BRAM_W1_ADDR), .BRAM_W2_ADDR(BRAM_W2_ADDR), .BRAM_W3_ADDR(BRAM_W3_ADDR), .BRAM_W4_ADDR(BRAM_W4_ADDR), .BRAM_W5_ADDR(BRAM_W5_ADDR),
        
        .BRAM_IF1_WE(BRAM_IF1_WE), .BRAM_IF2_WE(BRAM_IF2_WE),
        .BRAM_W1_WE(BRAM_W1_WE), .BRAM_W2_WE(BRAM_W2_WE), .BRAM_W3_WE(BRAM_W3_WE), .BRAM_W4_WE(BRAM_W4_WE), .BRAM_W5_WE(BRAM_W5_WE),
        
        .BRAM_IF1_EN(BRAM_IF1_EN), .BRAM_IF2_EN(BRAM_IF2_EN),
        .BRAM_W1_EN(BRAM_W1_EN), .BRAM_W2_EN(BRAM_W2_EN), .BRAM_W3_EN(BRAM_W3_EN), .BRAM_W4_EN(BRAM_W4_EN), .BRAM_W5_EN(BRAM_W5_EN),
        
        .BRAM_IF1_DOUT(BRAM_IF1_DOUT), .BRAM_IF2_DOUT(BRAM_IF2_DOUT),
        .BRAM_W1_DOUT(BRAM_W1_DOUT), .BRAM_W2_DOUT(BRAM_W2_DOUT), .BRAM_W3_DOUT(BRAM_W3_DOUT), .BRAM_W4_DOUT(BRAM_W4_DOUT), .BRAM_W5_DOUT(BRAM_W5_DOUT),
        
        .BRAM_IF1_DIN(BRAM_IF1_DIN), .BRAM_IF2_DIN(BRAM_IF2_DIN),
        .BRAM_W1_DIN(BRAM_W1_DIN), .BRAM_W2_DIN(BRAM_W2_DIN), .BRAM_W3_DIN(BRAM_W3_DIN), .BRAM_W4_DIN(BRAM_W4_DIN), .BRAM_W5_DIN(BRAM_W5_DIN)
    );

    // ================= BRAM INSTANTIATIONS =================
    
    // IF1: The Dual-Port memory upgrade. 
    // Port A faces the ARM Processor (AXI BRAM Ctrl)
    // Port B faces the CNN Core
    bram_dual_port #(.INIT_FILE(""), .DEPTH(2048)) bram_if1 (
        .clk_a(bram_clk_a), 
        .en_a(bram_en_a), 
        .we_a(bram_we_a), 
        .addr_a(bram_addr_a), 
        .din_a(bram_wrdata_a), 
        .dout_a(bram_rddata_a),
        
        .clk_b(clk),  
        .en_b(BRAM_IF1_EN), 
        .we_b(BRAM_IF1_WE), 
        .addr_b(BRAM_IF1_ADDR), 
        .din_b(BRAM_IF1_DIN), 
        .dout_b(BRAM_IF1_DOUT)
    );

    // IF2 & Weights: Standard single-port memory
    bram #(.INIT_FILE(""), .DEPTH(2048)) bram_if2 (
        .clk(clk), .rst(arm_ctrl[0]), .wen(BRAM_IF2_WE), .addr(BRAM_IF2_ADDR), .en(BRAM_IF2_EN), .dout(BRAM_IF2_DOUT), .din(BRAM_IF2_DIN)
    );
    bram #(.INIT_FILE("out_conv1_32.hex"), .DEPTH(128)) bram_w1 (
        .clk(clk), .rst(arm_ctrl[0]), .wen(BRAM_W1_WE), .addr(BRAM_W1_ADDR), .en(BRAM_W1_EN), .dout(BRAM_W1_DOUT), .din(BRAM_W1_DIN)
    );
    bram #(.INIT_FILE("out_conv2_32.hex"), .DEPTH(1024)) bram_w2 (
        .clk(clk), .rst(arm_ctrl[0]), .wen(BRAM_W2_WE), .addr(BRAM_W2_ADDR), .en(BRAM_W2_EN), .dout(BRAM_W2_DOUT), .din(BRAM_W2_DIN)
    );
    bram #(.INIT_FILE("out_conv3_32.hex"), .DEPTH(16384)) bram_w3 (
        .clk(clk), .rst(arm_ctrl[0]), .wen(BRAM_W3_WE), .addr(BRAM_W3_ADDR), .en(BRAM_W3_EN), .dout(BRAM_W3_DOUT), .din(BRAM_W3_DIN)
    );
    bram #(.INIT_FILE("out_fc1_32.hex"), .DEPTH(4096)) bram_w4 (
        .clk(clk), .rst(arm_ctrl[0]), .wen(BRAM_W4_WE), .addr(BRAM_W4_ADDR), .en(BRAM_W4_EN), .dout(BRAM_W4_DOUT), .din(BRAM_W4_DIN)
    );
    bram #(.INIT_FILE("out_fc2_32.hex"), .DEPTH(256)) bram_w5 (
        .clk(clk), .rst(arm_ctrl[0]), .wen(BRAM_W5_WE), .addr(BRAM_W5_ADDR), .en(BRAM_W5_EN), .dout(BRAM_W5_DOUT), .din(BRAM_W5_DIN)
    );

endmodule