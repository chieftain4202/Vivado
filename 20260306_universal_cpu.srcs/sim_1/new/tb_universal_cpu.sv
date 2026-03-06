`timescale 1ns / 1ps

module tb_universal_cpu;
    logic clk;
    logic rst;
    logic [7:0] value;

    universal_cpu dut (
        .clk  (clk),
        .rst  (rst),
        .value(value)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;

        #20 rst = 1'b0;

        // Wait for result or timeout.
        repeat (200) begin
            @(posedge clk);
            if (value == 8'd55) begin
                $display("[PASS] value=%0d at t=%0t", value, $time);
                #20;
                $finish;
            end
        end

        $error("[FAIL] timeout: expected 55, got %0d", value);
        $finish;
    end
endmodule
