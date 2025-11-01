`timescale 1ns / 1ps

module systolic_chain_3x3 #(
    parameter SUM_WIDTH = 4 // enough to hold sum up to 9
)(
    input  wire clk,
    input  wire reset,
    input  wire valid_in,
    input  wire [8:0] patch_bits,   // 9 bits from patch extractor
    input  wire [8:0] weight_bits,  // 9 bits kernel weights
    output wire [SUM_WIDTH-1:0] popcount, // full popcount at end of chain
    output wire valid_out
);

    // Partial sums between PEs
    wire [SUM_WIDTH-1:0] psum [0:9];
    wire [9:0] vld;

    assign psum[0] = {SUM_WIDTH{1'b0}}; // start with zero
    assign vld[0]  = valid_in;

    // 9 chained PEs
    genvar i;
    generate
        for (i = 0; i < 9; i = i + 1) begin : PE_CHAIN
            systolic_pe #(.SUM_WIDTH(SUM_WIDTH)) pe_inst (
                .clk(clk),
                .reset(reset),
                .valid_in(vld[i]),
                .in_bit(patch_bits[i]),
                .weight_bit(weight_bits[i]),
                .partial_sum_in(psum[i]),
                .partial_sum_out(psum[i+1]),
                .valid_out(vld[i+1])
            );
        end
    endgenerate

    assign popcount = psum[9]; // final sum
    assign valid_out = vld[9]; // final valid

endmodule

