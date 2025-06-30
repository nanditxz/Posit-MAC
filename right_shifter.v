`timescale 1ns / 1ps

module RightShifter56_by_max_48_F0_uid26 #(
    parameter N = 8,
    parameter DATA_WIDTH = 56,        // Input/output width
    parameter SHIFT_BITS = 6,         // Number of shift control bits
    parameter MAX_SHIFT = 48
    )(
    input [DATA_WIDTH-1:0] X,
    input [SHIFT_BITS-1:0] S,
    input padBit,
    output reg[DATA_WIDTH-1:0] R
);
    // Replicate fill_bit (shift_amount times) and concatenate with preserved MSBs
   // assign R = (X >> S) | ({DATA_WIDTH{padBit}} << (DATA_WIDTH - S));
   // assign R = { {S{padBit}}, X[DATA_WIDTH-1:S] };

   /* integer i;  // Moved outside

    always @(*) begin
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin
            if (i + S < DATA_WIDTH)
                R[i] = X[i + S];
            else
                R[i] = padBit;
        end
    end */
    
    reg [10*N-25:0] level0, level1, level2, level3, level4, level5, level6, level7, level8, level9;

always @(*) begin
    // Initialize with input (padded to output width)
    level0 = {{(10*N-24 - N){padBit}}, X};

    // Stage 0: 1 bit
    level1 = S[0] ? {padBit, level0[10*N-25:1]} : level0;

    // Stage 1: 2 bits
    level2 = S[1] ? {{2{padBit}}, level1[10*N-25:2]} : level1;

    // Stage 2: 4 bits
    level3 = S[2] ? {{4{padBit}}, level2[10*N-25:4]} : level2;

    // Stage 3: 8 bits
    level4 = S[3] ? {{8{padBit}}, level3[10*N-25:8]} : level3;

    // Stage 4: 16 bits
    level5 = S[4] ? {{16{padBit}}, level4[10*N-25:16]} : level4;

    // Stage 5: 32 bits
    level6 = S[5] ? {{32{padBit}}, level5[10*N-25:32]} : level5;

    // Stage 6: 64 bits (only if N > 64)
    if (N >= 16) begin
        level7 = S[6] ? {{64{padBit}}, level6[10*N-25:64]} : level6;
    end else begin
        level7 = level6;
    end

    // Stage 7: 128 bits (only if N > 128)
    if (N >= 32) begin
        level8 = S[7] ? {{128{padBit}}, level7[10*N-25:128]} : level7;
    end else begin
        level8 = level7;
    end
    
    // Stage 8
    if (N >= 64) begin
        level9 = S[8] ? {{256{padBit}}, level8[10*N-25:256]} : level8;
    end else begin
        level9 = level8;
    end

    // Output
    R = level9;
    
end
endmodule


