`timescale 1ns / 1ps
`include "define.vh"

module rv32i_cpu (
    input         clk,
    input         rst,
    input  [31:0] instr_data,
    input  [31:0] drdata,
    output [31:0] instr_addr,
    output [31:0] daddr,
    output [31:0] dwdata,
    output [ 2:0] o_funct3,
    output        dwe
);

    logic rf_we, alu_src, rfwd_src, branch, jal, jalr;
    logic [ 3:0] alu_control;
    logic [31:0] alu_result;

    control_unit U_CONTROL_UNIT (
        .rst        (rst),
        .funct7     (instr_data[31:25]),
        .funct3     (instr_data[14:12]),
        .opcode     (instr_data[6:0]),
        .rf_we      (rf_we),
        .alu_src    (alu_src),
        .dwe        (dwe),
        .jal        (jal),
        .jalr       (jalr),
        .rfwd_src   (rfwd_src),
        .o_funct3   (o_funct3),
        .branch     (branch),
        .alu_control(alu_control)
    );

    rv32I_datapath u_datapath (
        .clk        (clk),
        .rst        (rst),
        .rf_we      (rf_we),
        .alu_src    (alu_src),
        .alu_control(alu_control),
        .instr_data (instr_data),
        .drdata     (drdata),
        .jal        (jal),
        .jalr       (jalr),
        .rfwd_src   (rfwd_src),
        .instr_addr (instr_addr),
        .daddr      (daddr),
        .branch     (branch),
        .dwdata     (dwdata)

    );
endmodule


module control_unit (
    input              rst,
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    output logic       rf_we,
    output logic       alu_src,
    output logic       jal,
    output logic       jalr,
    output logic [2:0] o_funct3,
    output logic       dwe,
    output logic       rfwd_src,
    output logic       branch,
    output logic [3:0] alu_control
);

    always_comb begin
        alu_control = 4'b0000;
        rf_we       = 1'b0;
        alu_src     = 1'b0;
        rfwd_src    = 1'b0;
        o_funct3    = 3'b000;
        dwe         = 1'b0;
        branch      = 0;
        jal         = 0;
        jalr        = 0;
        case (opcode)
            // R-type, to write register file, alu_contrl == {funct7[5], funct3}
            `R_TYPE: begin
                rf_we       = 1'b1;
                alu_src     = 1'b0;
                alu_control = {funct7[5], funct3};
                rfwd_src    = 1'b0;
                o_funct3    = 3'b000;
                dwe         = 1'b0;
                branch      = 0;
            end
            `S_TYPE: begin
                rf_we       = 1'b0;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 1'b0;
                o_funct3    = funct3;
                dwe         = 1'b1;
                branch      = 0;

            end
            `IL_TYPE: begin
                rf_we       = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 1'b1;
                o_funct3    = funct3;
                dwe         = 1'b0;
                branch      = 0;
            end
            `I_TYPE: begin
                rf_we   = 1'b1;
                alu_src = 1'b1;

                if (funct3 == 3'b101) begin
                    alu_control = {funct7[5], funct3};
                end else begin
                    alu_control = {1'b0, funct3};
                end

                rfwd_src = 1'b0;
                o_funct3 = funct3;
                dwe      = 1'b0;
                branch   = 0;
            end
            `B_TYPE: begin
                rf_we       = 1'b0;
                alu_src     = 1'b0;
                alu_control = {1'b0, funct3};
                rfwd_src    = 1'b0;
                o_funct3    = funct3;
                dwe         = 1'b0;
                branch      = 1'b1;
            end
            `U_TYPE: begin
                ;
            end
            `UL_TYPE: begin
                ;
            end
            `J_TYPE: begin
                ;
            end
            `JL_TYPE: begin
                ;
            end
        endcase
    end
endmodule


