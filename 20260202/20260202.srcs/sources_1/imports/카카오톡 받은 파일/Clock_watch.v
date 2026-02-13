`timescale 1ns / 1ps

module Top_stopwatch (
    input        clk,
    input        reset,
    input        btn_r,      //i_run_stop , minup
    input        btn_l,      //i_clear    , secup
    input        btn_d,      //hourup
    input  [3:0] sw,         //sw[0] up/down
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire [13:0] w_counter;
    wire w_run_stop, w_clear, w_mode;
    wire o_btn_run_stop, o_btn_run_clear;
    wire o_btn_up, o_btn_down, o_btn_left, o_btn_right;
    wire o_btn_hour, o_btn_min, o_btn_sec;
    wire [23:0] w_stopwatch_time;
    wire [23:0] w_clock_time;
    wire [23:0] w_mux_out;

    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(o_btn_run_stop)
    );

    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_l),
        .o_btn(o_btn_run_clear)
    );

    btn_debounce U_BD_HOUR (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(o_btn_hour)
    );

    btn_debounce U_BD_MIN (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_d),
        .o_btn(o_btn_min)
    );


    btn_debounce U_BD_SEC (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_l),
        .o_btn(o_btn_sec)
    );

    control_unit U_CONTROL_UNIT (
        .clk       (clk),
        .reset     (reset),
        .i_mode    (sw),
        .i_run_stop(o_btn_run_stop),
        .i_clear   (o_btn_run_clear),
        .sw_1      (sw[1]),
        .sw_2      (sw[2]),
        .o_mode    (w_mode),
        .o_run_stop(w_run_stop),
        .o_clear   (w_clear)
    );


    mux_2 U_MUX_2 (
        .mux_in_stop(w_stopwatch_time),
        .mux_in_clock(w_clock_time),
        .mode(sw[1]),
        .mux_out(w_mux_out)
    );


    clock_datapath U_CLOCK_DATAPATH (
        .clk    (clk),
        .reset  (reset),
        .up_hour(o_btn_hour),
        .up_min (o_btn_min),
        .up_sec (o_btn_sec),
        .msec   (w_clock_time[6:0]),
        .sec    (w_clock_time[12:7]),
        .min    (w_clock_time[18:13]),
        .hour   (w_clock_time[23:19])
    );


    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk     (clk),
        .reset   (reset),
        .mode    (w_mode),
        .clear   (w_clear),
        .run_stop(w_run_stop),
        .msec    (w_stopwatch_time[6:0]),    //7bit
        .sec     (w_stopwatch_time[12:7]),   //6bit  
        .min     (w_stopwatch_time[18:13]),  //6bit      
        .hour    (w_stopwatch_time[23:19])   //6bit
    );


    fnd_controller U_FND_CNTL (
        .clk        (clk),
        .reset      (reset),
        .sel_display(sw[2]),
        .fnd_in_data(w_mux_out),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );


endmodule



module mux_2 (
    input [23:0] mux_in_stop,
    input [23:0] mux_in_clock,
    input mode,
    output [23:0] mux_out
);
    assign mux_out = (mode) ? mux_in_clock : mux_in_stop;

endmodule



module clock_datapath (
    input clk,
    input reset,
    input up_hour,
    input up_min,
    input up_sec,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;


    tick_counter_c #(
        .BIT_WIDTH(5),
        .TIMES(24),
        .DEFAULT_TIME(12)
    ) hour_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_hour_tick),
        .o_count(hour),
        .o_tick()
    );

    tick_counter_c #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .DEFAULT_TIME()
    ) min_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_min_tick),
        .o_count(min),
        .o_tick(w_hour_tick)
    );

    tick_counter_c #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .DEFAULT_TIME()
    ) sec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_sec_tick),
        .o_count(sec),
        .o_tick(w_min_tick)
    );

    tick_counter_c #(
        .BIT_WIDTH(7),
        .TIMES(100),
        .DEFAULT_TIME()
    ) msec_counter (
        .clk(clk),
        .i_tick(w_tick_100hz),
        .o_count(msec),
        .o_tick(w_sec_tick)
    );

    tick_gen_100Hz_2 U_TICK (
        .clk(clk),
        .reset(reset),
        .o_tick_100hz_2(w_tick_100hz)
    );


endmodule


// msec, sec, min, hour
// tick counter
module tick_counter_c #(
    parameter BIT_WIDTH = 7,
    parameter DEFAULT_TIME = 0,
    TIMES = 100
) (
    input clk,
    input reset,
    input i_tick,
    input clear,
    input mode_1,
    input mode_2,
    input up,
    input down,
    input right,
    input left,
    output [BIT_WIDTH-1:0] o_count,
    output reg o_tick
);

    //counter reg
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign o_count = counter_reg;


    //State reg SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= DEFAULT_TIME;
        end else begin
            counter_reg <= counter_next;
        end
    end

    //next CL
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick) begin
            if (counter_reg == TIMES - 1) begin
                counter_next = 0;
                o_tick = 1'b1;
            end else begin
                counter_next = counter_reg + 1;
                o_tick = 1'b0;
            end
        end
    end



endmodule


module tick_gen_100Hz_2 (
    input      clk,
    input      reset,
    output reg o_tick_100hz_2
);
    parameter F_count = 100_000_000 / 100;
    reg [$clog2(F_count)-1:0] counter_r;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 0;
            o_tick_100hz_2 <= 1'b0;
        end else begin
            counter_r <= counter_r + 1;
            o_tick_100hz_2 <= 1'b0;
            if (counter_r == (F_count - 1)) begin
                counter_r <= 0;
                o_tick_100hz_2 <= 1'b1;
            end else begin
                o_tick_100hz_2 <= 1'b0;
            end
        end
    end


endmodule




module stopwatch_datapath (
    input clk,
    input reset,
    input mode,
    input clear,
    input run_stop,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour

);
    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    tick_counter_s #(
        .BIT_WIDTH(5),
        .TIMES(24)
    ) hour_counter (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .i_tick(w_hour_tick),
        .mode(mode),
        .run_stop(run_stop),
        .o_count(hour),
        .o_tick()
    );

    tick_counter_s #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) min_counter (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .i_tick(w_min_tick),
        .mode(mode),
        .run_stop(run_stop),
        .o_count(min),
        .o_tick(w_hour_tick)
    );

    tick_counter_s #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) sec_counter (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .i_tick(w_sec_tick),
        .mode(mode),
        .run_stop(run_stop),
        .o_count(sec),
        .o_tick(w_min_tick)
    );

    tick_counter_s #(
        .BIT_WIDTH(7),
        .TIMES(100)
    ) msec_counter (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .i_tick(w_tick_100hz),
        .mode(mode),
        .run_stop(run_stop),
        .o_count(msec),
        .o_tick(w_sec_tick)
    );

    tick_gen_100Hz U_TICK (
        .clk(clk),
        .reset(reset),
        .i_run_stop(run_stop),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

// msec, sec, min, hour
// tick counter
module tick_counter_s #(
    parameter BIT_WIDTH = 7,
    TIMES = 100
) (
    input clk,
    input reset,
    input i_tick,
    input mode,
    input clear,
    input run_stop,
    output [BIT_WIDTH-1:0] o_count,
    output reg o_tick
);

    //counter reg
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign o_count = counter_reg;
    //State reg SL
    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    //next CL
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick & run_stop) begin
            if (mode == 1'b1) begin
                //down
                if (counter_reg == 0) begin
                    counter_next = TIMES - 1;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg - 1;
                    o_tick = 1'b0;
                end
            end else begin
                //up
                if (counter_reg == TIMES - 1) begin
                    counter_next = 0;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg + 1;
                    o_tick = 1'b0;
                end
            end
        end
    end

endmodule


module tick_gen_100Hz (
    input      clk,
    input      reset,
    input      i_run_stop,
    output reg o_tick_100hz
);
    parameter F_count = 100_000_000 / 100;
    reg [$clog2(F_count)-1:0] counter_r;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 0;
            o_tick_100hz <= 1'b0;
        end else begin
            if (i_run_stop) begin
                counter_r <= counter_r + 1;
                o_tick_100hz <= 1'b0;
                if (counter_r == (F_count - 1)) begin
                    counter_r <= 0;
                    o_tick_100hz <= 1'b1;
                end else begin
                    o_tick_100hz <= 1'b0;
                end
            end
        end
    end

endmodule






