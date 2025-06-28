module PositMAC #(parameter N = 32)(
    input [N-1:0] A,
    input [N-1:0] B,
    input [16*N-1:0] C,
    output [16*N-1:0] R
);

    // Internal signals
    wire A_sgn;
    wire [log2(N)+2:0] A_sf;
    wire [N-6:0] A_f;
    wire A_nzn;
    wire B_sgn;
    wire [log2(N)+2:0] B_sf;
    wire [N-6:0] B_f;
    wire B_nzn;
    wire AB_nzn;
    wire AB_nar;
    wire [N-4:0] AA_f;
    wire [N-4:0] BB_f;
    wire [2*N-7:0] AB_f;
    wire AB_sgn;
    wire AB_ovfExtra;
    wire AB_ovf;
    wire [2*N-10:0] AB_normF;
    wire [log2(N)+3:0] AA_sf;
    wire [log2(N)+3:0] BB_sf;
    wire [log2(N)+3:0] AB_sf_tmp;
    wire [log2(N)+3:0] AB_sf;
    wire neg_sf;
    wire [log2(N)+2:0] AB_effectiveSF;
    wire [log2(N)+2:0] adderInput;
    wire [log2(N)+2:0] adderBias;
    wire ob;
    wire [10*N-25:0] paddedFrac;
    wire [10*N-25:0] fixedPosit;
    wire [16*N-32:0] quirePosit;
    wire [16*N-1:0] AB_quire;
    wire zb;
    wire [16*N-1:0] ABC_add;
    wire [16*N-2:0] zeros;
    wire C_nar;
    wire ABC_nar;
    wire [16*N-1:0] result;
    wire [log2(N)+2:0] AB_sfBiased;

function integer log2;
   input integer N;
   log2 = (N <= 8)  ? 3 :
          (N <= 16) ? 4 :
          (N <= 32)? 5 : 6; 
endfunction

    // Decode A & B operands
    PositDecoder_8_2_F0_uid4 #(.N(N)) A_decoder(
        .X(A),
        .Sign(A_sgn),
        .SF(A_sf),
        .Frac(A_f),
        .NZN(A_nzn)
    );

    PositDecoder_8_2_F0_uid4 #(.N(N)) B_decoder(
        .X(B),
        .Sign(B_sgn),
        .SF(B_sf),
        .Frac(B_f),
        .NZN(B_nzn)
    );

    // Multiply A & B fractions
    assign AB_nzn = A_nzn & B_nzn;
    assign AB_nar = (A_sgn & ~A_nzn) | (B_sgn & ~B_nzn);

    assign AA_f = {A_sgn, ~A_sgn, A_f};
    assign BB_f = {B_sgn, ~B_sgn, B_f};

    IntMultiplier_F0_uid12 #(.N(N-3)) FracMultiplier(
        .X(AA_f),
        .Y(BB_f),
        .R(AB_f)
    );

    assign AB_sgn = AB_f[2*N-7];
    assign AB_ovfExtra = ~AB_sgn & AB_f[2*N-8];
    assign AB_ovf = AB_ovfExtra | (AB_sgn ^ AB_f[2*N-9]);
    assign AB_normF = AB_ovf ? AB_f[2*N-10:0] : {AB_f[2*N-11:0], 1'b0};

    // Add exponent values
    assign AA_sf = {A_sf[log2(N)+2], A_sf};
    assign BB_sf = {B_sf[log2(N)+2], B_sf};

    IntAdder_7_F0_uid19 #(.N(log2(N)+3))SFAdder(
        .Cin(AB_ovfExtra),
        .X(AA_sf),
        .Y(BB_sf),
        .R(AB_sf_tmp)
    );

    IntAdder_7_F0_uid19 #(.N(log2(N)+3))RoundingAdder(
        .Cin(AB_ovf),
        .X(AB_sf_tmp),
        .Y({(log2(N)+4){1'b0}}),
        .R(AB_sf)
    );

    // Shift AB fraction into quire format
    assign neg_sf = AB_sf[log2(N)+3];
    assign AB_effectiveSF = AB_sf[log2(N)+2:0];
    assign adderInput = ~AB_effectiveSF;
    assign adderBias = neg_sf ? {(log2(N)+3){1'b1}} : {{(log2(N)-1){1'b1}},{4'b0000}};
    assign ob = 1'b1;

    IntAdder_7_F0_uid19 #(.N(log2(N)+2))BiasedSFAdder(
        .Cin(ob),
        .X(adderInput),
        .Y(adderBias),
        .R(AB_sfBiased)
    );

    assign paddedFrac = neg_sf ? {{(2*N-8){AB_sgn}}, ~AB_sgn, AB_normF, {(6*N-8){1'b0}}} : {~AB_sgn, AB_normF, {(8*N-16){1'b0}}};

    RightShifter56_by_max_48_F0_uid26 #(.DATA_WIDTH(10*N-24), .SHIFT_BITS(log2(N)+3), .MAX_SHIFT(8*N-16)) Frac_RightShifter (
        .S(AB_sfBiased),
        .X(paddedFrac),
        .padBit(AB_sgn),
        .R(fixedPosit)
    );

    assign quirePosit = neg_sf ? {{(6*N-7){AB_sgn}}, fixedPosit} : {fixedPosit, {(6*N-7){1'b0}}};
    assign AB_quire = AB_nzn ? {{31{AB_sgn}}, quirePosit} : {AB_nar, {(16*N-1){1'b0}}};

    // Add quires
    assign zb = 1'b0;

    brent_kung_adder #(.N(16*N)) QuireAdder(
        .a(C),
        .b(AB_quire),
        .cin(zb),
        .sum(ABC_add),
        .cout()
    );

    assign zeros = {(16*N-1){1'b0}};
    assign C_nar = (C[16*N-2:0] == zeros) & C[16*N-1];
    assign ABC_nar = AB_nar | C_nar;
    assign result = ABC_nar ? {1'b1, zeros} : ABC_add;

    assign R = result;
endmodule
