`timescale 1ns/10ps
`define CYCLE 15.4

module cnn_tb;

  reg clk;
  reg rst;
  reg start;
  reg ready;
  wire done;
  wire [7:0] result;

  integer err, i;

  wire [31:0] BRAM_IF1_ADDR, BRAM_W1_ADDR, BRAM_IF2_ADDR;
  wire [31:0] BRAM_W2_ADDR, BRAM_W3_ADDR, BRAM_W4_ADDR, BRAM_W5_ADDR;

  wire [3:0] BRAM_IF1_WE, BRAM_IF2_WE;
  wire [3:0] BRAM_W1_WE, BRAM_W2_WE, BRAM_W3_WE, BRAM_W4_WE, BRAM_W5_WE;

  wire BRAM_IF1_EN, BRAM_IF2_EN;
  wire BRAM_W1_EN, BRAM_W2_EN, BRAM_W3_EN, BRAM_W4_EN, BRAM_W5_EN;

  wire [31:0] BRAM_IF1_DOUT, BRAM_IF2_DOUT;
  wire [31:0] BRAM_W1_DOUT, BRAM_W2_DOUT, BRAM_W3_DOUT, BRAM_W4_DOUT, BRAM_W5_DOUT;

  wire [31:0] BRAM_IF1_DIN, BRAM_IF2_DIN;
  wire [31:0] BRAM_W1_DIN, BRAM_W2_DIN, BRAM_W3_DIN, BRAM_W4_DIN, BRAM_W5_DIN;

  // ================= CNN DUT =================
  cnn cnn (
    .clk(clk),
    .rst(rst),
    .start(start),
    .ready(ready),
    .done(done),
    .result(result),

    .BRAM_IF1_ADDR(BRAM_IF1_ADDR),
    .BRAM_IF2_ADDR(BRAM_IF2_ADDR),
    .BRAM_W1_ADDR(BRAM_W1_ADDR),
    .BRAM_W2_ADDR(BRAM_W2_ADDR),
    .BRAM_W3_ADDR(BRAM_W3_ADDR),
    .BRAM_W4_ADDR(BRAM_W4_ADDR),
    .BRAM_W5_ADDR(BRAM_W5_ADDR),

    .BRAM_IF1_WE(BRAM_IF1_WE),
    .BRAM_IF2_WE(BRAM_IF2_WE),
    .BRAM_W1_WE(BRAM_W1_WE),
    .BRAM_W2_WE(BRAM_W2_WE),
    .BRAM_W3_WE(BRAM_W3_WE),
    .BRAM_W4_WE(BRAM_W4_WE),
    .BRAM_W5_WE(BRAM_W5_WE),

    .BRAM_IF1_EN(BRAM_IF1_EN),
    .BRAM_IF2_EN(BRAM_IF2_EN),
    .BRAM_W1_EN(BRAM_W1_EN),
    .BRAM_W2_EN(BRAM_W2_EN),
    .BRAM_W3_EN(BRAM_W3_EN),
    .BRAM_W4_EN(BRAM_W4_EN),
    .BRAM_W5_EN(BRAM_W5_EN),

    .BRAM_IF1_DOUT(BRAM_IF1_DOUT),
    .BRAM_IF2_DOUT(BRAM_IF2_DOUT),
    .BRAM_W1_DOUT(BRAM_W1_DOUT),
    .BRAM_W2_DOUT(BRAM_W2_DOUT),
    .BRAM_W3_DOUT(BRAM_W3_DOUT),
    .BRAM_W4_DOUT(BRAM_W4_DOUT),
    .BRAM_W5_DOUT(BRAM_W5_DOUT),

    .BRAM_IF1_DIN(BRAM_IF1_DIN),
    .BRAM_IF2_DIN(BRAM_IF2_DIN),
    .BRAM_W1_DIN(BRAM_W1_DIN),
    .BRAM_W2_DIN(BRAM_W2_DIN),
    .BRAM_W3_DIN(BRAM_W3_DIN),
    .BRAM_W4_DIN(BRAM_W4_DIN),
    .BRAM_W5_DIN(BRAM_W5_DIN)
  );

  // ================= BRAM INSTANTIATIONS (SIMULATION) =================
    // Feature maps
    bram #(.INIT_FILE("in_32.hex"), .DEPTH(2048)) bram_if1 (
        .clk(clk), .rst(rst), .wen(BRAM_IF1_WE), .addr(BRAM_IF1_ADDR), 
        .en(BRAM_IF1_EN), .dout(BRAM_IF1_DOUT), .din(BRAM_IF1_DIN)
    );
    bram #(.INIT_FILE(""), .DEPTH(2048)) bram_if2 (
        .clk(clk), .rst(rst), .wen(BRAM_IF2_WE), .addr(BRAM_IF2_ADDR), 
        .en(BRAM_IF2_EN), .dout(BRAM_IF2_DOUT), .din(BRAM_IF2_DIN)
    );

    // Weights
    bram #(.INIT_FILE("out_conv1_32.hex"), .DEPTH(128)) bram_w1 (
        .clk(clk), .rst(rst), .wen(BRAM_W1_WE), .addr(BRAM_W1_ADDR), 
        .en(BRAM_W1_EN), .dout(BRAM_W1_DOUT), .din(BRAM_W1_DIN)
    );
    bram #(.INIT_FILE("out_conv2_32.hex"), .DEPTH(1024)) bram_w2 (
        .clk(clk), .rst(rst), .wen(BRAM_W2_WE), .addr(BRAM_W2_ADDR), 
        .en(BRAM_W2_EN), .dout(BRAM_W2_DOUT), .din(BRAM_W2_DIN)
    );
    bram #(.INIT_FILE("out_conv3_32.hex"), .DEPTH(16384)) bram_w3 ( // The 12,000-line fix!
        .clk(clk), .rst(rst), .wen(BRAM_W3_WE), .addr(BRAM_W3_ADDR), 
        .en(BRAM_W3_EN), .dout(BRAM_W3_DOUT), .din(BRAM_W3_DIN)
    ); 
    bram #(.INIT_FILE("out_fc1_32.hex"), .DEPTH(4096)) bram_w4 (
        .clk(clk), .rst(rst), .wen(BRAM_W4_WE), .addr(BRAM_W4_ADDR), 
        .en(BRAM_W4_EN), .dout(BRAM_W4_DOUT), .din(BRAM_W4_DIN)
    );
    bram #(.INIT_FILE("out_fc2_32.hex"), .DEPTH(256)) bram_w5 (
        .clk(clk), .rst(rst), .wen(BRAM_W5_WE), .addr(BRAM_W5_ADDR), 
        .en(BRAM_W5_EN), .dout(BRAM_W5_DOUT), .din(BRAM_W5_DIN)
    );
  // ================= CLOCK =================
  always #(`CYCLE/2) clk = ~clk;

  // ================= TEST =================
  initial begin
    clk   = 0;
    rst   = 1;
    start = 0;
    ready = 1;

    #20 rst = 0;
    
    // Wait for the next rising edge of the clock
    @(posedge clk); 
    start = 1;      // Fire the start signal ON the clock edge
    
    // Hold it high for 2 full clock cycles to ensure the FSM catches it
    @(posedge clk);
    @(posedge clk);
    start = 0;

    wait(done);
    $display("====================================");
    $display(" CNN Prediction Result ");
    $display(" Predicted Digit = %0d", result);
    $display("====================================");

    $finish;
  end
  
  // ================= LOAD MEMORIES =================
  initial begin
    $readmemh("out_conv1_32.hex", bram_w1.mem);
    $readmemh("out_conv2_32.hex", bram_w2.mem);
    $readmemh("out_conv3_32.hex", bram_w3.mem);
    $readmemh("out_fc1_32.hex",   bram_w4.mem);
    $readmemh("out_fc2_32.hex",   bram_w5.mem);
    $readmemh("in_32.hex",        bram_if1.mem);
  end

endmodule
