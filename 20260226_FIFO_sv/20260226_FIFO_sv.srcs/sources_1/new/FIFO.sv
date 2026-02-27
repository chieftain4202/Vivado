`timescale 1ns / 1ps

module FIFO (
    input  logic [7:0] wdata,
    input  logic       we,     //push
    input  logic       re,     //pop
    input  logic       wclk,
    input  logic       rclk,
    output logic [7:0] rdata,
    output logic       empty
);

    logic [3:0] l_wptr, l_rptr;
    logic l_full;

    register_file U_Register(
    .clk(wclk),
    .wdata(wdata),
    .waddr(l_wptr),
    .raddr(l_rptr),
    .we(we),     //push
    .rdata(rdata)
);

    control_unit U_Control(
    .wclk(wclk),
    .rclk(rclk),
    .we(we),    //push
    .re(re),    //pop
    .wptr(l_wptr),
    .rptr(l_rptr),
    .full(l_full),
    .empty(empty)

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

    logic [7:0] reg_file[0:255];

    always_ff @(posedge clk) begin
        if (we) begin
            reg_file[waddr] <= wdata;
        end  
    end
        assign rdata = reg_file[raddr];

endmodule


module control_unit (
    input  logic wclk,
    input  logic rclk,
    input  logic we,    //push
    input  logic re,    //pop
    output logic [3:0] wptr,
    output logic [3:0] rptr,
    output logic full,
    output logic empty

);

    reg [1:0] c_state, n_state;
    reg [3:0] wptr_reg, wptr_next, rptr_reg, rptr_next;
    reg full_reg, full_next, empty_reg, empty_next;
    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge wclk) begin
        if (!we) begin
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
                    empty_next = 1'd0;
                    if (wptr_next == rptr_reg) begin
                        empty_next = 1'd1;
                    end
                end
            end

            //pop
            2'b01: begin
                if (!empty) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'd0;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'd1;
                    end
                end
            end

            //push,pop
            2'b11: begin
                if (full_next == 1'd1) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'd0;
                end else if (empty_next == 1'd1) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'd0;
                end else begin
                    rptr_next = rptr_reg + 1;
                    wptr_next = wptr_reg + 1;
                end
            end
        endcase
    end
endmodule

