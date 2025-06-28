`timescale 1ns / 1ps

module RightShifter56_by_max_48_F0_uid26 #(
    parameter DATA_WIDTH = 56,        // Input/output width
    parameter SHIFT_BITS = 6,         // Number of shift control bits
    parameter MAX_SHIFT = 48
    )(
    input [DATA_WIDTH-1:0] X,
    input [SHIFT_BITS-1:0] S,
    input padBit,
    output [DATA_WIDTH-1:0] R
);
    // Replicate fill_bit (shift_amount times) and concatenate with preserved MSBs
    assign R = (X >> S) | ({DATA_WIDTH{padBit}} << (DATA_WIDTH - S));
endmodule


