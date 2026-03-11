`timescale 1ns / 1ps

module instruction_mem (
    input  [31:0] instr_addr,
    output [31:0] instr_data
);

    logic [31:0] rom[0:31];

    initial begin
        /*rom[0] = 32'h004182b3;  // ADD X5, X3, X4
        rom[1] = 32'h40418333;  // SUB  x6,  x3, x4
        rom[2] = 32'h004193B3;  // SLL  x7,  x3, x4*/
        rom[0] = 32'h0041B2B3;  // SLTU x5, x3, x4
        rom[1] = 32'h00323333;  // SLTU x6, x4, x3
        rom[2] = 32'h40735433;  // SRA  x8, x6, x7
        rom[3] = 32'h404354B3;  // SRA  x9, x6, x4
    end


    // rom[1] = 32'h00812123;  // SW x2, 2(x8),  sw x2,x8,2
    // rom[2] = 32'h009100a3;  // SB x2, 0(x8)
    // rom[3] = 32'h007100A3;

    //    rom[2] = 32'h00212383;  // LW x7, X2, 2
    //    rom[3] = 32'h00438413;  // ADDi X8, X7, 4
    //    rom[1] = 32'h005201b3;

    assign instr_data = rom[instr_addr[31:2]];

endmodule


module data_mem (
    input         clk,
    input         rst,
    input         dwe,
    input  [ 2:0] i_funct3,
    input  [31:0] daddr,
    input  [31:0] dwdata,
    output [31:0] drdata
);

    //byte address

    //    logic [7:0] dmem[0:31];
    //
    //    always_ff @(posedge clk) begin
    //
    //        if (dwe) begin
    //            //store word 일 때만, 이렇게? 
    //            dmem[daddr+0] <= dwdata[7:0];
    //            dmem[daddr+1] <= dwdata[15:8];
    //            dmem[daddr+2] <= dwdata[23:16];
    //            dmem[daddr+3] <= dwdata[31:24];
    //        end
    //    end
    //
    //    assign drdata = {
    //        dmem[daddr], dmem[daddr+1], dmem[daddr+2], dmem[daddr+3]
    //    };

    //word address

    logic [31:0] dmem[0:31];  //word로 word address
    always_ff @(posedge clk) begin
        if (dwe) begin
            if (i_funct3 == 3'b000) dmem[daddr[31:2]][7:2] <= dwdata;  // SB
            if (i_funct3 == 3'b001) dmem[daddr[31:2]][15:2] <= dwdata;  // SH
            if (i_funct3 == 3'b010) dmem[daddr[31:2]] <= dwdata;  // SW
        end else begin
            if (i_funct3 == 3'b000) dmem[daddr[31:2]][7:2] <= dwdata;  // LB
            if (i_funct3 == 3'b001) dmem[daddr[31:2]][15:2] <= dwdata;  // LH
            if (i_funct3 == 3'b010) dmem[daddr[31:2]] <= dwdata;  // LW
            if (i_funct3 == 3'b000)
                dmem[daddr[31:2]] <= {24'b0, dwdata[7:0]};  // LBU
            if (i_funct3 == 3'b001)
                dmem[daddr[31:2]] <= {16'b0, dwdata[15:0]};  // LHU

        end
    end

    assign drdata = dmem[daddr[31:2]]; //data가 byte로 오니까 밑에 2bit 짜르기 

endmodule
