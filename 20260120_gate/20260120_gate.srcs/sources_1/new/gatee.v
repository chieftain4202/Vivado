`timescale 1ns / 1ps


//top module
module gatee(

    input a,
    input b,

    output y0,
    output y1,
    output y2,
    output y3,
    output y4,
    output y5,
    output y6

);
    //AND gate
    assign y0 = a & b;
    //NAND
    assign y1 = ~(a & b);
    //OR
    assign y2 = a | b;
    //NOR
    assign y3 = ~(a | b);
    //ExOR
    assign y4 = a ^ b;
    //ExNOR
    assign y5 = ~(a ^ b);
    //NOT
    assign y6 = ~a;

endmodule