`timescale 1ns / 1ps



module cpu_rep (
    input        clk,
    input        rst,
    output [7:0] out

);

    logic losel, lasrcsel, laload, lbload, lcompare;
    control_unit u_con (
        .clk    (clk),
        .rst    (rst),
        .compare(lcompare),
        .asrcsel(lasrcsel),
        .aload  (laload),
        .bload  (lbload),
        .outsel (losel)
    );

    datapath u_data (
        .clk     (clk),
        .rst     (rst),
        .asrcsel (lasrcsel),
        .aload   (laload),
        .bload   (lbload),
        .cosel   (losel),
        .vcompare(lcompare),
        .odata   (out)
    );

endmodule


module control_unit (
    input        clk,
    input        rst,
    input        compare,
    output logic asrcsel,
    output logic aload,
    output logic bload,
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
        bload = 0;
        outsel = 0;
        case (c_st)
            s0: begin
                asrcsel = 0;
                aload   = 0;
                bload   = 0;
                outsel  = 0;
                n_st    = s1;
            end
            s1: begin
                asrcsel = 0;
                aload   = 0;
                bload   = 0;
                outsel  = 0;
                if (!compare) begin
                    n_st = s2;
                end else begin
                    n_st = s4;
                end
            end
            s2: begin
                asrcsel = 0;
                aload   = 0;
                bload   = 0;
                outsel  = 1;
                n_st    = s3;
            end
            s3: begin
                asrcsel = 1;
                aload = 1;
                bload = 1;
                outsel = 0;
                n_st = s1;
            end
            s4: begin
                asrcsel = 0;
                aload = 0;
                bload = 0;
                outsel = 0;
                n_st = s4;
            end

        endcase

    end

endmodule

module datapath (
    input        clk,
    input        rst,
    input        asrcsel,
    input        aload,
    input        bload,
    input        cosel,
    output       vcompare,
    output [7:0] odata
);

    logic [7:0] lareg, lbreg, lalu, lomux;
    assign odata   = (cosel) ? lalu : 1'dz;

    areg u_areg (
        .clk  (clk),
        .rst  (rst),
        .idata(lomux),
        .iload(aload),
        .oareg(lareg)
    );

    breg u_breg (
        .clk  (clk),
        .rst  (rst),
        .idata(lomux),
        .iload(bload),
        .obreg(lbreg)
    );

    alu u_alu (
        .ia  (lareg),
        .ib  (lbreg),
        .oalu(lalu)
    );

    mux_2X1 u_mux (
        .ia(0),
        .ib(lalu),
        .asrcsel(asrcsel),
        .omux(lomux)

    );

    acompare u_compare (
        .iacom(lbreg),
        .oac  (vcompare)
    );
endmodule

module acompare (
    input  [7:0] iacom,
    output       oac
);
    assign oac = (iacom < 8'd11) ? 0 : 1;
endmodule

module areg (
    input        clk,
    input        rst,
    input  [7:0] idata,
    input        iload,
    output [7:0] oareg
);

    logic [7:0] alog;

    assign oareg = alog;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            alog <= 0;
        end else begin
            if (iload) begin
                alog <= idata;
            end
            
        end

    end

endmodule

module breg (
    input        clk,
    input        rst,
    input  [7:0] idata,
    input        iload,
    output [7:0] obreg
);

    logic [7:0] blog;

    assign obreg = blog;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            blog <= 0;
        end else begin
            if (iload) begin
                blog <= idata;
                blog <= blog + 1;
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
