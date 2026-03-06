`timescale 1ns / 1ps

module rv32i_top (
    input clk,
    input rst
);

    logic [31:0] inst_addr, inst_data;

    instruction_memo u_inst_mem (.*);

    rv32i_cpu u_cpu (.*);
endmodule
