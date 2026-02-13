`timescale 1ns / 1ps

module fsm_mealy (
    input  clk,
    input  rst,
    input  din_bit,
    output dout_bit
);

    reg [2:0] state_reg, next_state;

    parameter s0 = 3'b0000;
    parameter s1 = 3'b0001;
    parameter s2 = 3'b0010;
    parameter s3 = 3'b0011;

    always @(posedge clk, posedge rst) begin
        if (rst == 1) state_reg <= s0;
        else state_reg <= next_state;
    end


    always @(state_reg or din_bit) begin
        case (state_reg)
            s0:
            if (din_bit == 0) begin
                next_state = s1;
            end else if (din_bit == 1) begin
                next_state = s0;
            end else next_state = s0;

            s1:
            if (din_bit == 0) begin
                next_state = s1;
            end else if (din_bit == 1) begin
                next_state = s2;
            end else next_state = s0;

            s2:
            if (din_bit == 0) begin
                next_state = s3;
            end else if (din_bit == 1) begin
                next_state = s0;
            end else next_state = s0;

            s3:
            if (din_bit == 0) begin
                next_state = s1;
            end else if (din_bit == 1) begin
                next_state = s0;
            end else next_state = s0;

            default: next_state = s0;
        endcase
    end

    assign dout_bit = (state_reg == s3) && (din_bit == 1) ? 1 : 0;

endmodule
