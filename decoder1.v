module PositDecoder_8_2_F0_uid4 #(parameter N=8)(
    input [N-1:0] X,        // 8-bit posit input
    output Sign,          // Sign bit
    output [log2(N)+2:0] SF,      // Scale factor (regime + exponent)
    output [N-6:0] Frac,    // Fraction bits
    output NZN            // Not Zero / Not NaR flag
);
    // Internal signals
    wire sgn;
    wire pNZN;
    wire rc;
    wire [N-3:0] regPosit;
    wire [log2(N)-1:0] regLength;
    wire [N-3:0] shiftedPosit;
    wire [log2(N):0] k;
    wire [1:0] sgnVect;
    wire [1:0] exp;
    wire [log2(N)+2:0] pSF;
    wire [N-6:0] pFrac;

function integer log2;
   input integer N;
   log2 = (N <= 8)  ? 3 :
          (N <= 16) ? 4 :
          (N <= 32)? 5 : 6;  // For N=64
endfunction

    //---------------------------
    // Sign bit & special cases
    //---------------------------
    assign sgn = X[N-1];  // MSB is sign bit
    assign pNZN = (X[N-2:0] == {(N-1){1'b0}}) ? 1'b0 : 1'b1;  // Zero/NaR detection

    //---------------------------
    // Regime processing
    //---------------------------
    assign rc = X[N-2];           // Regime sign bit
    assign regPosit = X[N-3:0];  // Remaining bits for regime processing

    // Instantiate normalizer (implementation not shown here)
    Normalizer_ZO_6_6_6_F0_uid6 #(.N(N)) regime_counter (
        .X(regPosit),
        .OZb(rc),
        .Count(regLength),
        .R(shiftedPosit)
    );

    //---------------------------
    // Scale factor calculation
    //---------------------------
    assign k = (rc != sgn) ? {1'b0, regLength} : {1'b1, ~regLength};
    assign sgnVect = {2{sgn}};
    assign exp = shiftedPosit[N-4:N-5] ^ sgnVect;
    assign pSF = {k, exp};

    //---------------------------
    // Fraction extraction
    //---------------------------
    assign pFrac = shiftedPosit[N-6:0];

    //---------------------------
    // Output assignments
    //---------------------------
    assign Sign = sgn;
    assign SF = pSF;
    assign Frac = pFrac;
    assign NZN = pNZN;

endmodule

