`timescale 1ns / 1ps


module universal_cpu (
    input        clk,
    input        rst,
    output [7:0] value
);
    logic rfsrcsel, we, let10;
    logic [1:0] ra0, ra1, wa;

    datapath u_datapath (
        .clk(clk),
        .rst(rst),
        .rf_srcsel(rfsrcsel),
        .ra0(ra0),
        .ra1(ra1),
        .wa(wa),
        .we(we),
        .compare(let10),
        .value(value)

    );

    control_unit u_control (
        .clk(clk),
        .rst(rst),
        .ile10(let10),
        .we(we),
        .rfsrcsel(rfsrcsel),
        .ra0(ra0),
        .ra1(ra1),
        .wa(wa)

    );


endmodule


module control_unit (
    input              clk,
    input              rst,
    input              ile10,
    output logic       we,
    output logic       rfsrcsel,
    output logic [1:0] ra0,
    output logic [1:0] ra1,
    output logic [1:0] wa

);


    typedef enum logic [2:0] {
        s0,
        s1,
        s2,
        s3,
        s4,
        s5,
        s6
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
        we = 0;
        ra0 = 0;
        ra1 = 0;
        wa = 0;
        rfsrcsel = 0;
        n_st = c_st;
        case (c_st)
            s0: begin
                rfsrcsel = 0;
                ra0      = 2'd0;
                ra1      = 2'd0;
                wa       = 2'd3;
                we       = 1;
                n_st     = s1;
            end
            s1: begin
                rfsrcsel = 1;
                ra0      = 2'd0;
                ra1      = 2'd3;
                wa       = 2'd1;
                we       = 1;
                n_st     = s2;
            end
            s2: begin
                rfsrcsel = 1;
                ra0      = 2'd0;
                ra1      = 2'd0;
                wa       = 2'd2;
                we       = 1;
                n_st     = s3;
            end
            s3: begin
                rfsrcsel = 0;
                ra0      = 2'd1;
                ra1      = 2'd0;
                wa       = 2'd0;
                we       = 0;
                if (ile10) begin
                    n_st = s4;
                end else begin
                    n_st = s6;
                end
            end

            s4: begin
                rfsrcsel = 1;
                ra0      = 2'd1;
                ra1      = 2'd2;
                wa       = 2'd2;
                we       = 1;
                n_st     = s5;
            end
            s5: begin
                rfsrcsel = 1;
                ra0      = 2'd1;
                ra1      = 2'd3;
                wa       = 2'd1;
                we       = 1;
                n_st     = s3;
            end
            s6: begin
                rfsrcsel = 0;
                ra0      = 2'd0;
                ra1      = 2'd0;
                wa       = 2'd0;
                we       = 0;
                n_st     = s6;
            end
        endcase
    end


endmodule

module datapath (
    input              clk,
    input              rst,
    input              rf_srcsel,
    input        [1:0] ra0,
    input        [1:0] ra1,
    input        [1:0] wa,
    input              we,
    output logic       compare,
    output logic [7:0] value

);

    logic [7:0] oalu, rd0, rd1, wd;


    register_file u_reg (
        .clk(clk),
        .rst(rst),
        .ra0(ra0),
        .ra1(ra1),
        .wa (wa),
        .wd (wd),
        .we (we),
        .rd0(rd0),
        .rd1(rd1),
        .sum_value(value)

    );

    compare u_compare (
        .in_data (rd0),
        .ocompare(compare)
    );

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
    input              clk,
    input              rst,
    input        [1:0] ra0,
    input        [1:0] ra1,
    input        [1:0] wa,
    input        [7:0] wd,
    input              we,
    output logic [7:0] rd0,
    output logic [7:0] rd1,
    output logic [7:0] sum_value

);

    logic we1, we2, we3;
    logic [7:0] r1_q, r2_q, r3_q;

    always_comb begin
        we1 = 1'b0;
        we2 = 1'b0;
        we3 = 1'b0;
        if (we) begin
            case (wa)
                2'd1: we1 = 1'b1;
                2'd2: we2 = 1'b1;
                2'd3: we3 = 1'b1;
                default: ;
            endcase
        end
    end

    always_comb begin
        case (ra0)
            2'd0: rd0 = 8'd0;
            2'd1: rd0 = r1_q;
            2'd2: rd0 = r2_q;
            default: rd0 = r3_q;
        endcase
    end

    // read port 1
    always_comb begin
        case (ra1)
            2'd0: rd1 = 8'd0;
            2'd1: rd1 = r1_q;
            2'd2: rd1 = r2_q;
            default: rd1 = r3_q;
        endcase
    end
    register u_reg_1 (
        .clk    (clk),
        .rst    (rst),
        .load   (we1),
        .in_data(wd),
        .o_data (r1_q)
    );

    register u_reg_2 (
        .clk    (clk),
        .rst    (rst),
        .load   (we2),
        .in_data(wd),
        .o_data (r2_q)
    );

    register u_reg_3 (
        .clk    (clk),
        .rst    (rst),
        .load   (we3),
        .in_data(1),
        .o_data (r3_q)
    );

    assign sum_value = r2_q;
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
