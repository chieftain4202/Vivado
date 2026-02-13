`timescale 1ns / 1ps

module tb_fsm_mealy();

    reg clk, rst, din_bit;
    wire dout_bit;

    always #5 clk = ~clk;
    
fsm_mealy dut(
    .clk(clk),
    .rst(rst),
    .din_bit(din_bit),
    .dout_bit(dout_bit)
    );


    initial begin
        #0;
        clk=0;
        rst = 1;
        din_bit = 0;
        #10;
        rst = 0;
        #20;
        din_bit = 1;
        #30;
        din_bit = 0;
        #10;
        din_bit = 1;
        #20;
        din_bit = 0;

        #10;
        $stop;


    end
endmodule
