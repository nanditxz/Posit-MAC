`timescale 1ns / 1ps

module IntAdder_7_F0_uid19 #(parameter N =6)(
    input [N:0] X,      
    input [N:0] Y,      
    input Cin,           
    output [N:0] R      
);
 
    assign R = X + Y + Cin;
   
endmodule

