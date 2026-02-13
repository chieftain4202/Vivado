`timescale 1ns / 1ps


module tb_uart();

    
    parameter BAUD_9600 = 104_160;
    reg clk, rst, btn_down;//need to for btn_down 100msec
    wire uart_tx, rx;

uart_top dut(
    .clk(clk),
    .rst(rst),
    .btn_down(btn_down),
    .uart_tx(uart_tx)
);


/*   Top_stopwatch dut (
        .clk(clk),
        .reset(rst),
        .btn_r(),
        .btn_d(),
        .btn_u(),
        .btn_l(),
        .sw(),         //sw[0] up/down
        .uart_rx(rx),
        .uart_tx(uart_tx),
        .fnd_digit(),
        .fnd_data()
    );
*/


//clock
always #5 clk = ~clk;

initial begin
    #0;
    clk = 0;
    rst = 1;
    btn_down = 0;
    #20;
    rst = 0;
    btn_down = 1'b1;
    #100_000; // 100usec
    btn_down = 1'b0;
    
    #(BAUD_9600 * 1);

    #10;
    $stop;
end


endmodule
