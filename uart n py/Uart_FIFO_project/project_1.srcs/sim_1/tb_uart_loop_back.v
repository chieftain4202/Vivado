`timescale 1ns / 1ps

module tb_uart_loop_back ();

    parameter BAUD = 9600;
    parameter BAUD_REPIOD = (100_000_000 / BAUD) * 10;  //104_160
    integer i = 0, j = 0;


    reg clk, rst, rx;
    wire tx;
    reg [7:0] test_data;


    uart_top U_DUT (
        .clk(clk),
        .rst(rst),
        .uart_rx(rx),
        .uart_tx(tx)
    );


    initial clk = 1'b0;
    always #5 clk = ~clk;


    task uart_sender();
        begin
            #(BAUD_REPIOD);
            for (i = 0; i < 8; i = i + 1) begin
                rx = test_data[i];
                #(BAUD_REPIOD);
            end
            //stop
            rx = 1'b1;
            #(BAUD_REPIOD);
        end
    endtask

    initial begin
        rst       = 1;
        rx        = 1;
        test_data = 8'h30;  //ascii = 0
        repeat (5) @(posedge clk);
        rst = 0;
        //uart test pattern
        //start
        rx  = 0;
        //data
        for (j = 0; j < 10; j = j + 1) begin
            test_data = 8'h30 + j;
            uart_sender();
        end

        //hold uart tx output
        for (j = 0; j < 8; j = j + 1) begin
            rx = test_data[j];
            #(BAUD_REPIOD);
        end

        // stop
        #(BAUD_REPIOD);
        $stop;
    end
endmodule
