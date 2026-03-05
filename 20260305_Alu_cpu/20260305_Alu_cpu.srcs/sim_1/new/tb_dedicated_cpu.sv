`timescale 1ns / 1ps


module tb_dedicated_cpu(

    );
    logic clk, rst;
    logic [7:0] out;

    dedicated_cpu dut (
    .clk(clk),
    .rst(rst),
    .out(out)

);



always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    #20;
    rst = 0;
    #400;
    $stop;

end
endmodule
