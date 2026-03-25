`timescale 1ns / 1ps
//`include "define.vh"


module Amba_apb ();
endmodule


module apb_master (
    input               Pclk,      // input from system/APB clock generator -> used inside APB master
    input Prst,  // input from system reset -> used inside APB master

    input        [31:0] addr,      // input from CPU/datapath/control side -> APB master uses it to generate Paddr
    input        [31:0] wdata,     // input from CPU/datapath write-data path -> APB master forwards it to Pwdata
    input               Wreg,      // input from CPU/control unit write request -> APB master starts APB write transfer
    input               Rreg,      // input from CPU/control unit read request -> APB master starts APB read transfer

    input        [31:0] Pdata,     // input from APB slave PRDATA -> APB master captures it and returns it as Rrdata
    input               Rready,    // input from APB slave PREADY -> APB master checks transfer completion
    input               Rslverr,   // input from APB slave PSLVERR -> APB master reports error as suerr

    output logic        Penable,   // output from APB master -> APB slave/access bus, enables access phase
    output logic        Pwrite,    // output from APB master -> APB slave, indicates write(1)/read(0)
    output logic        suerr,     // output from APB master -> CPU/control/status logic, indicates slave error
    output logic        ready,     // output from APB master -> CPU/control logic, indicates transaction finished
    output logic [31:0] Pwdata,    // output from APB master -> APB slave PWDATA bus
    output logic [31:0] Paddr,      // output from APB master -> APB slave/decoder PADDR bus
    output logic [31:0] Pselx_0,     // output from APB master/decoder -> selected APB slave, chip select signal
    output logic [31:0] Pselx_1,     // output from APB master/decoder -> selected APB slave, chip select signal
    output logic [31:0] Pselx_2,     // output from APB master/decoder -> selected APB slave, chip select signal
    output logic [31:0] Pselx_3,     // output from APB master/decoder -> selected APB slave, chip select signal
    output logic [31:0] Pselx_4,     // output from APB master/decoder -> selected APB slave, chip select signal
    output logic [31:0] Rrdata_0,    // output from APB master -> CPU/datapath read-data path
    output logic [31:0] Rrdata_1,    // output from APB master -> CPU/datapath read-data path
    output logic [31:0] Rrdata_2,    // output from APB master -> CPU/datapath read-data path
    output logic [31:0] Rrdata_3,    // output from APB master -> CPU/datapath read-data path
    output logic [31:0] Rrdata_4    // output from APB master -> CPU/datapath read-data path
);

    typedef enum {
        IDLE,
        SETUP,
        ACCESS
    } state_a;

    state_a c_state, n_state;

    always_ff @(posedge Pclk, posedge Prst) begin
        if (Prst) begin
            c_state <= IDLE;
        end else begin
            c_state <= n_state;
        end
    end

    always_comb begin
        n_state = c_state;
        case (c_state)
            IDLE: begin
                n_state = SETUP;
            end
            SETUP: begin

            end
            ACCESS: begin

            end
        endcase
    end



endmodule


module address_dec (
    input        [31:0] addr,
    output logic        PSel_0,
    output logic        PSel_1,
    output logic        PSel_2,
    output logic        PSel_3,
    output logic        PSel_4,
    output logic        PSel_5,
    output logic        PSel_6,
    output logic [ 3:0] sel
);
    logic [31:0] dec_data;

    always_comb begin
        PSel_0 = 0;
        PSel_1 = 0;
        PSel_2 = 0;
        PSel_3 = 0;
        PSel_4 = 0;
        PSel_5 = 0;
        PSel_6 = 0;
        case (addr[32:0])
            32'h1000_0000: begin PSel_0 = 1; sel = 4'd0; end  // RAM
            32'h2000_0000: begin PSel_1 = 1; sel = 4'd1; end  // GPO
            32'h2000_1000: begin PSel_2 = 1; sel = 4'd2; end  // GPI
            32'h2000_2000: begin PSel_3 = 1; sel = 4'd3; end  // GPIO
            32'h2000_3000: begin PSel_4 = 1; sel = 4'd4; end  // FND
            32'h2000_4000: begin PSel_5 = 1; sel = 4'd5; end  // UART
        endcase

    end

endmodule


module mux5x1 (
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,
    input  [31:0] d,
    input  [31:0] e,
    input         sel,
    output [31:0] odata_mux
);
    logic [31:0] mux_data;
    always_comb begin
        case (sel)
            4'd0: mux_data = a; 
            4'd1: mux_data = b; 
            4'd2: mux_data = c; 
            4'd3: mux_data = d; 
            4'd4: mux_data = e;  
        endcase
    end
    
    assign odata_mux = mux_data;

endmodule


module register (
    input         clk,
    input         rst,
    input  [31:0] idata,
    output [31:0] odata
);
    logic [31:0] ldata;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            ldata <= 0;
        end else begin
            ldata <= idata;
        end
    end

    assign odata = ldata;
endmodule
