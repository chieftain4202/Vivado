`timescale 1ns / 1ps

module TOP_Module(
    input clk,
    input rst,
    output done
    );


uart_top U_UART(
    .clk(clk),
    .rst(rst),
    .uart_rx(),
    .uart_tx(),
    .uart_rx_data(),
    .uart_rx_done()

);









endmodule
