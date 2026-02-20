`timescale 1ns / 1ps

module TOP_dht11 (
    input  clk,
    input  rst,
    input  btn_r,
    input  [3:0]sw,
    output [3:0]fnd_digit,
    output [7:0]fnd_data,
    output vaild,
    inout dhtio

);

    wire [15:0] w_data_hum, w_data_tem;
    wire [27:0] w_data;
    assign w_data [27:14] = {w_data_hum [14:8], w_data_hum [6:0]};
    assign w_data [13:0] = {w_data_tem [14:8], w_data_tem [6:0]};

    dht11_controller U_DHT11 (
        .clk        (clk),
        .rst        (rst),
        .start      (w_btn),
        .humidity   (w_data_hum),
        .temperature(w_data_tem),
        .dht11_done (),
        .dht11_valid(vaild),
        .debug      (), 
        .dhtio      (dhtio)             //always wire
    );

    btn_debounce U_DTN (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_r),
        .o_btn(w_btn)
    );

    fnd_controller U_FND (
        .clk(clk),
        .reset(rst),
        .fnd_in_data(w_data),
        .sel_display(sw[0]),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );





endmodule
