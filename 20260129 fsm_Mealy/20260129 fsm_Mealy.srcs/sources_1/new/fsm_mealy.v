`timescale 1ns / 1ps

module fsm_mealy(
    input clk,
    input rst,
    input din_bit,
    output dout_bit
    );

    reg [2:0] state_reg, next_state;

    parameter start = 3'b0000;
    parameter rd0_once = 3'b0001;
    parameter rd1_once = 3'b0010;
    parameter rd0_twice= 3'b0011;
    parameter rd1_twice= 3'b0010;

    always @(state_reg or din_bit) begin
        case (state_reg)
           start : if (din_bit == 0) begin
                next_state = rd0_once;            
           end else if (din_bit == 1) begin
            next_state = rd1_once;
           end else next_state = start;

           rd0_once : if (din_bit == 0) begin
                next_state = rd0_twice;            
           end else if (din_bit == 1) begin
            next_state = rd1_once;
           end else next_state = start;

           rd0_twice : if (din_bit == 0) begin
                next_state = rd0_twice;            
           end else if (din_bit == 1) begin
            next_state = rd1_once;
           end else next_state = start;

           rd1_once : if (din_bit == 0) begin
                next_state = rd0_once;            
           end else if (din_bit == 1) begin
            next_state = rd1_twice;
           end else next_state = start;

           rd1_twice : if (din_bit == 0) begin
                next_state = rd0_once;            
           end else if (din_bit == 1) begin
            next_state = rd1_twice;
           end else next_state = start;

            default: next_state = start;
        endcase
    end


always @(posedge clk ,posedge rst) begin
    if(rst == 1) state_reg <= start;
    else         state_reg <= next_state;
end

assign dout_bit = (((state_reg == rd0_twice)&&(din_bit == 0) ||
(state_reg == rd1_twice) && (din_bit == 1))) ? 1 : 0;

endmodule