`timescale 1ns / 1ps


module tb_sr04_top(

    );

reg clk, rst, st, echo, all;
wire[7:0] dist;
wire ot;

SR04_TOP dut(
    .clk(clk),
    .rst(rst),
    .btn_r(st),
    .echo(echo),
    .fnd_data(dist),
    .fnd_digit(),
    .out_trigger(ot)

    );

always #5 clk = ~clk;

initial begin
    #0;
    rst = 1;
    clk = 0;
    st = 0;
    echo = 0;
    all = 0;
    #5;
    rst = 0;
    all = 1;
    #5;
    st = 1;
    #(100_000);
    st = 0;
    #(100_000);
    echo = 1;
    #(7_900_000);
    echo = 0;
    #(1_000_000);
    st = 1;
    #(100_000);
    st = 0;
    #(100_000);
    echo = 1;
    #(1_740_000);
    echo = 0;
end

endmodule
