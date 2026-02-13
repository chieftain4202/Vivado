`timescale 1ns / 1ps

module tb_work ();

    reg [7:0] a, b;
    wire [7:0] sum;
    wire carry;

    integer i = 0, j = 0;  //data type : 2 type, 32bit

    full_adder_8bit dut(
    .a (a),
    .b (b),
    .sum(sum),
    .carry (carry)

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
