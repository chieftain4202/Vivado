`timescale 1ns / 1ps

module SR04_Controller(
    input [13:0] echo,
    input echo_up,
    input clk,
    input rst,
    input i_trigger,
    input start,
    input all,
    input tick,
    input [6:0] tick_cnt,
    output reg o_trigger,
    output reg [23:0]dist,
    output reg [23:0]dist_val
    );

    localparam IDLE = 2'b00, START = 2'b01, WAIT = 2'b10, DISTANCE = 2'b11; 

    reg [1:0] cnt_st, next_st;
    reg [6:0] start_cnt;
    reg [23:0] dist_reg;
    reg [23:0] dist_val_reg;

    always @(posedge clk, posedge rst) begin
    if (rst) begin
        cnt_st <= IDLE;
        o_trigger <= 0;
        dist_val_reg <= 0;
        dist_reg <= 0;
    end else begin
        cnt_st <= next_st;

        if (cnt_st == START)
            o_trigger <= 1;
        else
            o_trigger <= 0;

            if (cnt_st == DISTANCE)
            dist_reg <= echo / 58;
              if (!echo_up) 
                    dist_val_reg <= dist_reg;
              
            
    end
end

    always @(*) begin
        next_st = cnt_st;
        dist = 0;
        case (cnt_st)
           IDLE: begin
            if (start) begin
                dist = 0;
                next_st = START;
              end
           end

           START: begin
            if (tick_cnt == 13) begin
                dist = 0;
                next_st = WAIT;
            end
           end

           WAIT: begin
            dist_val = 0;
            if (echo) begin
                dist = 0;
                next_st = DISTANCE;
            end
           end

           DISTANCE: begin
            if (echo) begin
            dist = dist_reg;
            end else if (!echo) begin
                next_st = IDLE;
                dist_val = dist_val_reg;
                dist = 0;
            end
           end
        endcase
    end

endmodule


module echo_count(
    input clk,
    input rst,
    input i_echo,
    input tick,
    output [13:0]o_echo
);

    reg [13:0] r_echo;

    assign o_echo = r_echo;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_echo <= 0;
        end else if (tick) begin
            if (i_echo) begin
                r_echo <= r_echo + 1;
            end else begin
                r_echo <= 0;
            end
        end
    end
endmodule




module tick_count(
    input clk,
    input rst,
    input i_tick,
    output [10:0] o_tick
);

    reg [10:0] r_tick;

    assign o_tick = r_tick;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_tick <= 0;
        end else begin

                if (i_tick) begin
                r_tick <= r_tick + 1;
                end
            end 
        end
    
endmodule




module tick_gen_1MHz (
    input      clk,
    input      rst,
    output reg o_tick_1mhz
);
    parameter F_count = 100_000_000 / 1_000_000;
    reg [$clog2(F_count)-1:0] counter_r;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= 0;
            o_tick_1mhz <= 1'b0;
        end else begin
            counter_r <= counter_r + 1;
            o_tick_1mhz <= 1'b0;
            if (counter_r == (F_count - 1)) begin
                counter_r <= 0;
                o_tick_1mhz <= 1'b1;
            end else begin
                o_tick_1mhz <= 1'b0;
            end
        end
    end

endmodule