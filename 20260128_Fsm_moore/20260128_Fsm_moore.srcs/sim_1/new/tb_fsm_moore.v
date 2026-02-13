`timescale 1ns / 1ps


module tb_fsm_moore ();

wire led;
reg clk,reset,sw;

fsm_moore dut(
    .clk(clk),
    .reset(reset),
    .sw(sw),
    .led(led)

);


always #5 clk = ~clk;

initial begin
    #0;
    reset = 1;
    clk = 0;
    sw = 1;
    #10;
    reset = 0;
    #100;
    sw = 0;
    #97.6;
    sw = 1;
    #102;
    sw = 0;
    #100;
    $stop;


end

endmodule