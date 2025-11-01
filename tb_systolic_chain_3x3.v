`timescale 1ns / 1ps

module tb_systolic_chain_3x3;

    reg clk;
    reg reset;
    reg valid_in;
    reg [8:0] patch_bits;
    reg [8:0] weight_bits;
    wire [3:0] popcount;
    wire valid_out;

    systolic_chain_3x3 #(.SUM_WIDTH(4)) DUT (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .patch_bits(patch_bits),
        .weight_bits(weight_bits),
        .popcount(popcount),
        .valid_out(valid_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz
    end

    initial begin
        $display("Time | patch_bits weight_bits -> popcount valid_out");
        reset = 1; valid_in = 0; patch_bits = 9'b0; weight_bits = 9'b0;
        #15 reset = 0;

        // Example 1: all match -> popcount=9
        send_patch(9'b111111111, 9'b111111111); // expect 9
        // Example 2: half mismatch
        send_patch(9'b101010101, 9'b111111111); // expect 5
        // Example 3: all mismatch -> popcount=0
        send_patch(9'b000000000, 9'b111111111); // expect 0
        // Example 4: random
        send_patch(9'b110101001, 9'b101101111); // random test

        #100 $finish;
    end

    task send_patch(input [8:0] patch, input [8:0] weights);
    begin
        @(negedge clk);
        valid_in = 1;
        patch_bits = patch;
        weight_bits = weights;
        @(negedge clk);
        valid_in = 0; // one cycle pulse
    end
    endtask

    always @(posedge clk) begin
        if (valid_out) begin
            $display("%0t | %b %b -> %0d %b",
                     $time, patch_bits, weight_bits, popcount, valid_out);
        end
    end

endmodule

