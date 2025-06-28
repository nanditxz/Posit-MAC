`timescale 1ns / 1ps

module brent_kung_adder #(
    parameter N = 128  // Bit-width (must be power of 2)
) (
    input  [N-1:0] a,
    input  [N-1:0] b,
    input           cin,
    output [N-1:0] sum,
    output          cout
);

function integer log2;
   input integer N;
   log2 = (N <= 8)  ? 3 :
          (N <= 16) ? 4 :
          (N <= 32)? 5 : 6;  // For N=64
endfunction

    // Total stages = 2*log2(N) - 1
    localparam S = log2(N);
    localparam TOTAL_STAGES = 2*S - 1;
    
    // Propagate/Generate signals matrix
    wire [N-1:0] P [0:TOTAL_STAGES];
    wire [N-1:0] G [0:TOTAL_STAGES];
    
    // Final carries
    wire [N:0] carry;

    // Stage 0: Pre-processing
    assign P[0] = a ^ b;          // Propagate bits
    assign G[0] = a & b;           // Generate bits
    assign carry[0] = cin;         // Carry-in

    // Prefix tree computation
generate
    genvar stage, bit;
    
    // Forward phase (log2N stages: 1 to S)
    for(stage=1; stage<=S; stage=stage+1) begin : forward_phase
        for(bit=0; bit<N; bit=bit+1) begin : bit_processing_fw
            if(bit % (2**stage) == (2**stage - 1)) begin : gen_combine
                assign P[stage][bit] = P[stage-1][bit] & 
                                      P[stage-1][bit - 2**(stage-1)];
                assign G[stage][bit] = G[stage-1][bit] | 
                                      (P[stage-1][bit] & 
                                      G[stage-1][bit - 2**(stage-1)]);
            end else begin : gen_copy
                assign P[stage][bit] = P[stage-1][bit];
                assign G[stage][bit] = G[stage-1][bit];
            end
        end
    end
    
    // Backward phase (S-1 stages: S+1 to 2*S-1)
    for(stage=S+1; stage<=TOTAL_STAGES; stage=stage+1) begin : backward_phase
        for(bit=0; bit<N; bit=bit+1) begin : bit_processing_bw
            localparam OFFSET = 2**(TOTAL_STAGES-stage+1);
            if((bit >= OFFSET) && ((bit-OFFSET) % (2*OFFSET) == (2*OFFSET-1))) begin : gen_if
                assign P[stage][bit] = P[stage-1][bit] & P[stage-1][bit-OFFSET];
                assign G[stage][bit] = G[stage-1][bit] | (P[stage-1][bit] & G[stage-1][bit-OFFSET]);
            end else begin : gen_else
                assign P[stage][bit] = P[stage-1][bit];
                assign G[stage][bit] = G[stage-1][bit];
            end
        end
    end
endgenerate

    // Carry computation
    generate
        for(genvar i=0; i<N; i=i+1) begin : carry_gen
            assign carry[i+1] = G[TOTAL_STAGES-1][i] | 
                                (P[TOTAL_STAGES-1][i] & carry[i]);
        end
    endgenerate

    // Sum computation
    assign sum = P[0] ^ carry[N-1:0];
    assign cout = carry[N];

endmodule

