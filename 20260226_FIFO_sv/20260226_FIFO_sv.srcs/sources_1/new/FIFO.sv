`timescale 1ns / 1ps

module FIFO (
    input  logic       clk,
    input  logic       rclk,
    input  logic       rst,
    input  logic       we,     //push
    input  logic       re,     //pop
    input  logic [7:0] wdata,
    output logic [7:0] rdata,
    output logic       full,
    output logic       empty
);

    logic [3:0] l_wptr, l_rptr;
    logic l_full;

    register_file U_Register (
        .waddr(l_wptr),
        .raddr(l_rptr),
        .we   (~full & we), //push
        .*
    );

    control_unit U_Control (
        .wptr(l_wptr),
        .rptr(l_rptr),
        .*
    );
endmodule



module register_file (
    input  logic       clk,
    input  logic [7:0] wdata,
    input  logic [3:0] waddr,
    input  logic [3:0] raddr,
    input  logic       we,     //push
    output logic [7:0] rdata

);

    logic [7:0] reg_file[0:15];

    always_ff @(posedge clk) begin
        if (we) begin
            reg_file[waddr] <= wdata;
            //$monitor("wdata");
        end
    end
    assign rdata = reg_file[raddr];


endmodule


module control_unit (
    input  logic       clk,
    input  logic       rclk,
    input  logic       rst,
    input  logic       we,    //push
    input  logic       re,    //pop
    output logic [3:0] wptr,
    output logic [3:0] rptr,
    output logic       full,
    output logic       empty

);

    logic [1:0] c_state, n_state;
    logic [3:0] wptr_reg, wptr_next, rptr_reg, rptr_next;
    logic full_reg, full_next, empty_reg, empty_next;
    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state   <= 2'b00;
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1'b1;
        end else begin
            c_state   <= n_state;
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always_comb begin
        n_state = c_state;
        wptr_next = wptr_reg;
        rptr_next = rptr_reg;
        full_next = full_reg;
        empty_next = empty_reg;
        case ({
            we, re
        })
            //push
            2'b10: begin
                if (!full) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end

            //pop
            2'b01: begin
                if (!empty) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (rptr_next == wptr_reg) begin
                        empty_next = 1'b1;
                    end
                end
            end

            //push,pop
            2'b11: begin
                if (full_next == 1'b1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else if (empty_next == 1'b1) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    rptr_next = rptr_reg + 1;
                    wptr_next = wptr_reg + 1;
                end
            end
        endcase
    end
endmodule

