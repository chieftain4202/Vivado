`timescale 1ns / 1ps


module cpu_rep_pr (
    input        clk,
    input        rst,
    output [7:0] out
);
    logic isrcsel, ile10, sumsrcsel, iload, sumload, alusrcsel, outload;

    datapath u_datapath (.*);

    control_unit u_control (.*);

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

    typedef enum logic [2:0] {
        s0,
        s1,
        s2,
        s3,
        s4,
        s5
    } state_t;

    state_t c_state, n_state;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= s0;
        end else begin
            c_state <= n_state;
        end
    end

    //next, output
    always_comb begin
        n_state   = c_state;
        isrcsel   = 0;
        sumsrcsel = 0;
        iload     = 0;
        sumload   = 0;
        alusrcsel = 0;
        outload   = 0;
        case (c_state)
            s0: begin
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 1;
                sumload   = 1;
                alusrcsel = 0;
                outload   = 0;
                n_state   = s1;
            end
            s1: begin
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 0;
                sumload   = 0;
                alusrcsel = 0;
                outload   = 0;
                if (ile10 == 1) begin
                    n_state = s2;
                end else n_state = s5;
            end
            s2: begin
                isrcsel   = 0;
                sumsrcsel = 1;
                iload     = 0;
                sumload   = 1;
                alusrcsel = 0;
                outload   = 0;
                n_state   = s3;
            end
            s3: begin
                isrcsel   = 1;
                sumsrcsel = 0;
                iload     = 1;
                sumload   = 0;
                alusrcsel = 1;
                outload   = 0;
                n_state   = s4;
            end
            s4: begin
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 0;
                sumload   = 0;
                alusrcsel = 0;
                outload   = 1;
                n_state   = s1;
            end
            s5: begin
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 0;
                sumload   = 0;
                alusrcsel = 0;
                outload   = 0;
                n_state   = s5;
            end

        endcase

    end

endmodule


module datapath (
    input        clk,
    input        rst,
    input        isrcsel,
    input        sumsrcsel,
    input        iload,
    input        sumload,
    input        alusrcsel,
    input        outload,
    output       ile10,
    output [7:0] out
);

    logic [7:0]
        ireg_src_data,
        ireg_out,
        sumreg_src_data,
        sumreg_out,
        alu_src_data,
        alu_out;

    register u_outreg (
        .clk(clk),
        .rst(rst),
        .load(outload),
        .in_data(sumreg_out),
        .o_data(out)
    );

    register u_ireg (
        .clk(clk),
        .rst(rst),
        .load(iload),
        .in_data(ireg_src_data),
        .o_data(ireg_out)
    );

    mux_2X1 u_ireg_src_mux (
        .a      (0),             //sel 0
        .b      (alu_out),       //sel 1
        .sel    (isrcsel),
        .mux_out(ireg_src_data)
    );

    register u_sumrg (
        .clk    (clk),
        .rst    (rst),
        .load   (sumload),
        .in_data(sumreg_src_data),
        .o_data (sumreg_out)
    );

    mux_2X1 u_sumreg_src_mux (
        .a      (0),               //sel 0
        .b      (alu_out),         //sel 1
        .sel    (sumsrcsel),
        .mux_out(sumreg_src_data)
    );

    mux_2X1 u_alu_src_mux (
        .a      (sumreg_out),   //sel 0
        .b      (1),            //sel 1
        .sel    (alusrcsel),
        .mux_out(alu_src_data)
    );


    alu u_alu (
        .a      (ireg_out),      // from ireg
        .b      (alu_src_data),  //from sumreg
        .alu_out(alu_out)
    );

    let10 u_let10 (
        .in_data(ireg_out),
        .ile10  (ile10)
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

module let10 (
    input  [7:0] in_data,
    output       ile10
);
    assign ile10 = (in_data <= 10);

endmodule
