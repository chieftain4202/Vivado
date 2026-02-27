`timescale 1ns / 1ps


module register_8bit(
    input clk,
    input rst,
    output [7:0] data
    );
     logic [7:0] wdata;
    logic [7:0] rdata;

    assign data = rdata;

    reg current_reg, next_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            wdata <= 0;
            rdata <= 0;
        end else begin
            current_reg <= next_reg;
        end
    end

    always_comb begin
        next_reg = current_reg;

    end
    
endmodule
