`timescale 1ns / 1ps

module tb_bcnn_2layer;

    localparam IMG_WIDTH1   = 28;
    localparam IMG_HEIGHT1  = 28;
    localparam KERNEL_SIZE  = 3;
    localparam SUM_WIDTH    = 4;
    localparam THRESHOLD1   = 3;
    localparam THRESHOLD2   = 3;

    reg clk;
    reg reset;

    reg pixel_in;
    reg valid_in;
    reg [KERNEL_SIZE*KERNEL_SIZE-1:0] weight_bits1;
    reg [KERNEL_SIZE*KERNEL_SIZE-1:0] weight_bits2;

    wire [SUM_WIDTH-1:0] popcount1;
    wire valid_out1;
    wire bin_out1;
    wire pool_out;
    wire pool_valid;

    wire [SUM_WIDTH-1:0] popcount2;
    wire valid_out2;
    wire bin_out2;

    bcnn_conv3x3_top #(
        .IMG_WIDTH(IMG_WIDTH1),
        .IMG_HEIGHT(IMG_HEIGHT1),
        .KERNEL_SIZE(KERNEL_SIZE),
        .SUM_WIDTH(SUM_WIDTH)
    ) conv1_inst (
        .clk(clk),
        .reset(reset),
        .pixel_in(pixel_in),
        .valid_in(valid_in),
        .weight_bits(weight_bits1),
        .popcount(popcount1),
        .valid_out(valid_out1)
    );

    binarizer #(
        .WIDTH(SUM_WIDTH),
        .THRESHOLD(THRESHOLD1)
    ) bin1_inst (
        .clk(clk),
        .reset(reset),
        .in(popcount1),
        .out(bin_out1)
    );

    maxpool2x2_bin #(
        .IN_WIDTH(IMG_WIDTH1 - KERNEL_SIZE + 1),
        .IN_HEIGHT(IMG_HEIGHT1 - KERNEL_SIZE + 1)
    ) pool_inst (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_out1),
        .pixel_in(bin_out1),
        .pixel_out(pool_out),
        .valid_out(pool_valid)
    );

    bcnn_conv3x3_layer2 #(
        .IMG_WIDTH((IMG_WIDTH1 - KERNEL_SIZE + 1)/2),
        .IMG_HEIGHT((IMG_HEIGHT1 - KERNEL_SIZE + 1)/2),
        .KERNEL_SIZE(KERNEL_SIZE),
        .SUM_WIDTH(SUM_WIDTH)
    ) conv2_inst (
        .clk(clk),
        .reset(reset),
        .pixel_in(pool_out),
        .valid_in(pool_valid),
        .weight_bits(weight_bits2),
        .popcount(popcount2),
        .valid_out(valid_out2)
    );

    binarizer #(
        .WIDTH(SUM_WIDTH),
        .THRESHOLD(THRESHOLD2)
    ) bin2_inst (
        .clk(clk),
        .reset(reset),
        .in(popcount2),
        .out(bin_out2)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    reg [IMG_WIDTH1*IMG_HEIGHT1-1:0] image_bits;
    integer r, c;
    integer fd;
    integer conv1_row, conv1_col;
    integer pool_row, pool_col;
    integer conv2_row, conv2_col;

    localparam OUT1_ROWS = IMG_HEIGHT1 - KERNEL_SIZE + 1;
    localparam OUT1_COLS = IMG_WIDTH1 - KERNEL_SIZE + 1;
    localparam POOL_ROWS = OUT1_ROWS / 2;
    localparam POOL_COLS = OUT1_COLS / 2;
    localparam OUT2_ROWS = POOL_ROWS - KERNEL_SIZE + 1;
    localparam OUT2_COLS = POOL_COLS - KERNEL_SIZE + 1;

    reg bin_image1 [0:OUT1_ROWS-1][0:OUT1_COLS-1];
    reg pooled_image [0:POOL_ROWS-1][0:POOL_COLS-1];
    reg bin_image2 [0:OUT2_ROWS-1][0:OUT2_COLS-1];

    initial begin
        reset = 1;
        pixel_in = 0;
        valid_in = 0;
        weight_bits1 = 9'b111111111;
        weight_bits2 = 9'b111111111;
        conv1_row = 0; conv1_col = 0;
        pool_row = 0; pool_col = 0;
        conv2_row = 0; conv2_col = 0;

        image_bits = 784'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100000000000000000000000011111000000000000000000000011111100000000000000000000011111011000000000000000000111111101110000000000000000011110110011000000000000000011110000001100000000000000011110000000111000000000000011100000000011100000000000001100000000001110000000000001110000000000111000000000000110000000000011100000000000011000000000011100000000000001100000000011100000000000000110000000011100000000000000011000000011100000000000000001110001111100000000000000000111111111100000000000000000011111111000000000000000000000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;

        #20 reset = 0;
        valid_in = 1;

        for (r = 0; r < IMG_HEIGHT1; r = r + 1)
            for (c = 0; c < IMG_WIDTH1; c = c + 1) begin
                pixel_in = image_bits[r*IMG_WIDTH1 + c];
                #10;
            end
        valid_in = 0;

        #1000;

        fd = $fopen("layer1_pooled_output.csv","w");
        for (r = 0; r < POOL_ROWS; r = r + 1) begin
            for (c = 0; c < POOL_COLS; c = c + 1) begin
                $fwrite(fd, "%0d", pooled_image[r][c]);
                if (c != POOL_COLS-1) $fwrite(fd, ",");
            end
            $fwrite(fd, "\n");
        end
        $fclose(fd);
        $display("Layer 1 pooled output saved as layer1_pooled_output.csv");

        fd = $fopen("layer2_binarized_output.csv","w");
        for (r = 0; r < OUT2_ROWS; r = r + 1) begin
            for (c = 0; c < OUT2_COLS; c = c + 1) begin
                $fwrite(fd, "%0d", bin_image2[r][c]);
                if (c != OUT2_COLS-1) $fwrite(fd, ",");
            end
            $fwrite(fd, "\n");
        end
        $fclose(fd);
        $display("Layer 2 binarized output saved as layer2_binarized_output.csv");

        $finish;
    end

    always @(posedge clk) begin
        if (reset) begin
            conv1_row <= 0; conv1_col <= 0;
        end else if (valid_out1) begin
            bin_image1[conv1_row][conv1_col] <= bin_out1;
            if (conv1_col == OUT1_COLS-1) begin
                conv1_col <= 0;
                conv1_row <= conv1_row + 1;
            end else conv1_col <= conv1_col + 1;
        end
    end

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

    always @(posedge clk) begin
        if (reset) begin
            conv2_row <= 0; conv2_col <= 0;
        end else if (valid_out2) begin
            bin_image2[conv2_row][conv2_col] <= bin_out2;
            if (conv2_col == OUT2_COLS-1) begin
                conv2_col <= 0;
                conv2_row <= conv2_row + 1;
            end else conv2_col <= conv2_col + 1;
        end
    end
endmodule

