`timescale 1ns / 1ps

module top_adder (
    input [7:0] a,
    input [7:0] b,
    input [1:0] btn,
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output  c
);

    wire [7:0] w_sum;

fnd_controller U_FND_CNTL(
    .sum(w_sum),
    .btn(btn),
    .fnd_digit(fnd_digit),
    .fnd_data(fnd_data)
);

adder U_ADDER (
    .a(a),
    .b(b),
    .sum(w_sum),
    .carry(c)
);

    
endmodule


module adder (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output carry
);

    wire w_fa4_0_c, w_fa4_1_c;

    full_adder_4bit fad0(
        .a0(a[0]),
        .a1(a[1]),
        .a2(a[2]),
        .a3(a[3]),
        .b0(b[0]),
        .b1(b[1]),
        .b2(b[2]),
        .b3(b[3]),
        .cin(1'b0),
        .sum0(sum[0]),
        .sum1(sum[1]),
        .sum2(sum[2]),
        .sum3(sum[3]),
        .carry(w_fa4_0_c)
    );

    full_adder_4bit fad1(
        .a0(a[4]),
        .a1(a[5]),
        .a2(a[6]),
        .a3(a[7]),
        .b0(b[4]),
        .b1(b[5]),
        .b2(b[6]),
        .b3(b[7]),
        .cin(w_fa4_0_c),
        .sum0(sum[4]),
        .sum1(sum[5]),
        .sum2(sum[6]),
        .sum3(sum[7]),
        .carry(carry)
    );

endmodule


module full_adder_4bit (
    input a0,
    input a1,
    input a2,
    input a3,
    input b0,
    input b1,
    input b2,
    input b3,
    input cin,
    output sum0,
    output sum1,
    output sum2,
    output sum3,
    output carry
);
    wire w_fa0_c, w_fa1_c, w_fa2_c;

    full_adder U_FA0 (
        .a(a0),
        .b(b0),
        .cin(cin),
        .sum(sum0),
        .carry(w_fa0_c)
    );
    full_adder U_FA1 (
        .a(a1),
        .b(b1),
        .cin(w_fa0_c),
        .sum(sum1),
        .carry(w_fa1_c)
    );
    full_adder U_FA2 (
        .a(a2),
        .b(b2),
        .cin(w_fa1_c),
        .sum(sum2),
        .carry(w_fa2_c)
    );
    full_adder U_FA3 (
        .a(a3),
        .b(b3),
        .cin(w_fa2_c),
        .sum(sum3),
        .carry(carry)
    );

endmodule

module full_adder (
    input  a,
    input  b,
    input  cin,
    output sum,
    output carry
);

    // full adder
    assign sum   = a ^ b ^ cin;
    assign carry = (a & b) | (cin & (a ^ b));

endmodule

