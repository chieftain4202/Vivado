`timescale 1ns / 1ps


module universal_cpu ();




endmodule


module control_unit (
    input        clk,
    input        rst,
    input        ile10,
    output logic isrcsel,
    output logic sumsrcsel,
    output logic iload,
    output logic sumload,
    output logic alusrcsel,
    output logic outload
);
endmodule

module datapath (
    input              clk,
    input              rst,
    input              rf_srcsel,
    
);

    logic [7:0] oalu;


    mux_2X1 u_mux (
        .a      (0),          //sel 0
        .b      (oalu),       //sel 1
        .sel    (rf_srcsel),
        .mux_out(wd)
    );

    alu u_alu (
        .a(rd0),
        .b(rd1),
        .alu_out(oalu)
    );
endmodule



module register_file (
    
    input        [1:0] ra0,
    input        [1:0] ra1,
    input        [1:0] wa,
    input              wd,
    input              we,
    output logic [7:0] rd0,
    output logic [7:0] rd1

);
    register u_reg_0 (
        .clk    (clk),
        .rst    (rst),
        .load   (we),
        .in_data(0),
        .o_data (rd0)
    );

    register u_reg_1 (
        .clk    (clk),
        .rst    (rst),
        .load   (we),
        .in_data(wd),
        .o_data (rd0)
    );

    register u_reg_2 (
        .clk    (clk),
        .rst    (rst),
        .load   (we),
        .in_data(wd),
        .o_data (rd1)
    );

    register u_reg_3 (
        .clk    (clk),
        .rst    (rst),
        .load   (we),
        .in_data(1),
        .o_data (rd1)
    );
endmodule



module register (
    input              clk,
    input              rst,
    input              load,
    input        [7:0] in_data,
    output logic [7:0] o_data
);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            o_data <= 0;
        end else if (load) begin
            o_data <= in_data;
        end
    end

endmodule

module alu (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] alu_out
);
    assign alu_out = a + b;

endmodule

module mux_2X1 (
    input  [7:0] a,       //sel 0
    input  [7:0] b,       //sel 1
    input        sel,
    output [7:0] mux_out
);
    assign mux_out = (sel) ? b : a;
endmodule

module compare (
    input  [7:0] in_data,
    output       ocompare
);
    assign ocompare = (in_data <= 10);

endmodule
