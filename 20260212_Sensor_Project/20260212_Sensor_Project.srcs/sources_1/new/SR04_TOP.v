`timescale 1ns / 1ps

module SR04_TOP(
    input clk,
    input rst,
    input echo,
    input btn_r,
    output [7:0] fnd_data,
    output [3:0] fnd_digit,
    output out_trigger

    );
    

    wire w_tick;
    wire [6:0] r_count;
    wire w_trigger;
    wire [13:0] r_echo;
    wire w_btn_r;
    reg o_tick_gen;
    wire [23:0] r_dist_val;

    SR04_Controller U_SR04_CONTROL(
    .clk(clk),
    .rst(rst),
    .i_trigger(w_trigger),
    .echo(r_echo),
    .start(w_btn_r),
    .all (all),
    .tick(w_tick),
    .tick_cnt(r_count),
    .o_trigger(out_trigger),
    .dist(),
    .echo_up(echo),
    .dist_val(r_dist_val)
    );


    echo_count U_ECHO_CNT(
    .clk(clk),
    .rst(rst),
    .i_echo(echo),
    .tick(w_tick),
    .o_echo(r_echo)
);

    tick_count U_TICK_CNT(
    .clk(clk),
    .rst(rst),
    .i_tick(w_tick),
    .o_tick(r_count)
);

    tick_gen_1MHz U_TICK_GEN(
    .clk(clk),
    .rst(rst),
    .o_tick_1mhz(w_tick)
);

btn_debounce U_BTN(
    .clk(clk),
    .reset(rst),
    .i_btn(btn_r),
    .o_btn(w_btn_r)
);

fnd_controller U_FND(
    .clk(clk),
    .reset(rst),
    .fnd_in_data(r_dist_val),
    .fnd_digit(fnd_digit),
    .fnd_data(fnd_data)
);
    
endmodule
