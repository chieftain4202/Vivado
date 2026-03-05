`timescale 1ns / 1ps


module fifo #(
    parameter ADDR = 16,
    parameter BIT_WIDTH = 8
) (
    input                        w_clk,
    input                        r_clk,
    input                        rst,
    input                        we,
    input                        re,
    input        [BIT_WIDTH-1:0] wdata,
    output logic [BIT_WIDTH-1:0] rdata,
    output logic                 full,
    output logic                 empty
);

    logic [$clog2(ADDR)-1:0] waddr, raddr;

    control_unit #(
        .ADDR     (ADDR),
        .BIT_WIDTH(BIT_WIDTH)
    ) U_FIFO_CTLR (
        .w_clk(w_clk),
        .r_clk(r_clk),
        .rst  (rst),
        .we   (we),
        .re   (re),
        .wptr (waddr),
        .rptr (raddr),
        .full (full),
        .empty(empty)
    );

    sram #(
        .ADDR     (ADDR),
        .BIT_WIDTH(BIT_WIDTH)
    ) U_SRAM (
        .clk   (w_clk),
        .we    (we && ~full),
        .w_addr(waddr),
        .r_addr(raddr),
        .wdata (wdata),
        .rdata (rdata)
    );

endmodule



module control_unit #(
    parameter ADDR = 16,
    parameter BIT_WIDTH = 8
) (
    input                           w_clk,
    input                           r_clk,
    input                           rst,
    input                           we,
    input                           re,
    output logic [$clog2(ADDR)-1:0] wptr,
    output logic [$clog2(ADDR)-1:0] rptr,
    output logic                    full,
    output logic                    empty
);

    logic [$clog2(ADDR)-1:0] wptr_reg, wptr_next;
    logic [$clog2(ADDR)-1:0] rptr_reg, rptr_next;
    logic full_reg, full_next;
    logic empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;


    //write
    always_ff @(posedge w_clk or posedge rst) begin : fifo_w_ff
        if (rst) begin
            wptr_reg  <= 0;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            wptr_reg  <= wptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    //read
    always_ff @(posedge r_clk or posedge rst) begin : fifo_r_ff
        if (rst) begin
            rptr_reg <= 0;
        end else begin
            rptr_reg <= rptr_next;
        end
    end

    always_comb begin : fifo_comb
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            we, re
        })
            //pop
            2'b01: begin
                if (!empty) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end
                if (wptr_reg == rptr_next) begin
                    empty_next = 1'b1;
                end
            end
            //push
            2'b10: begin
                if (!full) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end
                if (wptr_next == rptr_reg) begin
                    full_next = 1'b1;
                end
            end
            //push,pop
            2'b11: begin
                if (full) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else if (empty) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end


endmodule


module sram #(
    parameter ADDR = 16,
    parameter BIT_WIDTH = 8
) (
    input                           clk,
    input                           we,
    input        [$clog2(ADDR)-1:0] w_addr,
    input        [$clog2(ADDR)-1:0] r_addr,
    input        [   BIT_WIDTH-1:0] wdata,
    output logic [   BIT_WIDTH-1:0] rdata
);

    logic [BIT_WIDTH-1:0] sram_reg[0:ADDR-1];

    always_ff @(posedge clk) begin : sram_wdata
        if (we) begin
            sram_reg[w_addr] <= wdata;
            // $display("%t: [Mesage] sram[%h] <= %h", $time, w_addr, wdata);
        end
    end

    assign rdata = sram_reg[r_addr];
endmodule
