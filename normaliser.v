`timescale 1ns / 1ps

module Normalizer_ZO_6_6_6_F0_uid6 #(
    parameter N = 8  // Supported: 8, 16, 32, 64
)(
    input [N-3:0] X,
    input OZb,
    output reg [log2(N)-1:0] Count,  // Shift count (6-bit max for N=64)
    output reg [N-3:0] R      // Shifted result
);

function integer log2;
   input integer N;
   log2 = (N <= 8)  ? 3 :
          (N <= 16) ? 4 :
          (N <= 32) ? 5 : 6;  // N=64
endfunction

    // Internal signals
    wire sozb = OZb;
    reg [N-3:0] level0, level1, level2, level3, level4, level5, level6;
    reg count0, count1, count2, count3, count4, count5;
    
    // Initialize the pipeline
    always @(*) begin
        level6 = X;
        
        // Stage5: 32-bit check (only for N=64)
        if (N == 64) begin
            count5 = (level6[61:30] == {32{sozb}});
            level5 = count5 ? {level6[29:0], 32'b0} : level6;
        end else begin
            count5 = 0;
            level5 = level6;
        end
        
        // Stage4: 16-bit check (for N=32 and N=64)
        if (N == 32 || N == 64) begin
            count4 = (level5[N-3:N-18] == {16{sozb}});  // [61:46] for N=64
            level4 = count4 ? {level5[N-19:0], 16'b0} : level5;  // [45:0] for N=64
        end else begin
            count4 = 0;
            level4 = level5;
        end
        
        // Stage3: 8-bit check (for N>=16)
        if (N >= 16) begin
            count3 = (level4[N-3:N-10] == {8{sozb}});  // [61:54] for N=64
            level3 = count3 ? {level4[N-11:0], 8'b0} : level4;  // [53:0] for N=64
        end else begin
            count3 = 0;
            level3 = level4;
        end
        
        // Stage2: 4-bit check (for all N)
        count2 = (level3[N-3:N-6] == {4{sozb}});  // [61:58] for N=64
        level2 = count2 ? {level3[N-7:0], 4'b0} : level3;  // [57:0] for N=64
        
        // Stage1: 2-bit check (for all N)
        count1 = (level2[N-3:N-4] == {2{sozb}});  // [61:60] for N=64
        level1 = count1 ? {level2[N-5:0], 2'b0} : level2;  // [59:0] for N=64
        
        // Stage0: 1-bit check (for all N)
        count0 = (level1[N-3] == sozb);  // [61] for N=64
        level0 = count0 ? {level1[N-4:0], 1'b0} : level1;  // [60:0] for N=64
    end

    // Final output assignments
    always @(*) begin
        R = level0;
        // Count concatenation based on input size
        case(N)
            64: Count = {count5, count4, count3, count2, count1, count0};  // 6-bit count
            32: Count = {count4, count3, count2, count1, count0};
            16: Count = {count3, count2, count1, count0};
            8:  Count = {count2, count1, count0};
            default: Count = 0;
        endcase
    end
endmodule
