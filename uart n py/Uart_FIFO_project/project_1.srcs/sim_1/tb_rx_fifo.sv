//검증할 케이스
//1. Back to Back
//2 start bit 글리치

`timescale 1ns / 1ps
`define ADDR 16
`define BIT_WIDTH 8


interface rx_fifo_interface (
    input clk
);
    //rx
    logic                  rst;
    logic                  uart_rx;
    //fifo
    bit                    re;
    logic [`BIT_WIDTH-1:0] fifo_rdata;
    logic                  full;
    logic                  empty;

endinterface  //rx_fifo_interface

class transaction;
    randc bit [           7:0] ascii_data;
    //rx
    bit                        uart_rx;
    //fifo
    bit                        re;
    logic     [`BIT_WIDTH-1:0] fifo_rdata;
    bit                        full;
    bit                        empty;

    // constraint missing_cases {
    //     ascii_data inside {8'h0E, 8'h16, 8'h37, 8'h3B, 8'h55, 8'h7B, 8'hB9,
    //                        8'hD1};
    // }

    function void display(string name);
        $display(
            "%t: [%s] ascii_data = %h -> uart_rx = %h -> re = %h, fifo_rdata = %h full = %h, empty = %h",
            $realtime, name, ascii_data, uart_rx, re, fifo_rdata, full, empty);
    endfunction
endclass  //transaction

class generator;
    transaction tr;

    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    //통계
    int ascii_history[bit [7:0]];


    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()



    task run(int run_cnt);
        repeat (run_cnt) begin
            tr = new();
            tr.randomize();

            ascii_history[tr.ascii_data]++;

            gen2drv_mbox.put(tr);
            tr.display("gen");
            @(gen_next_ev);
        end
    endtask  //run


endclass  //generator

class driver;
    transaction tr;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) drv2mon_mbox;

    virtual rx_fifo_interface rx_fifo_if;

    event pop_fifo_ev;

    int s_time = 0;


    parameter BAUD = 9600;
    parameter BAUD_REPIOD = (100_000_000 / BAUD) * 10;  //104_160
    int i = 0;
    real add_rate = 0.94;
    real BAUD_DELAY = BAUD_REPIOD * add_rate;

    function new(mailbox#(transaction) gen2drv_mbox,
                 mailbox#(transaction) drv2mon_mbox, event pop_fifo_ev,
                 virtual rx_fifo_interface rx_fifo_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.drv2mon_mbox = drv2mon_mbox;
        this.pop_fifo_ev  = pop_fifo_ev;
        this.rx_fifo_if   = rx_fifo_if;
    endfunction  //new()

    task preset();
        rx_fifo_if.rst     = 1;
        rx_fifo_if.uart_rx = 1;
        rx_fifo_if.re      = 0;
        @(negedge rx_fifo_if.clk);
        @(negedge rx_fifo_if.clk);
        rx_fifo_if.rst = 0;
        @(posedge rx_fifo_if.clk);
        //add assertion
    endtask

    task uart_push(input [7:0] ascii_data);
        begin
            rx_fifo_if.uart_rx = 0;
            s_time = $time;
            $display("%t start", ($time - s_time));
            #(BAUD_DELAY);

            for (i = 0; i < 8; i = i + 1) begin
                rx_fifo_if.uart_rx = ascii_data[i];
                $display("%t data <= %h", ($time - s_time), ascii_data[i]);
                s_time = $time;
                #(BAUD_DELAY);
            end

            //stop
            rx_fifo_if.uart_rx = 1'b1;
            $display("%t stop", ($time - s_time));
            s_time = $time;
            #(BAUD_DELAY);
            $display("%t end", ($time - s_time));
        end
    endtask



    task run();
        forever begin
            gen2drv_mbox.get(tr);

            //gen rx
            @(posedge rx_fifo_if.clk);
            uart_push(tr.ascii_data);
            tr.display("drv_rx");

            //pop
            @(posedge rx_fifo_if.clk);
            rx_fifo_if.re = 1;
            @(posedge rx_fifo_if.clk);
            rx_fifo_if.re = 0;

            drv2mon_mbox.put(tr);
            tr.display("drv_pop");
            ->pop_fifo_ev;
        end
    endtask  //run
endclass  //driver

class monitor;
    transaction tr;
    transaction drv_tr;

    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) drv2mon_mbox;

    event pop_fifo_ev;

    virtual rx_fifo_interface rx_fifo_if;

    function new(mailbox#(transaction) mon2scb_mbox,
                 mailbox#(transaction) drv2mon_mbox, event pop_fifo_ev,
                 virtual rx_fifo_interface rx_fifo_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.drv2mon_mbox = drv2mon_mbox;
        this.pop_fifo_ev  = pop_fifo_ev;
        this.rx_fifo_if   = rx_fifo_if;
    endfunction  //new()

    task run();
        forever begin
            @(pop_fifo_ev);
            drv2mon_mbox.get(drv_tr);

            tr            = new();
            tr.ascii_data = drv_tr.ascii_data;
            tr.uart_rx    = rx_fifo_if.uart_rx;
            tr.fifo_rdata = rx_fifo_if.fifo_rdata;
            tr.full       = rx_fifo_if.full;
            tr.empty      = rx_fifo_if.empty;

            mon2scb_mbox.put(tr);
            tr.display("mon");
        end
    endtask  //run
endclass  //monitor

class scoreboard;
    transaction tr;

    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    int pass_cnt = 0, fail_cnt = 0, try_cnt = 0;


    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    task run();

        forever begin
            mon2scb_mbox.get(tr);
            tr.display("scb");

            try_cnt++;
            if (tr.ascii_data == tr.fifo_rdata) begin
                $display("[Pass]");
                pass_cnt++;
            end else begin
                $display(
                    " [Fail] ascii_data = %h -> uart_rx = %h,fifo_rdata = %h full = %h, empty = %h",
                    tr.ascii_data, tr.uart_rx, tr.fifo_rdata, tr.full,
                    tr.empty);
                fail_cnt++;
            end

            ->gen_next_ev;
        end

    endtask  //run
endclass  //scoreboard

class environment;
    transaction            tr;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;


    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) drv2mon_mbox;

    event                  gen_next_ev;
    event                  pop_fifo_ev;


    function new(virtual rx_fifo_interface rx_fifo_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        drv2mon_mbox = new();
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, drv2mon_mbox, pop_fifo_ev, rx_fifo_if);
        mon = new(mon2scb_mbox, drv2mon_mbox, pop_fifo_ev, rx_fifo_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()

    task run();
        drv.preset();
        fork
            gen.run(50);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;

        $display("\n============================================");
        $display("            VERIFICATION REPORT             ");
        $display("============================================");
        $display("  STATUS    |  DESCRIPTION       |  COUNT    ");
        $display("------------+--------------------+----------");
        $display("  TOTAL     |  Total Trials      |   %3d    ", scb.try_cnt);
        $display("  PASS      |  Success Matches   |   %3d    ", scb.pass_cnt);
        $display("  FAIL      |  Mismatch Errors   |   %3d    ", scb.fail_cnt);
        $display(
            "  RATIO     |  Success Rate      |  %6.2f%% ",
            (scb.try_cnt > 0) ? (real'(scb.pass_cnt) * 100.0 / scb.try_cnt) : 0.0);
        $display("------------+--------------------+----------");
        $display("  TIME      |  End Time          |  %t", $realtime);
        $display("============================================");
        $display("add_rate : %f",drv.add_rate);
        $display("============================================");
        $display("--- Generated ASCII Summary ---");
        $display(gen.ascii_history);
        $stop;
    endtask  //run

endclass  //environment

module tb_rx_fifo ();

    logic clk;
    logic w_b_tick;
    logic [7:0] rx_data;
    logic rx_done;

    rx_fifo_interface rx_fifo_if (clk);

    environment env;


    baud_tick U_BAUD_TICK (
        .clk   (clk),
        .rst   (rx_fifo_if.rst),
        .b_tick(w_b_tick)
    );

    uart_rx U_UART_RX (
        .clk    (clk),
        .rst    (rx_fifo_if.rst),
        .rx     (rx_fifo_if.uart_rx),
        .b_tick (w_b_tick),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    fifo #(
        .ADDR(`ADDR),
        .BIT_WIDTH(`BIT_WIDTH)
    ) U_FIFO (
        .w_clk(clk),
        .r_clk(clk),
        .rst  (rx_fifo_if.rst),
        .we   (rx_done),
        .wdata(rx_data),
        .re   (rx_fifo_if.re),
        .rdata(rx_fifo_if.fifo_rdata),
        .full (rx_fifo_if.full),
        .empty(rx_fifo_if.empty)
    );

    always #5 clk = ~clk;

    initial begin
        $timeformat(-9, 0, "ns");
        clk = 0;
        env = new(rx_fifo_if);
        env.run();
    end
endmodule
