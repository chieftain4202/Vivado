`timescale 1ns / 1ps

module dht11_controller (
    input              clk,
    input              rst,
    input              start,
    output wire [15:0] humidity,
    output wire [15:0] temperature,
    output wire        dht11_done,
    output wire        dht11_valid,
    output reg  [ 7:0] LED,
    output      [ 3:0] debug,
    inout              dhtio         //always wire

);

    wire tick_1us, w_btn;

    tick_gen_1MHz U_TICK_1MHz (
        .clk(clk),
        .rst(rst),
        .o_tick_1mhz(tick_1us)
    );

    parameter IDLE = 0, START = 1, WAIT = 2, SYNC_L = 3, SYNC_H = 4, DATA_SYNC = 5, DATA_C = 6, STOP = 7;


    reg [2:0] c_state, n_state;
    reg dhtio_r, dhtio_n;
    reg io_sel_reg, io_sel_next;
    //for 19sec count by 10usec tick
    reg [$clog2(19000)-1:0] tick_cnt_reg, tick_cnt_next;
    reg [5:0] bit_cnt, bit_next;
    reg [39:0] shift_reg, shift_next;
    reg delay;
    reg [15:0] hum_next, hum_reg;
    reg [15:0] tmp_next, tmp_reg;
    reg done_reg, done_next, valid_reg, valid_next;


    reg dht_sync1, dht_sync2;
    reg dht_prev;

    always @(posedge clk) begin
        dht_sync1 <= dhtio;
        dht_sync2 <= dht_sync1;
        dht_prev  <= dht_sync2;
    end

    wire dht_rising = (dht_sync2 & ~dht_prev);
    wire dht_falling = (~dht_sync2 & dht_prev);


    assign humidity = hum_reg;
    assign temperature = tmp_reg;
    assign dht11_valid = valid_reg;
    assign dht11_done = done_reg;

    assign dhtio = (io_sel_reg) ? dhtio_r : 1'bz;
    assign debug = c_state;

    always @(posedge clk) begin
        delay <= dhtio;
    end

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= 3'b000;
            dhtio_r      <= 1'b1;
            tick_cnt_reg <= 0;
            io_sel_reg   <= 1'b1;
            shift_reg    <= 0;
            bit_cnt      <= 0;
            hum_reg      <= 0;
            tmp_reg      <= 0;
            valid_reg    <= 0;
            done_reg     <= 0;

        end else begin
            c_state      <= n_state;
            dhtio_r      <= dhtio_n;
            tick_cnt_reg <= tick_cnt_next;
            io_sel_reg   <= io_sel_next;
            shift_reg    <= shift_next;
            bit_cnt      <= bit_next;
            tmp_reg      <= tmp_next;
            hum_reg      <= hum_next;
            done_reg     <= done_next;
            valid_reg    <= valid_next;

        end
    end

    //tick_10u -> tick_1u
    //next, output
    always @(*) begin
        n_state       = c_state;
        dhtio_n       = dhtio_r;
        io_sel_next   = io_sel_reg;
        tick_cnt_next = tick_cnt_reg;
        shift_next    = shift_reg;
        bit_next      = bit_cnt;
        tmp_next      = tmp_reg;
        hum_next      = hum_reg;
        done_next     = done_reg;
        valid_next    = valid_reg;

        case (c_state)
            IDLE: begin
                done_next = 0;
                valid_next = 0;
                LED[1] = 1;
                if (start) begin
                    n_state = START;
                    LED[1] = 0;
                    shift_next = 0;
                end
            end
            START: begin
                dhtio_n = 1'b0;
                valid_next = 1;
                LED[2] = 1;
                if (tick_1us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 19000) begin
                        tick_cnt_next = 0;
                        n_state = WAIT;
                        LED[2] = 0;
                    end
                end
            end
            WAIT: begin
                dhtio_n = 1'b1;  //1
                LED[3]  = 1;
                if (tick_1us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 30) begin
                        //for output to high-z
                        n_state = SYNC_L;
                        LED[3] = 0;
                        io_sel_next = 1'b0;
                        tick_cnt_next = 0;
                    end
                end
            end
            SYNC_L: begin
                LED[4] = 1;
                if (tick_1us) begin
                    if (dhtio == 1) begin
                        n_state = SYNC_H;
                        LED[4]  = 0;
                    end
                end
            end
            SYNC_H: begin
                LED[5] = 1;
                if (tick_1us) begin
                    if (dhtio == 0) begin
                        n_state = DATA_C;
                        LED[5]  = 0;
                    end
                end
            end
            // DATA_SYNC: begin
            //     if (tick_1us) begin
            //         if (dhtio == 1) begin
            //             n_state = DATA_C;
            //         end
            //     end
            // end
            DATA_C: begin
                if (tick_1us) begin
                    if (dht_sync2) tick_cnt_next = tick_cnt_reg + 1;
                    else tick_cnt_next = 0;
                end

                if (dht_rising) bit_next = bit_cnt + 1;

                if (dht_falling) begin
                    if (tick_cnt_reg < 45) shift_next = {shift_reg[38:0], 1'b0};
                    else shift_next = {shift_reg[38:0], 1'b1};
                    if (bit_cnt == 40) n_state = STOP;
                    tick_cnt_next = 0;
                end
            end


            STOP: begin
                LED[7] = 1;
                if (tick_1us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 50) begin
                        // output mode
                        dhtio_n = 1'b1;
                        io_sel_next = 1'b1;

                        LED[7] = 0;
                        hum_next[15:8] = shift_reg[39:32];
                        hum_next[7:0] = shift_reg[31:24];
                        tmp_next[15:8] = shift_reg[23:16];
                        tmp_next[7:0] = shift_reg[15:8];
                        done_next = 1;
                        n_state = IDLE;
                        tick_cnt_next = 0;
                        bit_next = 0;
                        if (shift_reg[39:32]+shift_reg[31:24]+shift_reg[23:16]+shift_reg[15:8] == shift_reg [7:0]) begin
                            valid_next = 1;
                        end else begin
                            valid_next = 0;
                        end
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


