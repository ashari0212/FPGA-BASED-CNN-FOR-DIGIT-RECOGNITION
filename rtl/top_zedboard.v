`timescale 1ns / 1ps

module top_zedboard(
    input wire clk_100mhz,  // Y9 pin on ZedBoard
    input wire rst_btn,     // Center push button
    input wire start_btn,   // Down push button
    output wire [7:0] led   // The 8 LEDs
);

    // ================= WIRES =================
    wire done;
    wire [7:0] result;
    
    // BRAM Addressing & Control
    wire [31:0] BRAM_IF1_ADDR, BRAM_IF2_ADDR;
    wire [31:0] BRAM_W1_ADDR, BRAM_W2_ADDR, BRAM_W3_ADDR, BRAM_W4_ADDR, BRAM_W5_ADDR;
    
    wire [3:0] BRAM_IF1_WE, BRAM_IF2_WE;
    wire [3:0] BRAM_W1_WE, BRAM_W2_WE, BRAM_W3_WE, BRAM_W4_WE, BRAM_W5_WE;
    
    wire BRAM_IF1_EN, BRAM_IF2_EN;
    wire BRAM_W1_EN, BRAM_W2_EN, BRAM_W3_EN, BRAM_W4_EN, BRAM_W5_EN;
    
    // BRAM Data Lines
    wire [31:0] BRAM_IF1_DOUT, BRAM_IF2_DOUT;
    wire [31:0] BRAM_W1_DOUT, BRAM_W2_DOUT, BRAM_W3_DOUT, BRAM_W4_DOUT, BRAM_W5_DOUT;
    
    wire [31:0] BRAM_IF1_DIN, BRAM_IF2_DIN;
    wire [31:0] BRAM_W1_DIN, BRAM_W2_DIN, BRAM_W3_DIN, BRAM_W4_DIN, BRAM_W5_DIN;

    // ================= CNN CORE =================
    cnn accelerator_core (
        .clk(clk_100mhz),
        .rst(rst_btn),
        .start(start_btn),
        .ready(1'b1), // Always ready to output
        .done(done),
        .result(result),
        
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
    // Synthesizer will automatically initialize these with the hex files!
    
    // IF1 loads the input image (change this filename to test different digits)
    bram #(.INIT_FILE("in_32.hex"))        bram_if1 (.clk(clk_100mhz), .rst(rst_btn), .wen(BRAM_IF1_WE), .addr(BRAM_IF1_ADDR), .en(BRAM_IF1_EN), .dout(BRAM_IF1_DOUT), .din(BRAM_IF1_DIN));
    
    // IF2 is intermediate memory, so it starts empty
    bram #(.INIT_FILE(""))                 bram_if2 (.clk(clk_100mhz), .rst(rst_btn), .wen(BRAM_IF2_WE), .addr(BRAM_IF2_ADDR), .en(BRAM_IF2_EN), .dout(BRAM_IF2_DOUT), .din(BRAM_IF2_DIN));

    // Weights for all 5 layers
    bram #(.INIT_FILE("out_conv1_32.hex")) bram_w1  (.clk(clk_100mhz), .rst(rst_btn), .wen(BRAM_W1_WE), .addr(BRAM_W1_ADDR), .en(BRAM_W1_EN), .dout(BRAM_W1_DOUT), .din(BRAM_W1_DIN));
    bram #(.INIT_FILE("out_conv2_32.hex")) bram_w2  (.clk(clk_100mhz), .rst(rst_btn), .wen(BRAM_W2_WE), .addr(BRAM_W2_ADDR), .en(BRAM_W2_EN), .dout(BRAM_W2_DOUT), .din(BRAM_W2_DIN));
    bram #(.INIT_FILE("out_conv3_32.hex")) bram_w3  (.clk(clk_100mhz), .rst(rst_btn), .wen(BRAM_W3_WE), .addr(BRAM_W3_ADDR), .en(BRAM_W3_EN), .dout(BRAM_W3_DOUT), .din(BRAM_W3_DIN));
    bram #(.INIT_FILE("out_fc1_32.hex"))   bram_w4  (.clk(clk_100mhz), .rst(rst_btn), .wen(BRAM_W4_WE), .addr(BRAM_W4_ADDR), .en(BRAM_W4_EN), .dout(BRAM_W4_DOUT), .din(BRAM_W4_DIN));
    bram #(.INIT_FILE("out_fc2_32.hex"))   bram_w5  (.clk(clk_100mhz), .rst(rst_btn), .wen(BRAM_W5_WE), .addr(BRAM_W5_ADDR), .en(BRAM_W5_EN), .dout(BRAM_W5_DOUT), .din(BRAM_W5_DIN));

    // ================= OUTPUT LOGIC =================
    // Display the 4-bit binary result on LEDs 3 to 0.
    // Turn on LED 7 when the inference is 'done'.
    assign led[3:0] = result[3:0];
    assign led[6:4] = 3'b000;
    assign led[7]   = done;

endmodule
