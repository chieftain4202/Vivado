`timescale 1ns / 1ps `timescale 1ns / 1ps
`define ADDR 16
`define BIT_WIDTH 8

interface fifo_interface (
    input w_clk,
    input r_clk
);
    logic                  rst;
    logic                  we;
    logic                  re;
    logic [`BIT_WIDTH-1:0] wdata;
    logic [`BIT_WIDTH-1:0] rdata;
    logic                  full;
    logic                  empty;
endinterface  //fifo_interface

class transaction;
    rand bit                  we;
    rand bit                  re;
    rand bit [`BIT_WIDTH-1:0] wdata;
    logic    [`BIT_WIDTH-1:0] rdata;
    bit                       full;
    bit                       empty;

    function void display(string name);
        $display(
            "%t: [%s] we = %h, wdata = %h \t re = %h, rdata = %2h \t full = %h, empty = %h",
            $realtime, name, we, wdata, re, rdata, full, empty);
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

    virtual fifo_interface fifo_if;

    int cnt;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual fifo_interface fifo_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.fifo_if = fifo_if;
    endfunction  //new()

    task preset();
        fifo_if.rst = 1;
        fifo_if.we = 0;
        fifo_if.wdata = 0;
        fifo_if.re = 0;
        @(negedge fifo_if.w_clk);
        @(negedge fifo_if.w_clk);
        fifo_if.rst = 0;
        @(posedge fifo_if.w_clk);
        //add assertion
    endtask

    task push();
        fifo_if.we    = 1;
        fifo_if.wdata = tr.wdata;
        fifo_if.re    = 0;
    endtask

    task pop();
        fifo_if.we    = 0;
        fifo_if.wdata = tr.wdata;
        fifo_if.re    = 1;
    endtask

    task push_pop();
        fifo_if.we    = 1;
        fifo_if.wdata = tr.wdata;
        fifo_if.re    = 1;
    endtask

    task stop();
        fifo_if.we    = 0;
        fifo_if.wdata = tr.wdata;
        fifo_if.re    = 0;
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);

            @(posedge fifo_if.w_clk);
            #1;

            // if (tr.we) push();
            // else fifo_if.we = 0;
            // if (tr.re) pop();
            // else fifo_if.re = 0;
            if (cnt < 14) push();
            else if (cnt == 16)push_pop();
            else stop();
            cnt++;

            tr.display("drv");
        end
    endtask  //run
endclass  //driver

class monitor;
    transaction tr;

    mailbox #(transaction) mon2scb_mbox;

    virtual fifo_interface fifo_if;
    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual fifo_interface fifo_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.fifo_if = fifo_if;
    endfunction  //new()

    task run();
        forever begin
            @(negedge fifo_if.w_clk);

            tr       = new();
            tr.we    = fifo_if.we;
            tr.re    = fifo_if.re;
            tr.wdata = fifo_if.wdata;
            tr.rdata = fifo_if.rdata;
            tr.full  = fifo_if.full;
            tr.empty = fifo_if.empty;

            mon2scb_mbox.put(tr);
            tr.display("mon");
        end
    endtask  //run
endclass  //monitor

class scoreboard;
    transaction tr;

    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    logic [`BIT_WIDTH-1:0] scb_q[$:`ADDR-1];
    logic [`BIT_WIDTH-1:0] q_data;
    int pass_cnt = 0, fail_cnt = 0, try_cnt = 0;
    int full_cnt, empty_cnt;
    int i = 0;


    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    task run();
        logic [`BIT_WIDTH-1:0] scb_mem[0:`ADDR-1];
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("scb");

            if (tr.we && !tr.full) begin
                //save
                scb_q.push_front(tr.wdata);
                $display("scb_push <= %h", tr.wdata);
                $write("q (Hex): [");
                foreach (scb_q[i]) begin
                    $write("%h ", scb_q[i]);  // %h는 16진수 출력
                end
                $display("]");  // 줄바꿈
            end

            if (tr.re && !tr.empty) begin
                //pass,fail
                try_cnt++;
                q_data = scb_q.pop_back();
                $display("scb_pop <= %h", q_data);
                $write("q (Hex): [");
                foreach (scb_q[i]) begin
                    $write("%h ", scb_q[i]);  // %h는 16진수 출력
                end
                $display("]");  // 줄바꿈
                if (q_data == tr.rdata) begin
                    $display("[Pass]");
                    pass_cnt++;
                end else begin
                    $display(
                        "[Fail] we = %h, wdata = %h \t re = %h, rdata = %2h \t full = %h, empty = %h \t q_data = %h",
                        tr.we, tr.wdata, tr.re, tr.rdata, tr.full, tr.empty,
                        q_data);
                    fail_cnt++;
                end
            end

            if (tr.full) full_cnt++;
            if (tr.empty) empty_cnt++;

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

    event                  gen_next_ev;


    function new(virtual fifo_interface fifo_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, fifo_if);
        mon = new(mon2scb_mbox, fifo_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()

    task run();
        drv.preset();
        fork
            gen.run(1000);
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
        $display("  FULL      |  Full Occurred     |   %3d    ", scb.full_cnt);
        $display("  EMPTY     |  Empty Occurred    |   %3d    ", scb.empty_cnt);
        $display("------------+--------------------+----------");
        $display("  QUEUE     |  Data Remained     |   %3d    ",
                 scb.scb_q.size());
        $display("  TIME      |  End Time          |  %t", $realtime);
        $display("============================================");
        $stop;
    endtask  //run

endclass  //environment


module tb_fifo ();
    logic w_clk, r_clk;
    fifo_interface fifo_if (
        w_clk,
        r_clk
    );

    environment env;

    fifo #(
        .ADDR(`ADDR),
        .BIT_WIDTH(`BIT_WIDTH)
    ) DUT (
        .w_clk(w_clk),
        .r_clk(r_clk),
        .rst  (fifo_if.rst),
        .we   (fifo_if.we),
        .wdata(fifo_if.wdata),
        .re   (fifo_if.re),
        .rdata(fifo_if.rdata),
        .full (fifo_if.full),
        .empty(fifo_if.empty)
    );

    always #5 w_clk = ~w_clk;
    always #5 r_clk = ~r_clk;

    initial begin
        $timeformat(-9, 3, "ns");
        w_clk = 0;
        r_clk = 0;
        env   = new(fifo_if);
        env.run();
    end
endmodule
