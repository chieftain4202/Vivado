`timescale 1ns / 1ps

module ram (
    input            clk,
    input            we,
    input      [9:0] addr,
    input      [7:0] wdata,
    output reg [7:0] rdata
);

    //ram space
    reg [7:0] ram[0:1023];

    //to write to RAM
    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= wdata;
        end
        else begin
            rdata <= ram[addr];
        end
    end

    //output CL
    //        assign rdata = ram[addr];


endmodule
