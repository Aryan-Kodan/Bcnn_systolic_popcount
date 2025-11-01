`timescale 1ns / 1ps

module bcnn_conv3x3_top #(
    parameter IMG_WIDTH   = 28,
    parameter IMG_HEIGHT  = 28,
    parameter KERNEL_SIZE = 3,
    parameter SUM_WIDTH   = 4
)(
    input  wire clk,
    input  wire reset,
    input  wire pixel_in,
    input  wire valid_in,
    input  wire [KERNEL_SIZE*KERNEL_SIZE-1:0] weight_bits,
    output wire [SUM_WIDTH-1:0] popcount,
    output wire valid_out
);

    wire [KERNEL_SIZE*KERNEL_SIZE-1:0] patch_bits;
    wire patch_valid;

    patch_extractor_28x28 #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) patch_extractor_inst (
        .clk(clk),
        .reset(reset),
        .pixel_in(pixel_in),
        .valid_in(valid_in),
        .patch_out(patch_bits),
        .valid_out(patch_valid)
    );

    systolic_chain_3x3 #(
        .SUM_WIDTH(SUM_WIDTH)
    ) systolic_chain_inst (
        .clk(clk),
        .reset(reset),
        .valid_in(patch_valid),
        .patch_bits(patch_bits),
        .weight_bits(weight_bits),
        .popcount(popcount),
        .valid_out(valid_out)
    );

endmodule

