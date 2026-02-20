`timescale 1ns / 1ps


module tb_uart_watch ();

    reg clk, rst;
    reg btn; 
    reg [3:0]sw;
    wire tx;
    wire [7:0] fnd_data;
    wire [3:0] fnd_digit;
/*
    fnd_controller dut (
    .clk(clk),
    .reset(rst),
    .sel_display(),
    .mode(btn),
    .fnd_in_data(rx),
    .fnd_digit(),
    .fnd_data(),
    .fnd_to_sender()
);

*/
    Top_stopwatch dut(
    .clk(clk),
    .reset(rst),
    .btn_r(),
    .btn_d(),
    .btn_u(btn),
    .btn_l(),
    .sw(sw),         //sw[0] up/down
    .uart_rx(1'b1),
    .uart_tx(),
    .fnd_digit(fnd_digit),
    .fnd_data(fnd_data)

);


always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        sw = 4'b0000;
        btn = 0;
        #1000;
        rst = 0;
        #10;
        btn = 1;
        #10000000;
        btn = 0;
       
        #10;
        $stop;
    end
endmodule
