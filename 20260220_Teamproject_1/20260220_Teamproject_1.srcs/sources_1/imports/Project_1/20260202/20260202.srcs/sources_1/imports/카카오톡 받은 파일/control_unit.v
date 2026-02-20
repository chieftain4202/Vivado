`timescale 1ns / 1ps

module control_unit (
    input clk,
    input reset,
    input i_mode,
    input sw_1,
    input sw_2,
    input i_run_stop,
    input i_clear,
    input i_up,
    input i_down,
    output o_up,
    output o_down,
    output o_mode,
    output reg o_run_stop,
    output reg o_clear
    
);
   
   /*localparam DOWN = 2'b00, UP = 2'b01, TOGGLE = 2'b10;

    reg [1:0] current_st_1, next_st_1;

    assign o_mode =  i_mode;

    //state register SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st_1 <= TOGGLE;
        end else if (sw_3 == 1) begin
            current_st_1 <= next_st_1;
        end
    end

    always @(*) begin
        next_st_1 = current_st_1;
        o_down = 1'b0;
        o_up = 1'b0;
        o_toggle = 1'b0;
        case (current_st_1)
            DOWN: begin
                //moore output
                o_run_stop = 1'b0;
                o_clear = 1'b0;
                if (i_run_stop) begin
                    next_st = RUN;
                end else if (i_clear) begin
                    next_st = CLEAR;
                end
            end
            UP: begin
                o_run_stop = 1'b1;
                o_clear = 1'b0;
                if (i_run_stop) begin
                    next_st = STOP;
                end
            end
            TOGGLE: begin
                o_run_stop = 1'b0;
                o_clear = 1'b1;
                next_st = STOP;
            end
        endcase
    end

*/




    localparam STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;

    reg [1:0] current_st, next_st;

    assign o_mode =  i_mode;

    //state register SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st <= STOP;
        end else if (sw_1 == 0) begin
            current_st <= next_st;
        end
    end


    always @(*) begin
        next_st = current_st;
        o_run_stop = 1'b0;
        o_clear = 1'b0;
        case (current_st)
            STOP: begin
                //moore output
                o_run_stop = 1'b0;
                o_clear = 1'b0;
                if (i_run_stop) begin
                    next_st = RUN;
                end else if (i_clear) begin
                    next_st = CLEAR;
                end
            end
            RUN: begin
                o_run_stop = 1'b1;
                o_clear = 1'b0;
                if (i_run_stop) begin
                    next_st = STOP;
                end
            end
            CLEAR: begin
                o_run_stop = 1'b0;
                o_clear = 1'b1;
                next_st = STOP;
            end
        endcase
    end


 endmodule