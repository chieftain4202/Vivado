`timescale 1ns / 1ps


module tb_fsm_moore ();

wire [2:0] led;
reg clk,reset;
reg [2:0] sw;

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
    sw = 3'b000;
    #10;
    reset = 0;
    #10;
    sw = 3'b001;
    #10;
    sw = 3'b010;
    #10;
    sw = 3'b100;
    #10;
    sw = 3'b011;
    #10;
    sw = 3'b010;
    #10;
    sw = 3'b100;
    #10;
    sw = 3'b000;
    #10;
    sw = 3'b010;
    #10;
    sw = 3'b100;
    #10;
    sw = 3'b111;
    #10;
    sw = 3'b000;
    #10;
    $stop;


end

endmodule