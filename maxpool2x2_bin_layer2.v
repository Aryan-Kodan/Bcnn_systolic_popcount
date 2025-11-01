`timescale 1ns / 1ps

module maxpool2x2_bin_layer2 #(
    parameter IN_WIDTH  = 11,
    parameter IN_HEIGHT = 11
)(
    input  wire clk,
    input  wire reset,
    input  wire valid_in,
    input  wire pixel_in,
    output reg  pixel_out,
    output reg  valid_out
);

    reg linebuf [0:IN_WIDTH-1];
    integer row_count;
    integer col_count;
    reg top_left, top_right, bottom_left, bottom_right;
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            row_count  <= 0;
            col_count  <= 0;
            pixel_out  <= 0;
            valid_out  <= 0;
            for (i = 0; i < IN_WIDTH; i = i + 1)
                linebuf[i] <= 0;
        end else if (valid_in) begin
            top_left     <= linebuf[col_count];
            top_right    <= linebuf[col_count + 1];
            bottom_left  <= pixel_in;
            bottom_right <= pixel_in;
            linebuf[col_count] <= pixel_in;

            if ((row_count % 2 == 1) && (col_count % 2 == 1)) begin
                pixel_out <= top_left | top_right | bottom_left | bottom_right;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end

            if (col_count == IN_WIDTH - 1) begin
                col_count <= 0;
                row_count <= row_count + 1;
            end else begin
                col_count <= col_count + 1;
            end
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule

