//추가할 케이스
//1. rst test 동작 중 rst 입력


`timescale 1ns / 1ps
`define ADDR 16
`define BIT_WIDTH 8

interface tx_fifo_interface (
    input clk
);
    logic       rst;
    //fifo
    logic       fifo_we;
    logic [7:0] fifo_wdata;
    //tx
    logic       tx_busy;
    logic       tx_done;
    logic       uart_tx;

endinterface  //tx_fifo_interface

class transaction;
    bit                        rst;
    //fifo
    bit                        fifo_we;
    randc bit [           7:0] fifo_wdata;
    //tx
    bit                        tx_busy;
    bit                        tx_done;
    bit                        uart_tx;

    bit       [           7:0] pc_data;
    logic     [`BIT_WIDTH-1:0] scb_q      [$:`ADDR-1];

    //제약
    // constraint c_last_three {fifo_wdata inside {18, 146, 223};}

    function void display(string name);
        $display(
            "%t: [%s] fifo_we = %h, fifo_wdata = %h -> uart_tx = %h, tx_done = %h tx_busy = %h, pc_data = %h",
            $realtime, name, fifo_we, fifo_wdata, uart_tx, tx_done, tx_busy,
            pc_data);
    endfunction
endclass  //transaction

class generator;
    transaction tr;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;
    event gen_next_ev;

    //통계
    int ascii_history[bit [7:0]];

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

            ascii_history[tr.fifo_wdata]++;

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

    virtual tx_fifo_interface tx_fifo_if;

    event gen_next_ev;


    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev,
                 virtual tx_fifo_interface tx_fifo_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
        this.tx_fifo_if   = tx_fifo_if;
    endfunction  //new()

    task preset();
        tx_fifo_if.rst = 1;
        tx_fifo_if.fifo_we = 0;
        @(negedge tx_fifo_if.clk);
        @(negedge tx_fifo_if.clk);
        tx_fifo_if.rst = 0;
        @(posedge tx_fifo_if.clk);
        //add assertion
    endtask

    task push_data();
        gen2drv_mbox.get(tr);
        tx_fifo_if.fifo_wdata = tr.fifo_wdata;
        tr.scb_q.push_front(tr.fifo_wdata);
        
        @(negedge tx_fifo_if.clk);
        tx_fifo_if.fifo_we = 1;
        #10;
        tx_fifo_if.fifo_we = 0;
    endtask

    task run();
        forever begin
            //driver

            push_data();


            tr.display("drv");
        end
    endtask  //run
endclass  //driver

class monitor;
    transaction tr;

    mailbox #(transaction) mon2scb_mbox;

    virtual tx_fifo_interface tx_fifo_if;

    int s_time = 0;

    parameter BAUD = 9600;
    parameter BAUD_REPIOD = (100_000_000 / BAUD) * 10;  //104_160

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual tx_fifo_interface tx_fifo_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.tx_fifo_if   = tx_fifo_if;
    endfunction  //new()

    task run();
        forever begin
            @(negedge tx_fifo_if.uart_tx);
            tr = new();

            //check_tx
            #(BAUD_REPIOD / 2);

            for (int i = 0; i < 8; i++) begin
                #(BAUD_REPIOD);
                tr.pc_data[i] = tx_fifo_if.uart_tx;
            end
            @(posedge tx_fifo_if.tx_done);
            tr.fifo_we = tx_fifo_if.fifo_we;
            tr.fifo_wdata = tx_fifo_if.fifo_wdata;

            tr.uart_tx = tx_fifo_if.uart_tx;
            tr.tx_busy = tx_fifo_if.tx_busy;
            tr.tx_done = tx_fifo_if.tx_done;

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
    logic [7:0] q_data;




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
            q_data = gen_tr.scb_q.pop_back();
            if (tr.pc_data == q_data) begin
                $display("[Pass]");
                pass_cnt++;
            end else begin
                $display(
                    "[Fail] pc_data = %h ->q_data = %h, tx_done = %h, tx_busy = %h",
                    tr.pc_data, q_data, tr.tx_done, tr.tx_busy);
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


    function new(virtual tx_fifo_interface tx_fifo_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen2scb_mbox = new();
        gen = new(gen2drv_mbox, gen2scb_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, gen_next_ev, tx_fifo_if);
        mon = new(mon2scb_mbox, tx_fifo_if);
        scb = new(mon2scb_mbox, gen2scb_mbox, gen_next_ev);
    endfunction  //new()

    int cnt = 18;
    task run();
        drv.preset();
        fork
            gen.run(cnt);
            drv.run();
            mon.run();
            scb.run();
        join_none

        wait(scb.try_cnt == cnt);
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
        $display("============================================");
        $display("--- Generated ASCII Summary ---");
        $display(gen.ascii_history);
        $stop;
    endtask  //run

endclass  //environment


module tb_tx_fifo ();
    logic clk;
    logic w_b_tick;
    logic [7:0] fifo_rdata;
    logic fifo_empty;

    tx_fifo_interface tx_fifo_if (clk);

    environment env;

    baud_tick U_BAUD_TICK (
        .clk   (clk),
        .rst   (tx_fifo_if.rst),
        .b_tick(w_b_tick)
    );

    fifo #(
        .ADDR(`ADDR),
        .BIT_WIDTH(`BIT_WIDTH)
    ) U_FIFO (
        .w_clk(clk),
        .r_clk(clk),
        .rst  (tx_fifo_if.rst),
        .we   (tx_fifo_if.fifo_we),
        .wdata(tx_fifo_if.fifo_wdata),
        .re   (~tx_fifo_if.tx_busy),
        .rdata(fifo_rdata),
        .full (),
        .empty(fifo_empty)
    );

    uart_tx U_UART_TX (
        .clk     (clk),
        .rst     (tx_fifo_if.rst),
        .tx_start(~fifo_empty && ~tx_fifo_if.tx_busy),
        .b_tick  (w_b_tick),
        .tx_data (fifo_rdata),
        .tx_busy (tx_fifo_if.tx_busy),
        .tx_done (tx_fifo_if.tx_done),
        .uart_tx (tx_fifo_if.uart_tx)
    );


    always #5 clk = ~clk;

    initial begin
        $timeformat(-9, 0, "ns");
        clk = 0;
        env = new(tx_fifo_if);
        env.run();
    end
endmodule

