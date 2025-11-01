`timescale 1ns / 1ps

module systolic_pe #(
    parameter SUM_WIDTH = 4 // enough to hold partial sums
)(
    input  wire clk,
    input  wire reset,
    input  wire valid_in,          // when 1, inputs are valid
    input  wire in_bit,            // input bit from patch
    input  wire weight_bit,        // weight bit
    input  wire [SUM_WIDTH-1:0] partial_sum_in, // from previous PE
    output reg  [SUM_WIDTH-1:0] partial_sum_out,// to next PE
    output reg  valid_out          // pipelined valid signal
);

    wire xnor_bit;
    assign xnor_bit = ~(in_bit ^ weight_bit);

    always @(posedge clk) begin
        if (reset) begin
            partial_sum_out <= 0;
            valid_out       <= 0;
        end else begin
            if (valid_in) begin
                partial_sum_out <= partial_sum_in + xnor_bit; // accumulate
            end
            valid_out <= valid_in; // pipeline valid signal
        end
    end

endmodule

