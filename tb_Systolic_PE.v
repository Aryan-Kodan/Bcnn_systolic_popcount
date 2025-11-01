`timescale 1ns / 1ps
module tb_systolic_pe;

    reg clk;
    reg reset;
    reg valid_in;
    reg in_bit;
    reg weight_bit;
    reg [3:0] partial_sum_in;
    wire [3:0] partial_sum_out;
    wire valid_out;

    // Instantiate the PE
    systolic_pe #(.SUM_WIDTH(4)) UUT (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .in_bit(in_bit),
        .weight_bit(weight_bit),
        .partial_sum_in(partial_sum_in),
        .partial_sum_out(partial_sum_out),
        .valid_out(valid_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    // Stimulus
    initial begin
        $display("Time | in_bit weight_bit partial_in -> partial_out valid_out");
        reset = 1; valid_in = 0; in_bit = 0; weight_bit = 0; partial_sum_in = 0;
        #12 reset = 0;

        // Example sequence:
        // (in_bit, weight_bit, partial_in)
        send_bit(1, 1, 4'd0); // XNOR=1, sum=1
        send_bit(0, 1, 4'd1); // XNOR=0, sum stays
        send_bit(1, 0, 4'd1); // XNOR=0
        send_bit(0, 0, 4'd1); // XNOR=1
        send_bit(1, 1, 4'd2); // XNOR=1

        #50 $finish;
    end

    task send_bit(input b_in, input b_w, input [3:0] sum_in);
    begin
        @(negedge clk);
        valid_in = 1;
        in_bit = b_in;
        weight_bit = b_w;
        partial_sum_in = sum_in;
        @(negedge clk);
        valid_in = 0; // one-cycle pulse
    end
    endtask

    always @(posedge clk) begin
        if (valid_out) begin
            $display("%0t | %b %b %0d -> %0d %b",
                $time, in_bit, weight_bit, partial_sum_in, partial_sum_out, valid_out);
        end
    end

endmodule

