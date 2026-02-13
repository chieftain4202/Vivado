`timescale 1ns / 1ps

module tb_top_counter_10000 ();

        reg clk, reset, mode_sw_0;
        wire [7:0] fnd_data;
        wire [3:0] fnd_digit;
    
    top_counter_10000 dut(
        .clk(clk),
        .reset(reset),
        .mode_sw_0(mode_sw_0),
        .fnd_data(fnd_data),
        .fnd_digit(fnd_digit)
    );
   

    always #5 clk = ~clk;
    always #10 tick = ~tick;

    initial begin
        #0;
        clk = 0;
        tick = 0;
        clear = 1;
        switch = 0;
        stop = 0;
        reset = 1;
        #10;
        reset = 0;
        #20;
        clear = 0;
        #200_00;
        switch = 1;
        #100_00;
        switch = 0;
        #100_00;
        stop = 1;
        #100_00;
        stop = 0;
        #100_00;
        clear = 1;
        #100_00;
        clear = 0;
        #10 
        $stop;
    end


endmodule
