//검증할 케이스
//1. Back to Back
//2 start bit 글리치

`timescale 1ns / 1ps
interface rx_interface (
    input clk
);
    logic       rst;
    logic       uart_rx;
    logic [7:0] rx_data;
    logic       rx_done;

endinterface  //rx_interface

class transaction;
    rand bit [7:0] ascii_data;

    bit            uart_rx;
    logic    [7:0] rx_data;
    bit            rx_done;

    function void display(string name);
        $display(
            "%t: [%s] ascii_data = %h -> uart_rx = %h,rx_data = %h rx_done = %h",
            $realtime, name, ascii_data, uart_rx, rx_data, rx_done);
    endfunction
endclass  //transaction

class generator;
    transaction tr;

    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    task run(int run_cnt);
        repeat (run_cnt) begin
            tr = new();
            tr.randomize();
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

    virtual rx_interface rx_if;


    parameter BAUD = 9600;
    parameter BAUD_REPIOD = (100_000_000 / BAUD) * 10;  //104_160
    int i = 0;

    function new(mailbox#(transaction) gen2drv_mbox,
                 mailbox#(transaction) drv2mon_mbox,
                 virtual rx_interface rx_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.drv2mon_mbox = drv2mon_mbox;
        this.rx_if = rx_if;
    endfunction  //new()

    task preset();
        rx_if.rst = 1;
        rx_if.uart_rx = 1;
        @(negedge rx_if.clk);
        @(negedge rx_if.clk);
        rx_if.rst = 0;
        @(posedge rx_if.clk);
        //add assertion
    endtask

    task uart_push(input [7:0] ascii_data);
        begin
            rx_if.uart_rx = 0;
            #(BAUD_REPIOD);
            for (i = 0; i < 8; i = i + 1) begin
                rx_if.uart_rx = ascii_data[i];
                #(BAUD_REPIOD);
            end
            //stop
            rx_if.uart_rx = 1'b1;
            #(BAUD_REPIOD);
        end
    endtask



    task run();
        forever begin
            gen2drv_mbox.get(tr);

            @(posedge rx_if.clk);
            drv2mon_mbox.put(tr);
            uart_push(tr.ascii_data);

            tr.display("drv");
        end
    endtask  //run
endclass  //driver

class monitor;
    transaction tr;
    transaction drv_tr;

    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) drv2mon_mbox;

    virtual rx_interface rx_if;

    function new(mailbox#(transaction) mon2scb_mbox,
                 mailbox#(transaction) drv2mon_mbox,
                 virtual rx_interface rx_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.drv2mon_mbox = drv2mon_mbox;
        this.rx_if = rx_if;
    endfunction  //new()

    task run();
        forever begin
            @(posedge rx_if.rx_done);
            #1;
            drv2mon_mbox.get(drv_tr);

            tr            = new();
            tr.ascii_data = drv_tr.ascii_data;
            tr.uart_rx    = rx_if.uart_rx;
            tr.rx_data    = rx_if.rx_data;
            tr.rx_done    = rx_if.rx_done;

            mon2scb_mbox.put(tr);
            tr.display("mon");

            wait (rx_if.rx_done === 0);
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
            if (tr.ascii_data == tr.rx_data) begin
                $display("[Pass]");
                pass_cnt++;
            end else begin
                $display(
                    " [Fail] ascii_data = %h -> uart_rx = %h,rx_data = %h rx_done = %h",
                    tr.ascii_data, tr.uart_rx, tr.rx_data, tr.rx_done);
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


    function new(virtual rx_interface rx_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        drv2mon_mbox = new();
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, drv2mon_mbox, rx_if);
        mon = new(mon2scb_mbox, drv2mon_mbox, rx_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()

    task run();
        drv.preset();
        fork
            gen.run(100);
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
        $stop;
    endtask  //run

endclass  //environment

module tb_rx ();

    logic clk;
    logic w_b_tick;

    rx_interface rx_if (clk);

    environment env;


    baud_tick U_BAUD_TICK (
        .clk   (clk),
        .rst   (rx_if.rst),
        .b_tick(w_b_tick)
    );

    uart_rx U_UART_RX (
        .clk    (clk),
        .rst    (rx_if.rst),
        .rx     (rx_if.uart_rx),
        .b_tick (w_b_tick),
        .rx_data(rx_if.rx_data),
        .rx_done(rx_if.rx_done)
    );


    always #5 clk = ~clk;

    initial begin
        $timeformat(-9, 0, "ns");
        clk = 0;
        env = new(rx_if);
        env.run();
    end
endmodule
