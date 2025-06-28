`timescale 1ns / 1ps

module IntMultiplier_F0_uid12 #(parameter N =5)(
    input [N-1:0] X,
    input [N-1:0] Y,
    output [2*N-1:0] R
);
    // Internal signals with parameterized widths
    wire [N-1:0] tile_0_X = X;
    wire [N-1:0] tile_0_Y = Y;
    wire [2*N-1:0] tile_0_output;
    
    // Bit-level decomposition and reassembly
    wire [2*N-1:0] bitheapResult_bh14;
    generate
        genvar i;
        for (i = 0; i < 2*N; i = i+1) begin: bit_reassembly
            assign bitheapResult_bh14[i] = tile_0_output[i];
        end
    endgenerate
    
    // Result assembly
 /*   wire [2*N-1:0] tmp_bitheapResult_bh14_9 = {
        bh14_w9_0, bh14_w8_0, bh14_w7_0, 
        bh14_w6_0, bh14_w5_0, bh14_w4_0, 
        bh14_w3_0, bh14_w2_0, bh14_w1_0, 
        bh14_w0_0
    };
    wire [9:0] bitheapResult_bh14 = tmp_bitheapResult_bh14_9; */
    
    // DSP block instantiation
    DSPBlock_5x5_F0_uid16 #(.N(N)) tile_0_mult (
        .X(tile_0_X),
        .Y(tile_0_Y),
        .R(tile_0_output)
    );
    
    // Final output
    assign R = bitheapResult_bh14;
endmodule

