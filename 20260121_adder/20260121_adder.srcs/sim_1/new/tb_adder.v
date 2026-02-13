`timescale 1ns / 1ps

module tb_adder ();

    // tb_adder lacal variable
    reg a, b, cin;
    wire sum, carry;

    //instanciate half_adder
 /*   half_adder dut (  //dut : instanciate name : design under test
        .a(a),
        .b(b),
        .sum(sum),
        .carry(carry)
    );
*/

    //instanciate full adder

    full_adder dut(
    .a(a),
    .b(b),
    .cin(cin),
    .sum(sum),
    .carry(carry)

);

    //init
    initial begin
        #0;
        a = 0;
        b = 0;
        cin = 0;
        #10;
        a = 1;
        b = 0;
        cin = 0;
        #10;
        a = 0;
        b = 1;
        cin = 0;
        #10;
        a = 1;
        b = 1;
        cin = 0;
        #10;
        a = 0;
        b = 0;
        cin = 1;
        #10;
        a = 1;
        b = 0;
        cin = 1;
        #10;
        a = 0;
        b = 1;
        cin = 1;
        #10;
        a = 1;
        b = 1;
        cin = 1;

        #10;
        $stop;
        #100;
        $finish;


    end
endmodule
