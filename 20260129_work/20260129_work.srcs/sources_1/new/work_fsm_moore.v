`timescale 1ns / 1ps


module work_fsm_moore (
    input  clk,
    input  reset,
    input  sw,
    output out
);

    //state
    parameter s0 = 3'd0, s1 = 3'd1, s2 = 3'd2, s3 = 3'd3, s4 = 3'd4;

    reg [2:0] current_state, next_state;
    reg current_out, next_out;

    // assign out = current_out;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_state <= s0;
            current_out   <= 0;
        end else begin
            current_state <= next_state;
            current_out   <= next_out;
        end
    end


    always @(*) begin
        next_state = current_state;
        next_out   = current_out;
        case (current_state)
            s0: begin
                next_out = 0;
                if (sw == 0) next_state = s1;
                else if (sw == 1) next_state = s0;
            end

            s1: begin
                if (sw == 0) next_state = s1;
                else if (sw == 1) next_state = s2;
            end

            s2: begin
                if (sw == 0) next_state = s3;
                else if (sw == 1) next_state = s0;
            end

            s3: begin
                if (sw == 0) next_state = s1;
                else if (sw == 1) next_state = s4;
            end

            s4: begin
                if (sw == 0) next_state = s1;
                else if (sw == 1) next_state = s0;
            end

            //   default: 
        endcase
    end

    assign out = (current_state == s4) && (sw == 1) ? 1 : 0;


endmodule
