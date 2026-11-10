`timescale 1ns/1ps

module argmax10_tb;
    reg clk;
    reg rst;
    reg clear;
    reg valid;
    reg [6:0] pair_base_index;
    reg [31:0] score_a;
    reg [31:0] score_b;
    wire [7:0] best_index;
    wire [31:0] best_score;

    cnn_argmax10 dut (
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .valid(valid),
        .pair_base_index(pair_base_index),
        .score_a(score_a),
        .score_b(score_b),
        .best_index(best_index),
        .best_score(best_score)
    );

    always #5 clk = ~clk;

    task send_pair;
        input [6:0] base_index;
        input [31:0] a;
        input [31:0] b;
        begin
            @(negedge clk);
            pair_base_index = base_index;
            score_a = a;
            score_b = b;
            valid = 1'b1;
            @(posedge clk);
            #1 valid = 1'b0;
        end
    endtask

    task check_result;
        input [7:0] expected_index;
        input [31:0] expected_score;
        begin
            if (best_index !== expected_index || best_score !== expected_score) begin
                $display("FAIL: expected class %0d score %0d, got class %0d score %0d",
                         expected_index, expected_score, best_index, best_score);
                $finish;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        clear = 1'b0;
        valid = 1'b0;
        pair_base_index = 0;
        score_a = 0;
        score_b = 0;

        #12;
        @(negedge clk);
        rst = 1'b0;

        // Winners in different pairs, with class 9 winning the final pair.
        send_pair(0, 10, 20);
        check_result(1, 20);
        send_pair(2, 50, 40);
        check_result(2, 50);
        send_pair(4, 30, 60);
        check_result(5, 60);
        send_pair(6, 70, 20);
        check_result(6, 70);
        send_pair(8, 80, 90);
        check_result(9, 90);

        // Equal scores within the final pair choose the lower class index.
        send_pair(8, 95, 95);
        check_result(8, 95);

        // A new inference must not inherit the previous prediction.
        @(negedge clk);
        clear = 1'b1;
        @(posedge clk);
        #1;
        clear = 1'b0;
        check_result(0, 0);

        // A valid zero-valued output remains class zero, not stale state.
        send_pair(0, 0, 0);
        check_result(0, 0);

        $display("PASS: ten-class argmax regression");
        $finish;
    end
endmodule
