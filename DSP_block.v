`timescale 1ns / 1ps

module DSPBlock_5x5_F0_uid16 #(parameter N =4)(
    input signed [N-1:0] X,
    input signed [N-1:0] Y,
    output signed [2*N-1:0] R
);
    // Behavioral implementation of 5x5 multiplier
    assign R = X * Y;

    // Internal signals
    wire [2*N-1:0] Mint; // Intermediate product (full 10-bit result)
    wire [2*N-1:0] M;    // Truncated product (10-bit)
    wire [2*N-1:0] Rtmp; // Output buffer

    // Signed multiplication: X * Y
    assign Mint = X * Y;
    
    // Take the 10 least significant bits of the product
    assign M = Mint[2*N-1:0];
    
    // Buffer the result
    assign Rtmp = M;
    
    // Final output assignment
    assign R = Rtmp;
endmodule

