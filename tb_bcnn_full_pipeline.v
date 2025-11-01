`timescale 1ns / 1ps

module tb_bcnn_full_pipeline;

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
    wire pool1_out;
    wire pool1_valid;
    wire [SUM_WIDTH-1:0] popcount2;
    wire valid_out2;
    wire bin_out2;
    wire pool2_out;
    wire pool2_valid;

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
    ) pool1_inst (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_out1),
        .pixel_in(bin_out1),
        .pixel_out(pool1_out),
        .valid_out(pool1_valid)
    );

    bcnn_conv3x3_top #(
        .IMG_WIDTH((IMG_WIDTH1 - KERNEL_SIZE + 1)/2),
        .IMG_HEIGHT((IMG_HEIGHT1 - KERNEL_SIZE + 1)/2),
        .KERNEL_SIZE(KERNEL_SIZE),
        .SUM_WIDTH(SUM_WIDTH)
    ) conv2_inst (
        .clk(clk),
        .reset(reset),
        .pixel_in(pool1_out),
        .valid_in(pool1_valid),
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

    maxpool2x2_bin #(
        .IN_WIDTH(((IMG_WIDTH1 - KERNEL_SIZE + 1)/2) - KERNEL_SIZE + 1),
        .IN_HEIGHT(((IMG_HEIGHT1 - KERNEL_SIZE + 1)/2) - KERNEL_SIZE + 1)
    ) pool2_inst (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_out2),
        .pixel_in(bin_out2),
        .pixel_out(pool2_out),
        .valid_out(pool2_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    reg [IMG_WIDTH1*IMG_HEIGHT1-1:0] image_bits;
    integer r, c, fd;
    integer conv1_row, conv1_col;
    integer pool1_row, pool1_col;
    integer conv2_row, conv2_col;
    integer pool2_row, pool2_col;

    localparam OUT1_ROWS = IMG_HEIGHT1 - KERNEL_SIZE + 1;
    localparam OUT1_COLS = IMG_WIDTH1 - KERNEL_SIZE + 1;
    localparam POOL1_ROWS = OUT1_ROWS / 2;
    localparam POOL1_COLS = OUT1_COLS / 2;
    localparam OUT2_ROWS = POOL1_ROWS - KERNEL_SIZE + 1;
    localparam OUT2_COLS = POOL1_COLS - KERNEL_SIZE + 1;
    localparam POOL2_ROWS = OUT2_ROWS / 2;
    localparam POOL2_COLS = OUT2_COLS / 2;

    reg bin_image1 [0:OUT1_ROWS-1][0:OUT1_COLS-1];
    reg pooled_image1 [0:POOL1_ROWS-1][0:POOL1_COLS-1];
    reg bin_image2 [0:OUT2_ROWS-1][0:OUT2_COLS-1];
    reg pooled_image2 [0:POOL2_ROWS-1][0:POOL2_COLS-1];

    initial begin
        reset = 1;
        pixel_in = 0;
        valid_in = 0;
        weight_bits1 = 9'b111111111;
        weight_bits2 = 9'b111111111;
        conv1_row = 0; conv1_col = 0;
        pool1_row = 0; pool1_col = 0;
        conv2_row = 0; conv2_col = 0;
        pool2_row = 0; pool2_col = 0;

        image_bits = 784'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000001000000000001000000000000001100000000001100000000000000110000000000110000000000000110000000000011000000000000011000000000001100000000000001100000000001100000000000001110000000000110000000000001110000000000011000000011111111000000000001111111111110001100000000000001111100000000110000000000000000000000000111000000000000000000000000011000000000000000000000000001100000000000000000000000000110000000000000000000000000011000000000000000000000000001110000000000000000000000000111000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;

        #20 reset = 0;
        valid_in = 1;
        for (r = 0; r < IMG_HEIGHT1; r = r + 1)
            for (c = 0; c < IMG_WIDTH1; c = c + 1) begin
                pixel_in = image_bits[r*IMG_WIDTH1 + c];
                #10;
            end
        valid_in = 0;
        #3000;

        fd = $fopen("layer1_conv_output.csv","w");
        for (r = 0; r < OUT1_ROWS; r = r + 1) begin
            for (c = 0; c < OUT1_COLS; c = c + 1) begin
                $fwrite(fd, "%0d", bin_image1[r][c]);
                if (c != OUT1_COLS-1) $fwrite(fd, ",");
            end
            $fwrite(fd, "\n");
        end
        $fclose(fd);

        fd = $fopen("layer1_pooled_output.csv","w");
        for (r = 0; r < POOL1_ROWS; r = r + 1) begin
            for (c = 0; c < POOL1_COLS; c = c + 1) begin
                $fwrite(fd, "%0d", pooled_image1[r][c]);
                if (c != POOL1_COLS-1) $fwrite(fd, ",");
            end
            $fwrite(fd, "\n");
        end
        $fclose(fd);

        fd = $fopen("layer2_conv_output.csv","w");
        for (r = 0; r < OUT2_ROWS; r = r + 1) begin
            for (c = 0; c < OUT2_COLS; c = c + 1) begin
                $fwrite(fd, "%0d", bin_image2[r][c]);
                if (c != OUT2_COLS-1) $fwrite(fd, ",");
            end
            $fwrite(fd, "\n");
        end
        $fclose(fd);

        fd = $fopen("layer2_pooled_output.csv","w");
        for (r = 0; r < POOL2_ROWS; r = r + 1) begin
            for (c = 0; c < POOL2_COLS; c = c + 1) begin
                $fwrite(fd, "%0d", pooled_image2[r][c]);
                if (c != POOL2_COLS-1) $fwrite(fd, ",");
            end
            $fwrite(fd, "\n");
        end
        $fclose(fd);

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
            pool1_row <= 0; pool1_col <= 0;
        end else if (pool1_valid) begin
            pooled_image1[pool1_row][pool1_col] <= pool1_out;
            if (pool1_col == POOL1_COLS-1) begin
                pool1_col <= 0;
                pool1_row <= pool1_row + 1;
            end else pool1_col <= pool1_col + 1;
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

    always @(posedge clk) begin
        if (reset) begin
            pool2_row <= 0; pool2_col <= 0;
        end else if (pool2_valid) begin
            pooled_image2[pool2_row][pool2_col] <= pool2_out;
            if (pool2_col == POOL2_COLS-1) begin
                pool2_col <= 0;
                pool2_row <= pool2_row + 1;
            end else pool2_col <= pool2_col + 1;
        end
    end
endmodule

