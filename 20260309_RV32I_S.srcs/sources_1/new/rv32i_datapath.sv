`timescale 1ns / 1ps
`include "define.vh"

module rv32I_datapath (
    input         clk,
    input         rst,
    input         rf_we,
    input         alu_src,
    input  [ 3:0] alu_control,
    input  [31:0] instr_data,
    output [31:0] instr_addr

);

    logic [31:0] rd1, rd2, alu_result, imm_data, alurs2_data;

    program_counter u_pc (
        .clk(clk),
        .rst(rst),
        .instr_addr(),
        .program_counter(instr_addr)
    );

    register_file U_REG_FILE (
        .clk  (clk),
        .rst  (rst),
        .ra1  (instr_data[19:15]),
        .ra2  (instr_data[24:20]),
        .wa   (instr_data[11:7]),
        .Wdata(alu_result),
        .rf_we(rf_we),
        .rd1  (rd1),
        .rd2  (rd2)
    );

    imm_extender u_imm_extend (
        .instr_data(instr_data),
        .imm_data  (imm_data)
    );

    mux2x1 u_mux (
        .in0(rd2),
        .in1(imm_data),
        .sel(alu_src),
        .out_mux(alurs2_data)
    );

    alu U_ALU (
        .rd1        (rd1),
        .rd2        (alurs2_data),
        .alu_control(alu_control),
        .alu_result (alu_result)
    );
endmodule

module mux2x1 (
    input        [31:0] in0,
    input        [31:0] in1,
    input               sel,
    output logic [31:0] out_mux
);
    assign out_mux = (sel) ? in1 : in0;

endmodule

module imm_extender (
    input [31:0] instr_data,
    output logic [31:0] imm_data
);

    always_comb begin
        imm_data = 32'd0;
        case (instr_data[6:0])  //opcode
            `S_TYPE: begin
                imm_data = {
                    {20{instr_data[31]}}, instr_data[31:25], instr_data[11:7]
                };
            end
        endcase
    end
endmodule

module register_file (
    input         clk,
    input         rst,
    input  [ 4:0] ra1,    //instruction code rs1
    input  [ 4:0] ra2,
    input  [ 4:0] wa,     //instruction RD write data
    input  [31:0] Wdata,  //
    input         rf_we,
    output [31:0] rd1,
    output [31:0] rd2
);
    logic [31:0] register_file[0:31];

`ifdef SIMULATION
    initial begin
        for (int i = 0; i < 32; i++) begin
            register_file[i] = i;
        end
    end
`endif

    always_ff @(posedge clk) begin
        if (!rst & rf_we) begin
            register_file[wa] <= Wdata;
        end
    end

    //output CL
    assign rd1 = register_file[ra1];
    assign rd2 = register_file[ra2];

endmodule

module alu (
    input        [31:0] rd1,          // rs1
    input        [31:0] rd2,          // rs2
    input        [ 3:0] alu_control,  // funct7[6], funct3 : 4bit 
    output logic [31:0] alu_result
);

    always_comb begin
        alu_result = 32'h0;
        case (alu_control)
            `ADD: alu_result = rd1 + rd2;  // add rd = rs1 + rs2
            `SUB: alu_result = rd1 - rd2;  //sub rd = rs1 - rs2;
            `SLL: alu_result = rd1 << rd2[4:0];  //sll rd = rs1 << rs2;
            `SLT:
            alu_result = ($signed(rd1) < $signed(rd2)) ? 1 :
                0;  //slt rd = (rs1 < rs2) ? 1 : 0;
            `SLTU:
            alu_result = (rd1 < rd2) ? 1 : 0;  //slt rd = (rs1 < rs2) ? 1 : 0;
            `XOR: alu_result = rd1 ^ rd2;  //xor rd = rs1 ^ rs2
            `SRL: alu_result = rd1 >> rd2[4:0];  //SRL rd = rs1 >> rs2
            `SRA:
            alu_result = ($signed(rd1) >>> rd2[4:0])
                ;  //SRA rd = rs1 >>> rs2 , msb extention, althmatic right shift
            `OR: alu_result = rd1 | rd2;  // or rd = rs1 | rs2
            `AND: alu_result = rd1 & rd2;  // and rd = rs1 & rs2
        endcase
    end

endmodule

module program_counter (
    input         clk,
    input         rst,
    input  [31:0] instr_addr,
    output [31:0] program_counter
);

    logic [31:0] pc_alu_out;

    pc_alu u_pc_alu (
        .a(32'd4),
        .b(program_counter),
        .pc_alu_out(pc_alu_out)
    );

    register u_pc_reg (
        .clk(clk),
        .rst(rst),
        .data_in(pc_alu_out),
        .data_out(program_counter)
    );

endmodule

module pc_alu (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] pc_alu_out
);
    assign pc_alu_out = a + b;
endmodule

module register (
    input         clk,
    input         rst,
    input  [31:0] data_in,
    output [31:0] data_out
);

    logic [31:0] register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 0;
        end else begin
            register <= data_in;
        end
    end

    assign data_out = register;

endmodule
