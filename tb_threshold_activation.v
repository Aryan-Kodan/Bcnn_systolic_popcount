`timescale 1ns / 1ps
`include "threshold_activation.v"

module tb_threshold_activation;

    reg clk;
    reg reset;
    reg valid_in;
    reg [3:0] popcount;
    wire activation;
    wire valid_out;

    // Instantiate module
    threshold_activation #(.SUM_WIDTH(4), .THRESHOLD(5)) DUT (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .popcount(popcount),
        .activation(activation),
        .valid_out(valid_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz
    end

    initial begin
        $display("Time | popcount -> activation valid_out");
        reset = 1; valid_in = 0; popcount = 0;
        #12 reset = 0;

        // Popcounts below threshold (5)
        send_popcount(4'd2); // expect 0
        send_popcount(4'd4); // expect 0
        // Popcounts at or above threshold
        send_popcount(4'd5); // expect 1
        send_popcount(4'd9); // expect 1

        #50 $finish;
    end

    task send_popcount(input [3:0] pc);
    begin
        @(negedge clk);
        valid_in = 1;
        popcount = pc;
        @(negedge clk);
        valid_in = 0;
    end
    endtask

    always @(posedge clk) begin
        if (valid_out) begin
            $display("%0t | %0d -> %b %b",
                $time, popcount, activation, valid_out);
        end
    end

endmodule

