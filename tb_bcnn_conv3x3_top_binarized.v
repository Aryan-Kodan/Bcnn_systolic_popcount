`timescale 1ns / 1ps

module tb_bcnn_conv3x3_top_binarized;

    // Parameters
    localparam IMG_WIDTH   = 28;
    localparam IMG_HEIGHT  = 28;
    localparam KERNEL_SIZE = 3;
    localparam SUM_WIDTH   = 4;
    localparam BIN_OUT     = 1;  // 1-bit binarized output
    localparam THRESHOLD   = 3;  // binarization threshold

    // Clock/reset
    reg clk;
    reg reset;

    // Input
    reg pixel_in;
    reg valid_in;
    reg [KERNEL_SIZE*KERNEL_SIZE-1:0] weight_bits;

    // Convolution outputs
    wire [SUM_WIDTH-1:0] popcount;
    wire valid_out;

    // Binarizer output
    wire bin_out;

    // DUT: Convolution
    bcnn_conv3x3_top #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .KERNEL_SIZE(KERNEL_SIZE),
        .SUM_WIDTH(SUM_WIDTH)
    ) conv_inst (
        .clk(clk),
        .reset(reset),
        .pixel_in(pixel_in),
        .valid_in(valid_in),
        .weight_bits(weight_bits),
        .popcount(popcount),
        .valid_out(valid_out)
    );

    // Binarizer
    binarizer #(
        .WIDTH(SUM_WIDTH),
        .THRESHOLD(THRESHOLD)
    ) bin_inst (
        .clk(clk),
        .reset(reset),
        .in(popcount),
        .out(bin_out)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Image memory (flattened 28x28)
    reg [IMG_WIDTH*IMG_HEIGHT-1:0] image_bits;

    // Patch coordinate counters
    integer patch_row;
    integer patch_col;

    // Binarized output image array
    localparam OUT_ROWS = IMG_HEIGHT - KERNEL_SIZE + 1;
    localparam OUT_COLS = IMG_WIDTH  - KERNEL_SIZE + 1;
    reg [BIN_OUT-1:0] bin_image [0:OUT_ROWS-1][0:OUT_COLS-1];

    // File handle for CSV
    integer fd;
    integer i, r, c;

    initial begin
        // Reset
        reset       = 1;
        pixel_in    = 0;
        valid_in    = 0;
        weight_bits = 9'b111111111; // example kernel

        // Example image (flattened 28x28)
        image_bits = 784'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100000000000000000000000011111000000000000000000000011111100000000000000000000011111011000000000000000000111111101110000000000000000011110110011000000000000000011110000001100000000000000011110000000111000000000000011100000000011100000000000001100000000001110000000000001110000000000111000000000000110000000000011100000000000011000000000011100000000000001100000000011100000000000000110000000011100000000000000011000000011100000000000000001110001111100000000000000000111111111100000000000000000011111111000000000000000000000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;

        patch_row = 0;
        patch_col = 0;

        // Release reset
        #20 reset = 0;

        // Stream pixels one by one
        valid_in = 1;
        for (i = 0; i < IMG_WIDTH*IMG_HEIGHT; i = i + 1) begin
            pixel_in = image_bits[i];
            #10; // one clock per pixel
        end
        valid_in = 0;

        // Wait extra cycles to drain pipeline
        #500;

        // Dump binarized image to CSV
        fd = $fopen("binarized_output.csv","w");
        for (r = 0; r < OUT_ROWS; r = r + 1) begin
            for (c = 0; c < OUT_COLS; c = c + 1) begin
                $fwrite(fd, "%0d", bin_image[r][c]);
                if (c != OUT_COLS-1) $fwrite(fd, ",");
            end
            $fwrite(fd, "\n");
        end
        $fclose(fd);
        $display("Binarized image CSV saved as binarized_output.csv");
        $finish;
    end

    // Capture binarizer output
    always @(posedge clk) begin
        if (reset) begin
            patch_row <= 0;
            patch_col <= 0;
        end else if (valid_out) begin
            bin_image[patch_row][patch_col] <= bin_out;
            $display("Time %0t : Patch at (row=%0d, col=%0d) Binarized=%0d",
                      $time, patch_row, patch_col, bin_out);

            // Advance coordinates
            if (patch_col == (OUT_COLS-1)) begin
                patch_col <= 0;
                patch_row <= patch_row + 1;
            end else begin
                patch_col <= patch_col + 1;
            end
        end
    end

endmodule

