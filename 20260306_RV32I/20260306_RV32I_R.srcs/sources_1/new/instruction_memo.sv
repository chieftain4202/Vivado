`timescale 1ns / 1ps

module instruction_memo (
    input  [31:0] inst_addr,
    output [31:0] inst_data
);

    logic [31:0] rom[0:31];

    initial begin
        rom[0] = 32'h005201b3;
        rom[1] = 32'h005201b3;
    end

    assign inst_data = rom[inst_addr[31:2]];
endmodule
