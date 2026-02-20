`timescale 1ns / 1ps

module dht11_controller_ila (
    input             clk,
    input             rst,
    input             start,
   // output reg [15:0] humidity,
   // output reg [15:0] temperature,
   // output reg        dht11_done,
   // output reg        dht11_valid,
    output     [ 3:0] debug,
    inout             dhtio         //always wire

);

    wire tick_1us;

    ila_0 U_ILA0 (
        .clk(clk),
        .probe0(dhtio),   //1bit
        .probe1(debug)    //3bit
    );


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

    assign dhtio = (io_sel_reg) ? dhtio_r : 1'bz;
    assign debug = c_state;

    always @(posedge clk) begin
        delay = dhtio;
    end

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= 3'b000;
            dhtio_r      <= 1'b1;
            tick_cnt_reg <= 0;
            io_sel_reg   <= 1'b1;
            shift_reg    <= 0;
            bit_cnt      <= 0;
            delay        <= 0;
        end else begin
            c_state      <= n_state;
            dhtio_r      <= dhtio_n;
            tick_cnt_reg <= tick_cnt_next;
            io_sel_reg   <= io_sel_next;
            shift_reg    <= shift_next;
            bit_cnt      <= bit_next;
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
        case (c_state)
            IDLE: begin
              //  dht11_done = 0;
                if (start) begin
                    n_state = START;
                end
            end
            START: begin
                dhtio_n = 1'b0;
              //  dht11_valid = 1;
                if (tick_1us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 19000) begin
                        tick_cnt_next = 0;
                        n_state = WAIT;
                    end
                end
            end
            WAIT: begin
                dhtio_n = 1'b1;  //1
                if (tick_1us) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 30) begin
                        //for output to high-z
                        n_state = SYNC_L;
                        io_sel_next = 1'b0;
                        tick_cnt_next = 0;
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
                        n_state = DATA_C;
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
                    if (dhtio == 1) begin
                        //tick_count
                        tick_cnt_next = tick_cnt_reg + 1;
                    end else begin
                        tick_cnt_next = 0;
                    end
                end


                if (dhtio) begin
                    if (delay == 0) begin
                        bit_next = bit_cnt + 1;
                    end
                end else begin
                    if (delay == 1) begin
                        if (tick_cnt_reg < 45) begin
                            shift_next = {shift_reg[38:0], 1'b0};
                        end else begin
                            shift_next = {shift_reg[38:0], 1'b1};
                        end
                    end
                end
                if (bit_cnt == 40) begin
                    if (delay == 0) begin

                        bit_next = 0;
                        tick_cnt_next = 0;
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
     //                   humidity[15:8] = shift_reg[39:32];
     //                   humidity[7:0] = shift_reg[31:24];
     //                   temperature[15:8] = shift_reg[23:16];
     //                   temperature[7:0] = shift_reg[15:8];
     //                   dht11_done = 1;
     //                   if (shift_reg[39:32]+shift_reg[31:24]+shift_reg[23:16]+shift_reg[15:8] == shift_reg [7:0]) begin
     //                       dht11_valid = 1;
     //                   end else begin
     //                       dht11_valid = 0;
     //                   end
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


