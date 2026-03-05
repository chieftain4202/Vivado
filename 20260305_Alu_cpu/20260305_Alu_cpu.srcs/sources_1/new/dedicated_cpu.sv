`timescale 1ns / 1ps

module dedicated_cpu (
    input  bit         clk,
    input  bit         rst,
    output logic [7:0] out

);
    logic lasrcsel, laload, lequal, losel;
    logic [3:0] lacom;
    logic [7:0] odata;


    datapath u_datapath (
        .clk    (clk),
        .rst    (rst),
        .asrcsel(lasrcsel),
        .aload  (laload),
        .outsel (losel),
        .equal  (lequal),
        .out    (out)
    );

    control_unit u_control (
        .clk     (clk),
        .rst     (rst),
        .acompare(lequal),
        .asrcsel (lasrcsel),
        .outsel  (losel),
        .aload   (laload)
    );

endmodule


module acompare (
    input  [7:0] iacom,
    output       oac
);
    assign oac = (iacom < 10) ? 0 : 1;
endmodule


module control_unit (
    input        clk,
    input        rst,
    input        acompare,
    output logic asrcsel,
    output logic aload,
    output logic outsel
);
    typedef enum logic [2:0] {
        s0 = 0,
        s1 = 1,
        s2 = 2,
        s3 = 3,
        s4 = 4
    } state_t;
    state_t c_st, n_st;

    logic [1:0] cnt_reg;
    logic nasrcsel, naload;
    logic [3:0] acnt, acom;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_st <= s0;
        end else begin
            c_st <= n_st;
        end
    end

    always_comb begin
        n_st = c_st;
        asrcsel = 0;
        aload = 0;
        outsel = 0;
        case (c_st)
            s0: begin
                asrcsel = 0;
                aload   = 0;
                outsel  = 0;
                n_st    = s1;
            end
            s1: begin
                    asrcsel = 0;
                    aload   = 0;
                    outsel  = 0;
                if (!acompare) begin
                    n_st    = s2;
                end else begin 
                    n_st = s4;
                end
            end
            s2: begin
                asrcsel = 0;
                aload   = 0;
                outsel  = 1;
                n_st    = s3;
            end
            s3: begin
                asrcsel = 1;
                aload   = 1;
                outsel  = 0;
                n_st = s1;
            end
            s4: begin
                asrcsel = 0;
                aload   = 0;
                outsel  = 1;
                n_st = s4;
            end
        endcase

    end
endmodule


module datapath (
    input              clk,
    input              rst,
    input              asrcsel,
    input              aload,
    input              outsel,
    output             equal,
    output logic [7:0] out
    
);

    logic [7:0] woalu;
    logic [7:0] womux, woreg;
    assign out = (outsel) ? woreg : 1'dz;

    mux_2X1 u_mux (
        .ia(0),
        .ib(woalu),
        .asrcsel(asrcsel),
        .omux(womux)
    );
    areg u_areg (
        .clk(clk),
        .rst(rst),
        .idata(womux),
        .iaload(aload),
        .rout(woreg)
    );

    alu u_alu (
        .ia  (woreg),
        .ib  (8'h1),
        .oalu(woalu)
    );

    acompare u_compare (
        .iacom(woalu),
        .oac  (equal)
    );


endmodule

module areg (
    input        clk,
    input        rst,
    input  [7:0] idata,
    input        iaload,
    output [7:0] rout
);
    logic [7:0] areg;

    assign rout = areg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            areg <= 0;
        end else begin
            if (iaload) begin
                areg <= idata;
            end
        end
    end

endmodule

module alu (
    input  [7:0] ia,
    input  [7:0] ib,
    output [7:0] oalu
);
    assign oalu = ia + ib;

endmodule

module mux_2X1 (
    input  [7:0] ia,
    input  [7:0] ib,
    input        asrcsel,
    output [7:0] omux
);

    assign omux = (asrcsel) ? ib : ia;

endmodule
