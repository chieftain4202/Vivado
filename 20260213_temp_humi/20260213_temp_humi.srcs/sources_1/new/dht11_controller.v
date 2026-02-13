`timescale 1ns / 1ps

module dht11_controller (
    input         clk,
    input         rst,
    input         start,
    output [15:0] humidity,
    output [15:0] temperature,
    output        dht11_done,
    output        dht11_valid,
    output [ 3:0] debug,
    inout         dhtio         //always wire

);

    wire tick_1us;

    tick_gen_1MHz U_TICK_1MHz (
        .clk(clk),
        .rst(rst),
        .o_tick_1mhz(tick_1us)
    );

    parameter IDLE = 0, START = 1, WAIT = 2, SYNC_L = 3, SYNC_H = 4, DATA_SYNC = 5, DATA_C = 6, STOP = 7;

    reg [3:0] c_state, n_state;
    reg dhtio_r, dhtio_n;
    reg io_sel_reg, io_sel_next;
    //for 19sec count by 10usec tick
    reg [$clog2(19000)-1:0] tick_cnt_reg, tick_cnt_next;
    assign dhtio = (io_sel_reg) ? dhtio_r: 1'bz;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= 3'b000;
            dhtio_r <= 1'b1;
            tick_cnt_reg <= 0;
            io_sel_reg <= 1'b1;
        end else begin
            c_state <= n_state;
            dhtio_r <= dhtio_n;
            tick_cnt_reg <= tick_cnt_next;
            io_sel_reg <= io_sel_next;
        end
    end
//tick_10u -> tick_1u
    //next, output
    always @(*) begin
        n_state = c_state;
        dhtio_n = dhtio_r;
        io_sel_next = io_sel_reg;
        tick_cnt_next = tick_cnt_reg;
        case (c_state)
            IDLE: begin
                if (start) begin
                    n_state = START;
                end
            end 
            START: begin
                dhtio_n = 1'b0;
                if (tick_1us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 19000) begin
                        tick_cnt_next = 0;
                        n_state = WAIT;
                    end
                end
            end
            WAIT: begin             
                dhtio_n = 1'b1; //1
                if (tick_1us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 30) begin
                        //for output to high-z
                        n_state = SYNC_L;
                        io_sel_next = 1'b0;
                    end
                end
            end
            SYNC_L: begin
                if (tick_1us) begin
                    if (dhtio == 1) begin
                        n_state = SYNC_H;
                    end
                end
            end
            SYNC_H: begin
                if (tick_1us) begin
                    if (dhtio == 0) begin
                        n_state = DATA_SYNC;
                    end
                end
            end
            DATA_SYNC: begin
                if (tick_1us) begin
                    if (dhtio == 1) begin
                        n_state = DATA_C;
                    end
                end
            end
            DATA_C: begin
                if (tick_1us) begin
                    if (dhtio == 1) begin
                        //tick_count
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                    else begin
                        n_state = STOP;
                    end
                end
            end
            STOP: begin
                if (tick_1us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 50) begin
                        // output mode
                        dhtio_n = 1'b1;
                        io_sel_next = 1'b1;
                        n_state = IDLE;
                    end
                end
            end
        endcase    
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
            counter_r   <= 0;
            o_tick_1mhz <= 1'b0;
        end else begin
            counter_r   <= counter_r + 1;
            o_tick_1mhz <= 1'b0;
            if (counter_r == (F_count - 1)) begin
                counter_r   <= 0;
                o_tick_1mhz <= 1'b1;
            end else begin
                o_tick_1mhz <= 1'b0;
            end
        end
    end

endmodule


