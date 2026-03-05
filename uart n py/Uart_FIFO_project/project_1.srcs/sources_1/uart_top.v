`timescale 1ns / 1ps


module uart_top (
    input  clk,
    input  rst,
    input  uart_rx,
    output uart_tx
);
    wire w_b_tick, w_rx_done;
    wire [7:0] w_rx_data;


    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .tx_start(w_rx_done),
        .b_tick(w_b_tick),
        .tx_data(w_rx_data),
        .tx_busy(),
        .tx_done(),
        .uart_tx(uart_tx)
    );
    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .b_tick(w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );


    baud_tick U_BAUD_TICK (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)
    );

endmodule

module uart_rx (
    input        clk,
    input        rst,
    input        rx,
    input        b_tick,
    output [7:0] rx_data,
    output       rx_done
);

    localparam [1:0] IDLE = 2'd0, START = 2'd1, DATA = 3'd2, STOP = 2'd3;
    reg [1:0] c_state, n_state;
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [3:0] bit_cnt_reg, bit_cnt_next;
    reg done_reg, done_next;
    reg [7:0] buf_reg, buf_next;

    assign rx_data = buf_reg;
    assign rx_done = done_reg;

    //
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg    <= 0;
            done_reg       <= 1'b0;
            buf_reg        <= 8'b0;
        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            done_reg       <= done_next;
            buf_reg        <= buf_next;
        end
    end


    //next, ouput
    always @(*) begin
        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        done_next       = done_reg;
        buf_next        = buf_reg;
        case (c_state)
            IDLE: begin
                b_tick_cnt_next = 0;
                bit_cnt_next    = 0;
                buf_next        = 8'b0;
                done_next       = 1'b0;
                if (rx != 1'b1) begin
                    n_state = START;
                end
            end
            START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 7) begin
                        n_state = DATA;
                        b_tick_cnt_next = 5'b0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        buf_next = {rx, buf_reg[7:1]};
                        if (bit_cnt_reg == 7) begin
                            n_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        done_next = 1'b1;
                        n_state   = IDLE;
                        b_tick_cnt_next = 0;
                        bit_cnt_next    = 0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule


module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,
    input        b_tick,
    input  [7:0] tx_data,
    output       tx_busy,
    output       tx_done,
    output       uart_tx
);

    localparam [1:0] IDLE = 3'd0, START = 3'd1, DATA = 3'd2, STOP = 3'd3;

    reg [1:0] c_state, next_state;
    reg tx_reg, tx_next;  //for OUTPUT SL

    reg [3:0] bit_cnt_reg, bit_cnt_next;
    //busy, done
    reg tx_busy_reg, tx_busy_next, tx_done_reg, tx_done_next;
    //data_in_buf
    reg [7:0] data_in_buf_reg, data_in_buf_next;
    //16tick counter
    reg [3:0] bt_cnt16_reg, bt_cnt16_next;




    assign uart_tx = tx_reg;
    assign tx_busy = tx_busy_reg;
    assign tx_done = tx_done_reg;

    // SL
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state         <= IDLE;
            tx_reg          <= 1'b1;
            bit_cnt_reg     <= 4'b0;
            tx_busy_reg     <= 1'b0;
            tx_done_reg     <= 1'b0;
            data_in_buf_reg <= 8'b0;
            bt_cnt16_reg    <= 4'b0;
        end else begin
            c_state         <= next_state;
            tx_reg          <= tx_next;
            bit_cnt_reg     <= bit_cnt_next;
            tx_busy_reg     <= tx_busy_next;
            tx_done_reg     <= tx_done_next;
            data_in_buf_reg <= data_in_buf_next;
            bt_cnt16_reg    <= bt_cnt16_next;
        end
    end

    //16tick done
    always @(*) begin
        bt_cnt16_next = bt_cnt16_reg;
        if (c_state == IDLE) begin
            bt_cnt16_next = 1'b0;
        end else begin
            if (b_tick == 1) begin
                if ((bt_cnt16_reg == 4'd15)) begin
                    bt_cnt16_next = 1'b0;
                end else begin
                    bt_cnt16_next = bt_cnt16_reg + 4'b1;
                end
            end
        end
    end

    // next_reg CL
    always @(*) begin
        next_state = c_state;
        tx_next = tx_reg;
        bit_cnt_next = bit_cnt_reg;
        tx_busy_next = tx_busy_reg;
        tx_done_next = tx_done_reg;
        data_in_buf_next = data_in_buf_reg;
        //tx_next, bit_cnt
        case (c_state)
            IDLE: begin
                tx_next          = 1'b1;
                bit_cnt_next     = 1'b0;
                tx_busy_next     = 1'b0;
                tx_done_next     = 1'b0;
                data_in_buf_next = tx_data;
                if (tx_start) begin
                    next_state   = START;
                    tx_busy_next = 1'b1;
                end
            end
            START: begin
                tx_next = 1'b0;
                if ((b_tick) && (bt_cnt16_reg == 4'd15)) next_state = DATA;
            end
            DATA: begin
                tx_next = data_in_buf_reg[0];
                if ((b_tick) && (bt_cnt16_reg == 4'd15)) begin
                    if (bit_cnt_reg < 3'd7) begin
                        bit_cnt_next = bit_cnt_reg + 1;
                        data_in_buf_next = {1'b0, data_in_buf_reg[7:1]};
                    end else begin
                        next_state = STOP;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                bit_cnt_next = 1'b0;
                if ((b_tick) && (bt_cnt16_reg == 4'd15)) begin
                    tx_done_next = 1'b1;
                    next_state   = IDLE;
                end
            end
        endcase
    end
endmodule




module baud_tick #(
    parameter CLK = 100_000_000,
    parameter FEQ = 9600 * 16
) (
    input      clk,
    input      rst,
    output reg b_tick
);

    parameter F_COUNT = CLK / FEQ;  //651


    reg [$clog2(F_COUNT)-1:0] r_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_count <= 0;
            b_tick  <= 1'b0;
        end else begin
            r_count <= r_count + 1;
            if (r_count == (F_COUNT - 1)) begin
                r_count <= 0;
                b_tick  <= 1'b1;
            end else begin
                b_tick <= 1'b0;
            end
        end
    end

endmodule
