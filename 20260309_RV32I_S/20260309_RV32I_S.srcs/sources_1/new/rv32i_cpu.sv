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
    output string o_opcode_type_name,
    output        dwe
);

    logic rf_we, alu_src, branch, jal, jalr;
    logic [ 2:0] rfwd_src;
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
        .o_opcode_type_name(o_opcode_type_name),
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
    output string      o_opcode_type_name,
    output logic       dwe,
    output logic [2:0] rfwd_src,
    output logic       branch,
    output logic [3:0] alu_control
);

    always_comb begin
        alu_control = 4'b0000;
        rf_we       = 1'b0;
        alu_src     = 1'b0;
        rfwd_src    = 3'b000;
        o_funct3    = 3'b000;
        o_opcode_type_name = "UNKNOWN";
        dwe         = 1'b0;
        branch      = 0;
        jal         = 0;
        jalr        = 0;
        case (opcode)
            // R-type, to write register file, alu_contrl == {funct7[5], funct3}
            `R_TYPE: begin
                o_opcode_type_name = "R_TYPE";
                rf_we       = 1'b1;  // write register
                alu_src     = 1'b0;  // 0 = rs2, 1 = imm 
                alu_control = {funct7[5], funct3};  // funct7, funct3 [3:0]
                rfwd_src    = 3'b000;  // o_alu value sel mux
                o_funct3    = 3'b000;  // data_mem control (M)
                dwe         = 1'b0;  // data mem control write
                branch      = 0;  // for control B Type
                jal         = 0;  // for jal
                jalr        = 0;  // for jalr
            end
            `S_TYPE: begin
                o_opcode_type_name = "S_TYPE";
                rf_we       = 1'b0;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 3'b001;
                o_funct3    = funct3;
                dwe         = 1'b1;
                branch      = 0;
                jal         = 0;
                jalr        = 0;

            end
            `IL_TYPE: begin
                o_opcode_type_name = "IL_TYPE";
                rf_we       = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 3'b001;
                o_funct3    = funct3;
                dwe         = 1'b0;
                branch      = 0;
                jal         = 0;
                jalr        = 0;
            end
            `I_TYPE: begin
                o_opcode_type_name = "I_TYPE";
                rf_we   = 1'b1;
                alu_src = 1'b1;

                if (funct3 == 3'b101) begin
                    alu_control = {funct7[5], funct3};
                end else begin
                    alu_control = {1'b0, funct3};
                end

                rfwd_src = 3'b000;
                o_funct3 = funct3;
                dwe      = 1'b0;
                branch   = 0;
                jal      = 0;
                jalr     = 0;
            end
            `B_TYPE: begin
                o_opcode_type_name = "B_TYPE";
                rf_we       = 1'b0;
                alu_src     = 1'b0;
                alu_control = {1'b0, funct3};
                rfwd_src    = 3'b000;
                o_funct3    = funct3;
                dwe         = 1'b0;
                branch      = 1'b1;
                jal         = 0;
                jalr        = 0;
            end


            `U_TYPE: begin
                o_opcode_type_name = "U_TYPE";
                rf_we       = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 3'b011;
                o_funct3    = 3'b000;
                dwe         = 1'b0;
                branch      = 1'b0;
                jal         = 0;
                jalr        = 0;
            end
            `UL_TYPE: begin
                o_opcode_type_name = "UL_TYPE";
                rf_we       = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 3'b010;
                o_funct3    = 3'b000;
                dwe         = 1'b0;
                branch      = 1'b0;
                jal         = 0;
                jalr        = 0;
            end
            `J_TYPE: begin
                o_opcode_type_name = "J_TYPE";
                rf_we       = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 3'b100;
                o_funct3    = 3'b000;
                dwe         = 1'b0;
                branch      = 1'b0;
                jal         = 1;
                jalr        = 0;
            end
            `JL_TYPE: begin
                o_opcode_type_name = "JL_TYPE";
                rf_we       = 1'b1;
                alu_src     = 1'b0;
                alu_control = 4'b0000;
                rfwd_src    = 3'b100;
                o_funct3    = funct3;
                dwe         = 1'b0;
                branch      = 1'b0;
                jal         = 1;
                jalr        = 1;
            end
        endcase
    end
endmodule
