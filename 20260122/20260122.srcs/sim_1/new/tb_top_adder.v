`timescale 1ns / 1ps

module tb_top_adder();

    reg clk, reset;
    reg [7:0] a, b;
    wire [7:0] fnd_data;
    wire [7:0] fnd_digit;
    

    integer i = 0, j = 0;  //data type : 2 type, 32bit
    integer k = 0;

top_adder dut(
    .a (a),
    .b (b),
    .clk(clk),
    .reset(reset),
    .fnd_data(fnd_data),
    .fnd_digit(fnd_digit)
);


    always #5 clk = ~ clk;

    initial begin
        #0;
        clk = 0;
        reset = 1;
        a = 0;
        b = 0;
        #20;
        reset = 0;
        a = 8'b0000_0000;
        b = 8'b0000_0000;
        #10;
    for (k = 0; k < 256 ;k = k + 1)begin
        #10;
        for (i = 0; i < 256 ;i = i + 1)begin
            for (j = 0; j < 256; j = j + 1)begin
                a = i;
                b = j;
                #10;

            end
        end
    end
        #10
        $stop;
        #10;
    end

    
endmodule
