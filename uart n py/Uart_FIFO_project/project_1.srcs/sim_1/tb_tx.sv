//추가할 케이스
//1. rst test 동작 중 rst 입력


`timescale 1ns / 1ps
interface tx_interface (
    input clk
);
    logic       rst;
    logic       tx_start;
    logic [7:0] tx_data;
    logic       tx_busy;
    logic       tx_done;
    logic       uart_tx;

endinterface  //tx_interface

class transaction;
    rand bit [7:0] tx_data;
    bit            tx_busy;
    bit            tx_done;
    bit            uart_tx;

    bit      [7:0] pc_data;

    function void display(string name);
        $display(
            "%t: [%s] tx_data = %h -> uart_tx = %h,tx_done = %h tx_busy = %h, pc_data = %h",
            $realtime, name, tx_data, uart_tx, tx_done, tx_busy, pc_data);
    endfunction
endclass  //transaction

class generator;
    transaction tr;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox,
                 mailbox#(transaction) gen2scb_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    task run(int run_cnt);
        repeat (run_cnt) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            gen2scb_mbox.put(tr);
            tr.display("gen");
            @(gen_next_ev);
        end
    endtask  //run
endclass  //generator

class driver;
    transaction tr;

    mailbox #(transaction) gen2drv_mbox;

    virtual tx_interface tx_if;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual tx_interface tx_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.tx_if = tx_if;
    endfunction  //new()

    task preset();
        tx_if.rst = 1;
        @(negedge tx_if.clk);
        @(negedge tx_if.clk);
        tx_if.rst = 0;
        @(posedge tx_if.clk);
        //add assertion
    endtask

    task start();
        tx_if.tx_start = 1;
        #10;
        tx_if.tx_start = 0;
    endtask

    task run();
        forever begin
            //driver
            gen2drv_mbox.get(tr);
            tx_if.tx_data = tr.tx_data;


            @(negedge tx_if.clk);
            start();


            tr.display("drv");
        end
    endtask  //run
endclass  //driver

class monitor;
    transaction tr;

    mailbox #(transaction) mon2scb_mbox;

    virtual tx_interface tx_if;

    parameter BAUD = 9600;
    parameter BAUD_REPIOD = (100_000_000 / BAUD) * 10;  //104_160

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual tx_interface tx_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.tx_if = tx_if;
    endfunction  //new()

    task run();
        forever begin
            @(negedge tx_if.uart_tx);
            tr = new();

            #(BAUD_REPIOD / 2);

            for (int i = 0; i < 8; i++) begin
                #(BAUD_REPIOD);
                tr.pc_data[i] = tx_if.uart_tx;
            end
            @(posedge tx_if.tx_done);

            tr.tx_data = tx_if.tx_data;
            tr.uart_tx = tx_if.uart_tx;
            tr.tx_busy = tx_if.tx_busy;
            tr.tx_done = tx_if.tx_done;

            mon2scb_mbox.put(tr);
            tr.display("mon");

        end
    endtask  //run
endclass  //monitor

class scoreboard;
    transaction tr;
    transaction gen_tr;

    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) gen2scb_mbox;

    event gen_next_ev;

    int pass_cnt = 0, fail_cnt = 0, try_cnt = 0;
    int busy_error_cnt = 0;
    int check_bit_cnt = 0;




    function new(mailbox#(transaction) mon2scb_mbox,
                 mailbox#(transaction) gen2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()


    task run();
        forever begin
            gen2scb_mbox.get(gen_tr);
            mon2scb_mbox.get(tr);


            //Verification
            try_cnt++;
            if (tr.pc_data == gen_tr.tx_data) begin
                $display("[Pass]");
                pass_cnt++;
            end else begin
                $display(
                    "[Fail] tx_data = %h ->pc_data = %h, tx_done = %h, tx_busy = %h",
                    gen_tr.tx_data, tr.pc_data, tr.tx_done, tr.tx_busy);
                fail_cnt++;
            end

            tr.display("scb");
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
    mailbox #(transaction) gen2scb_mbox;

    event                  gen_next_ev;


    function new(virtual tx_interface tx_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen2scb_mbox = new();
        gen = new(gen2drv_mbox, gen2scb_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, tx_if);
        mon = new(mon2scb_mbox, tx_if);
        scb = new(mon2scb_mbox, gen2scb_mbox, gen_next_ev);
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


module tb_tx ();
    logic clk;
    logic w_b_tick;

    tx_interface tx_if (clk);

    environment env;


    baud_tick U_BAUD_TICK (
        .clk   (clk),
        .rst   (tx_if.rst),
        .b_tick(w_b_tick)
    );

    uart_tx DUT (
        .clk     (clk),
        .rst     (tx_if.rst),
        .tx_start(tx_if.tx_start),
        .b_tick  (w_b_tick),
        .tx_data (tx_if.tx_data),
        .tx_busy (tx_if.tx_busy),
        .tx_done (tx_if.tx_done),
        .uart_tx (tx_if.uart_tx)
    );

    always #5 clk = ~clk;

    initial begin
        $timeformat(-9, 0, "ns");
        clk = 0;
        env = new(tx_if);
        env.run();
    end
endmodule
