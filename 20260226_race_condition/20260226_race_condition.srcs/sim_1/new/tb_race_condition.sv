`timescale 1ns / 1ps

module tb_race_condition ();

    logic p, q;

    assign p = q;  //0

    initial begin
        q = 1;
        #1; q = 0;
        $display("%d",p);
        #1;
        $stop;
    end

endmodule
