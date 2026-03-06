`timescale 1ns / 1ps


module tb_cpu_reg_pr();
    logic clk, rst;
    logic [7:0] out;

    cpu_rep_pr dut(
    .clk(clk),
    .rst(rst),
    .out(out)
);


    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        @(posedge clk);
        @(negedge clk);
        rst = 0;
        repeat(50)
        @(negedge clk);
        $stop;
    end


    
endmodule
