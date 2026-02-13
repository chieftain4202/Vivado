`timescale 1ns / 1ps

module fsm_moore (
    input  clk,
    input  reset,
    input  [2:0]sw,
    output [2:0]led

);

    //state
    parameter  s0 = 3'd0, s1 = 3'd1, s2 = 3'd2, s3 = 3'd3, s4 = 3'd4 ;

    //state reg variable
    reg [2:0]current_state, next_state;   
    reg [2:0]current_led, next_led;   

    //output
    assign led = current_led;

    //state register SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_state <= s0;
            current_led <= 3'b0000;
        end else begin
            current_state <= next_state;
            current_led <= next_led;
        end
        
    end

    //next state CL
    always @(*) begin
        //this always initiallize
        next_state = current_state;
        next_led = current_led;
        //init led CL output for full case
        //led = 3'b000;
        case (current_state)
            s0: begin
                next_led = 3'b000;
                if (sw == 3'b001) begin
                    next_state = s1;
                end 
                else if (sw == 3'b010) begin
                    next_state = s2;
                end
                
            end
            s1: begin
                next_led = 3'b001;
                if (sw == 3'b010) begin
                    next_state = s2;
                end 
            end
            s2: begin
                next_led = 3'b010;
                if (sw == 3'b100) begin
                    next_state = s3;
                end
            end
            s3 : begin
                next_led = 3'b100;
                if (sw == 3'b111) begin
                    next_state = s4;
                end
                else if (sw == 3'b011)begin
                    next_state = s1;
                end
                else if (sw == 3'b000)begin
                    next_state = s0;
                end else begin
                    next_state = current_state;
                end
                
            end
            s4 : begin
                next_led = 3'b111;
                if (sw == 3'b000)begin
                    next_state = s0;
                end
                
            end    
            
          //  default: next_state = current_state;
        endcase
    end


    //output CL 
  /*  assign led = (current_state == s1) ? 2'b01:
                (current_state == s2) ? 2'b11: 2'b00;
  */

   /* always @(*) begin
        case (current_state)
            s0: led = 3'b000;
            s1: led = 3'b001;
            s2: led = 3'b010;
            s3: led = 3'b100;
            s4: led = 3'b111;
            default: led = 3'b000;
        endcase
    end
    */
endmodule
 