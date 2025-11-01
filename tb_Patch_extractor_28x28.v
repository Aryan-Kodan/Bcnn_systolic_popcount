`timescale 1ns / 1ps

module tb_patch_extractor_28x28;

    // Parameters
    parameter IMG_WIDTH   = 28;
    parameter IMG_HEIGHT  = 28;
    parameter KERNEL_SIZE = 3;

    localparam PATCH_SIZE = KERNEL_SIZE*KERNEL_SIZE;

    // Testbench signals
    reg clk;
    reg reset;
    reg pixel_in;
    reg valid_in;
    wire [PATCH_SIZE-1:0] patch_out;
    wire valid_out;

    // Instantiate the patch extractor
    patch_extractor_28x28 #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .pixel_in(pixel_in),
        .valid_in(valid_in),
        .patch_out(patch_out),
        .valid_out(valid_out)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Generate a test image (28×28 bits)
    reg [IMG_WIDTH*IMG_HEIGHT-1:0] image_bits;
    integer i, row, col;

    initial begin
        // Initialize image with a simple pattern
        // e.g., pixel = 1 when row<14 and col<14 else 0
        for (row = 0; row < IMG_HEIGHT; row = row + 1) begin
            for (col = 0; col < IMG_WIDTH; col = col + 1) begin
                if ((row < 14) && (col < 14))
                    image_bits[row*IMG_WIDTH + col] = 1'b1;
                else
                    image_bits[row*IMG_WIDTH + col] = 1'b0;
            end
        end

        // Reset
        reset = 1;
        valid_in = 0;
        pixel_in = 0;
        #20;
        reset = 0;

        // Feed pixels one by one
        for (i = 0; i < IMG_WIDTH*IMG_HEIGHT; i = i + 1) begin
            @(posedge clk);
            valid_in <= 1'b1;
            pixel_in <= image_bits[i];
        end

        // End input
        @(posedge clk);
        valid_in <= 0;
        pixel_in <= 0;

        // Wait a few clocks
        #100;

        $finish;
    end

    // Monitor output patches
    always @(posedge clk) begin
        if (valid_out) begin
            $display("Time=%0t : Patch (3x3) at pixel stream index %0d:", $time, i);
            $display("Row0: %b%b%b", patch_out[2], patch_out[1], patch_out[0]);
            $display("Row1: %b%b%b", patch_out[5], patch_out[4], patch_out[3]);
            $display("Row2: %b%b%b", patch_out[8], patch_out[7], patch_out[6]);
            $display("---------------------------");
        end
    end

endmodule

