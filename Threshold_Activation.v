`timescale 1ns / 1ps

module threshold_activation #(
    parameter SUM_WIDTH = 4,    // width of popcount input
    parameter THRESHOLD = 5     // default threshold
)(
    input  wire clk,
    input  wire reset,
    input  wire valid_in,
    input  wire [SUM_WIDTH-1:0] popcount,
    output reg  activation,     // 1 if popcount >= THRESHOLD else 0
    output reg  valid_out
);

    always @(posedge clk) begin
        if (reset) begin
            activation <= 1'b0;
            valid_out  <= 1'b0;
        end else begin
            if (valid_in) begin
                activation <= (popcount >= THRESHOLD);
            end
            valid_out <= valid_in; // pipeline valid
        end
    end

endmodule
