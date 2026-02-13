//Tick mode
`timescale 1ns / 1ps

module clk_div (

    input      clk,
    input      reset,
    output reg clk_2,
    output reg clk_4,
    output reg clk_10

);
    reg [3:0] counter_10;
    reg [1:0] counter_4;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            //output init
            clk_2 <= 0;
            clk_4 <= 1'b0;
            clk_10 <= 1'b0;
            counter_4 <= 1;
            counter_10 <= 4;
        end else begin
            clk_2 <= ~clk_2;
            counter_4 <= counter_4 + 1;
            counter_10 <= counter_10 + 1;
            if (counter_4 == 1) begin
                clk_4 <= 1'b1;
            end else if (counter_4 == 3) begin
                clk_4 <= 1'b0;
                counter_4 <= 0;
            end
            if (counter_10 == 4) begin
                clk_10 <= 1'b1;
            end else if (counter_10 == 9) begin
                clk_10 <= 1'b0;
                counter_10 <= 0;
            end
        end
    end
endmodule

//default mode
/* 
`timescale 1ns / 1ps

module clk_div(

    input       clk,
    input       reset,
    output reg  clk_2,
    output reg  clk_10

    );
    reg [3:0] counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            //output init
            clk_2    <= 0;
            clk_10   <= 1'b1;
            counter  <= 0;
        end else begin
            clk_2   <= ~clk_2;
            counter <= counter + 1;
            if (counter == 4) begin
                clk_10 <= 1'b1;
            end else if (counter == 9)begin
                clk_10 <= 1'b0;
                counter <= 0;
            end
        end
    end
endmodule
*/
