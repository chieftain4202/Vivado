`timescale 1ns / 1ps

module tb_top_adder();

    reg [7:0] a,b;
    wire c;
    wire [7:0]fnd_data;
    wire [3:0]fnd_digit;

    integer i = 0, j = 0;  //data type : 2 type, 32bit

top_adder dut(
    .a (a),
    .b (b),
    .c (c),
    .fnd_data(fnd_data),
    .fnd_digit(fnd_digit)
);

    initial begin
        #0;
        a = 8'b0000_0000;
        b = 8'b0000_0000;
        #10;

        for (i = 0; i < 256 ;i = i + 1)begin
            for (j = 0; j < 256; j = j + 1)begin
                a = i;
                b = j;
                #10;

        end
    end
        #10
        $stop;
        #10;
    end

    
endmodule
