`timescale 1ns / 1ps

module binarizer #(
    parameter WIDTH     = 4,
    parameter THRESHOLD = 5
)(
    input  wire clk,
    input  wire reset,
    input  wire [WIDTH-1:0] in,
    output reg  out
);

always @(posedge clk) begin
    if (reset)
        out <= 0;
    else begin
        if (in >= THRESHOLD)
            out <= 1;
        else
            out <= 0;
    end
end

endmodule

