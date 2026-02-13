`timescale 1ns / 1ps

module top_counter_10000 (
    input    clk,
    input    reset,
    input    btn_r,     //i_run_stop
    input    btn_l,     //i_clear
    input    sw,        //sw[0] up/down
    output   [3:0] fnd_digit,
    output   [7:0] fnd_data
);

    wire [13:0] w_counter;
    wire w_tick_10hz;
    wire w_run_stop, w_clear, w_mode;

    control_unit U_CONTROL_UNIT(
    .clk(clk),
    .reset(reset),
    .i_mode(sw),
    .i_run_stop(btn_r),
    .i_clear(btn_l),
    .o_mode(w_mode),
    .o_run_stop(w_run_stop),
    .o_clear(w_clear)

);

    fnd_controller U_FND_CNTL (
        .clk        (clk),
        .reset      (reset),
        .fnd_in_data(w_counter),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );


    counter_10000 U_COUNTER_10000 (
        .clk          (clk),
        .reset        (reset),
        .switch       (w_mode),
        .clear        (w_clear),
        .run_stop     (w_run_stop),
        .i_tick       (w_tick_10hz),
        .counter_sel_2(w_counter)
    );

    tick_gen_10Hz U_TICK (
        .clk(clk),
        .reset(reset),
        .o_tick_10hz(w_tick_10hz)
    );

endmodule



module tick_gen_10Hz (
    input      clk,
    input      reset,
    output reg o_tick_10hz
);
    parameter tick_count = 10;
    reg [$clog2(tick_count)-1:0] counter_r;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r   <= 0;
            o_tick_10hz <= 1'b0;
        end else begin
            counter_r   <= counter_r + 1;
            o_tick_10hz <= 1'b0;
            if (counter_r == (tick_count - 1)) begin
                counter_r   <= 0;
                o_tick_10hz <= 1'b1;
            end else begin
                o_tick_10hz <= 1'b0;
            end
        end
    end

endmodule



module counter_10000 (
    input         clk,
    input         reset,
    input         i_tick,
    input         clear,
    input         run_stop,
    input         switch,
    output [13:0] counter_sel_2
);

    reg [13:0] counter_r;

    assign counter_sel_2 = counter_r;  //assign later than reg



    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            //init counter_r
            counter_r <= 14'd0;
        end else begin
            //to do
            if (run_stop == 0) begin
                if (switch == 1) begin
                    if (i_tick) begin
                        counter_r <= counter_r - 1;
                    end else if (counter_r == (0)) begin
                        counter_r <= 14'd9999;
                    end
                end else begin
                    if (i_tick) begin
                        counter_r <= counter_r + 1;
                    end else if (counter_r == (10000 - 1)) begin
                        counter_r <= 14'd0;
                    end
                end
            end
        end
    end

endmodule



