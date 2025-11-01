`timescale 1ns / 1ps

module patch_extractor_28x28 #(
    parameter IMG_WIDTH   = 28,
    parameter IMG_HEIGHT  = 28,
    parameter KERNEL_SIZE = 3
)(
    input  wire clk,
    input  wire reset,
    input  wire pixel_in,
    input  wire valid_in,
    output reg  [KERNEL_SIZE*KERNEL_SIZE-1:0] patch_out,
    output reg  valid_out
);

    localparam PATCH_SIZE = KERNEL_SIZE*KERNEL_SIZE;

    reg [IMG_WIDTH-1:0] linebuf1;
    reg [IMG_WIDTH-1:0] linebuf2;

    integer col_count;
    integer row_count;

    reg [KERNEL_SIZE-1:0] window_row0;
    reg [KERNEL_SIZE-1:0] window_row1;
    reg [KERNEL_SIZE-1:0] window_row2;

    initial begin
        col_count = 0;
        row_count = 0;
    end

    always @(posedge clk) begin
        if (reset) begin
            linebuf1    <= 0;
            linebuf2    <= 0;
            col_count   <= 0;
            row_count   <= 0;
            window_row0 <= 0;
            window_row1 <= 0;
            window_row2 <= 0;
            patch_out   <= 0;
            valid_out   <= 0;
        end else if (valid_in) begin
            if (row_count >= 1)
                linebuf1[col_count] <= pixel_in;
            if (row_count >= 2)
                linebuf2[col_count] <= linebuf1[col_count];

            window_row0 <= {window_row0[KERNEL_SIZE-2:0], pixel_in};
            window_row1 <= {window_row1[KERNEL_SIZE-2:0], linebuf1[col_count]};
            window_row2 <= {window_row2[KERNEL_SIZE-2:0], linebuf2[col_count]};

            patch_out <= {window_row2, window_row1, window_row0};

            if (col_count == IMG_WIDTH-1) begin
                col_count <= 0;
                if (row_count != IMG_HEIGHT-1)
                    row_count <= row_count + 1;
            end else begin
                col_count <= col_count + 1;
            end

            if (row_count >= KERNEL_SIZE-1 && col_count >= KERNEL_SIZE-1)
                valid_out <= 1'b1;
            else
                valid_out <= 1'b0;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule

