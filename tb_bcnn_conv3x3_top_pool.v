`timescale 1ns / 1ps

module tb_bcnn_conv3x3_top_pool;

    // Parameters
    localparam IMG_WIDTH   = 28;
    localparam IMG_HEIGHT  = 28;
    localparam KERNEL_SIZE = 3;
    localparam SUM_WIDTH   = 4;     // popcount width
    localparam THRESHOLD   = 3;     // binarizer threshold

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

    // Pooled output
    wire pool_out;
    wire pool_valid;

    // -------------------------------
    // DUT Instances
    // -------------------------------
    // Convolution
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

    // 1-bit maxpool 2x2
    maxpool2x2_bin #(
        .IN_WIDTH(IMG_WIDTH - KERNEL_SIZE + 1),
        .IN_HEIGHT(IMG_HEIGHT - KERNEL_SIZE + 1)
    ) pool_inst (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_out),
        .pixel_in(bin_out),
        .pixel_out(pool_out),
        .valid_out(pool_valid)
    );

    // -------------------------------
    // Clock
    // -------------------------------
    initial clk = 0;
    always #5 clk = ~clk; // 10ns period

    // -------------------------------
    // Image memory
    // -------------------------------
    reg [IMG_WIDTH*IMG_HEIGHT-1:0] image_bits;

    // Coordinates
    integer r, c;

    // Output arrays
    localparam OUT_ROWS = IMG_HEIGHT - KERNEL_SIZE + 1; // 26
    localparam OUT_COLS = IMG_WIDTH - KERNEL_SIZE + 1;  // 26
    reg bin_image [0:OUT_ROWS-1][0:OUT_COLS-1];

    localparam POOL_ROWS = OUT_ROWS / 2; // 13
    localparam POOL_COLS = OUT_COLS / 2; // 13
    reg pooled_image [0:POOL_ROWS-1][0:POOL_COLS-1];

    // File handles
    integer fd;

    // Track indices
    integer conv_row, conv_col;
    integer pool_row, pool_col;

    // -------------------------------
    // Testbench sequence
    // -------------------------------
    initial begin
        // Reset and initialize
        reset = 1;
        pixel_in = 0;
        valid_in = 0;
        weight_bits = 9'b111111111; // example kernel
        conv_row = 0; conv_col = 0;
        pool_row = 0; pool_col = 0;

        // Example 28x28 flattened image
        // Replace with your image data
        image_bits = 784'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100000000000000000000000011111000000000000000000000011111100000000000000000000011111011000000000000000000111111101110000000000000000011110110011000000000000000011110000001100000000000000011110000000111000000000000011100000000011100000000000001100000000001110000000000001110000000000111000000000000110000000000011100000000000011000000000011100000000000001100000000011100000000000000110000000011100000000000000011000000011100000000000000001110001111100000000000000000111111111100000000000000000011111111000000000000000000000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;

        #20 reset = 0;

        // Stream pixels
        valid_in = 1;
        for (r = 0; r < IMG_HEIGHT; r = r + 1)
            for (c = 0; c < IMG_WIDTH; c = c + 1) begin
                pixel_in = image_bits[r*IMG_WIDTH + c];
                #10;
            end
        valid_in = 0;

        // Wait extra cycles for pipeline to drain
        #500;

        // Dump binarized image
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

        // Dump pooled image
        fd = $fopen("pooled_output.csv","w");
        for (r = 0; r < POOL_ROWS; r = r + 1) begin
            for (c = 0; c < POOL_COLS; c = c + 1) begin
                $fwrite(fd, "%0d", pooled_image[r][c]);
                if (c != POOL_COLS-1) $fwrite(fd, ",");
            end
            $fwrite(fd, "\n");
        end
        $fclose(fd);
        $display("Pooled image CSV saved as pooled_output.csv");

        $finish;
    end

    // -------------------------------
    // Capture binarized output
    // -------------------------------
    always @(posedge clk) begin
        if (reset) begin
            conv_row <= 0; conv_col <= 0;
        end else if (valid_out) begin
            bin_image[conv_row][conv_col] <= bin_out;
            if (conv_col == OUT_COLS-1) begin
                conv_col <= 0;
                conv_row <= conv_row + 1;
            end else conv_col <= conv_col + 1;
        end
    end

    // -------------------------------
    // Capture pooled output
    // -------------------------------
    always @(posedge clk) begin
        if (reset) begin
            pool_row <= 0; pool_col <= 0;
        end else if (pool_valid) begin
            pooled_image[pool_row][pool_col] <= pool_out;
            if (pool_col == POOL_COLS-1) begin
                pool_col <= 0;
                pool_row <= pool_row + 1;
            end else pool_col <= pool_col + 1;
        end
    end

endmodule

