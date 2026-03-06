`timescale 1ns / 1ps


module rv32i_cpu (
    input        clk,
    input        rst,
    input [31:0] inst_data,
    input [31:0] inst_addr
);
    logic rfwe;
    logic [31:0] rd1, rd2, alu_result;
    logic [2:0] alucon;

    register_file u_reg_file (
        .clk  (clk),
        .rst  (rst),
        .rf_we(rfwe),
        .ra1  (inst_data[19:15]),
        .ra2  (inst_data[24:20]),
        .wa   (inst_data[11:7]),
        .wdata(alu_result),
        .rd1  (rd1),
        .rd2  (rd2)
    );

    control_unit u_control_unit (
        .clk   (clk),
        .rst   (rst),
        .func7 (inst_data[31:25]),
        .func3 (inst_data[14:12]),
        .opcode(inst_data[6:0]),
        .alucon(alucon),
        .rf_we (rfwe)
    );

    alu u_alu (
        .rd1       (rd1),
        .rd2       (rd2),
        .alucon    (alucon),
        .alu_result(alu_result)
    );
endmodule

module register_file (
    input         clk,
    input         rst,
    input         rf_we,
    input  [ 4:0] ra1,
    input  [ 4:0] ra2,
    input  [ 4:0] wa,
    input  [31:0] wdata,
    output [31:0] rd1,
    output [31:0] rd2
);

endmodule

module control_unit (
    input        clk,
    input        rst,
    input  [6:0] func7,
    input  [2:0] func3,
    input  [6:0] opcode,
    output [2:0] alucon,
    output       rf_we
);

endmodule

module alu (
    input  [31:0] rd1,
    input  [31:0] rd2,
    input  [ 2:0] alucon,
    output [31:0] alu_result
);

endmodule
