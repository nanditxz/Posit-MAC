`timescale 1ns / 1ps

module brent_kung_adder #(
    parameter N = 128  // Bit-width (power of 2)
) (
    input  [N-1:0] a,
    input  [N-1:0] b,
    input           cin,
    output [N-1:0] sum,
    output          cout
);

// Improved recursive log2 function
function integer log2;
    input integer n;
    begin
        log2 = 0;
        while (2**log2 < n) log2 = log2 + 1;
    end
endfunction

localparam S = log2(N);
localparam TOTAL_STAGES = 2*S - 1;

// Propagate/Generate signals
wire [N-1:0] P [0:TOTAL_STAGES];
wire [N-1:0] G [0:TOTAL_STAGES];
wire [N:0]   carry;

// Stage 0: Pre-processing
assign P[0] = a ^ b;
assign G[0] = a & b;
assign carry[0] = cin;

// Optimized prefix tree
generate
    genvar stage, bit;
    
    // Forward phase (stages 1 to S)
    for (stage = 1; stage <= S; stage = stage + 1) begin : forward
        localparam step = (1 << (stage-1));  // 2^(stage-1)
        
        for (bit = 0; bit < N; bit = bit + 1) begin : fw_stage
            if ((bit >= (2*step - 1)) && (((bit+1) & ((2*step)-1)) == 0)) begin
                // Combine blocks
                assign P[stage][bit] = P[stage-1][bit] & P[stage-1][bit-step];
                assign G[stage][bit] = G[stage-1][bit] | (P[stage-1][bit] & G[stage-1][bit-step]);
            end else begin
                // Direct propagation
                assign P[stage][bit] = P[stage-1][bit];
                assign G[stage][bit] = G[stage-1][bit];
            end
        end
    end
    
    // Backward phase (stages S+1 to TOTAL_STAGES)
    for (stage = S+1; stage <= TOTAL_STAGES; stage = stage + 1) begin : backward
        localparam step_size = (1 << (2*S - stage));  // 2^(2S-stage)
        
        for (bit = 0; bit < N; bit = bit + 1) begin : bw_stage
            if ((bit >= (3*step_size - 1)) && 
                (((bit - step_size + 1) & (2*step_size - 1)) == 0)) begin
                // Combine blocks
                assign P[stage][bit] = P[stage-1][bit] & P[stage-1][bit-step_size];
                assign G[stage][bit] = G[stage-1][bit] | (P[stage-1][bit] & G[stage-1][bit-step_size]);
            end else begin
                // Direct propagation
                assign P[stage][bit] = P[stage-1][bit];
                assign G[stage][bit] = G[stage-1][bit];
            end
        end
    end

    // Carry computation optimization
    for (genvar i = 0; i < N; i = i + 1) begin : carry_gen
        assign carry[i+1] = G[TOTAL_STAGES][i];
    end
endgenerate

// Final outputs
assign sum = P[0] ^ carry[N-1:0];
assign cout = carry[N];
endmodule

