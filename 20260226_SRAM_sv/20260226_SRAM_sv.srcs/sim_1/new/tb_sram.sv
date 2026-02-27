`timescale 1ns / 1ps

interface sram_interface (
    input clk
);
    logic [7:0] wdata;
    logic [3:0] addr;
    logic       we;
    logic [7:0] rdata;

endinterface  //sram_interface

class transaction;
    rand bit [7:0] wdata;
    rand bit [3:0] addr;
    rand bit       we;
    logic    [7:0] rdata;

    function void display(string name);
        $display("%t : [%s] we = %d,  addr = %2h, wdata = %2h, rdata = %2h ",
                 $time, name, we, addr, wdata, rdata);
    endfunction
    //    task display(string name);
    //        $display("%t : [%s] we = %d,  addr = %2h, wdata = %2h, rdata = %2h ",
    //           $time, name, we, addr, wdata, rdata);
    //    endtask

endclass  //transaction



class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;
    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    task run(int run_count);
        repeat (run_count) begin
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
    virtual sram_interface sram_if;
    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual sram_interface sram_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.sram_if      = sram_if;
    endfunction  //new()

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge sram_if.clk);
            sram_if.addr = tr.addr;
            sram_if.wdata = tr.wdata;
            sram_if.we = tr.we;
            tr.display("drv");
        end
    endtask  //run
endclass  //driver



class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual sram_interface sram_if;
    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual sram_interface sram_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.sram_if = sram_if;
    endfunction  //new()

    task run();
        forever begin
            @(posedge sram_if.clk);
            #1;
            tr       = new();
            tr.addr  = sram_if.addr;
            tr.wdata = sram_if.wdata;
            tr.rdata = sram_if.rdata;
            tr.we    = sram_if.we;
            tr.display("mon");
            mon2scb_mbox.put(tr);
        end
    endtask  //run
endclass  //monitor


class scoreboard;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    //covergroup
    covergroup cg_sram;
    cp_addr : coverpoint tr.addr{
        bins min = {0};
        bins max = {15};
        bins mid = {[1:14]};
    }
    endgroup


    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
        cg_sram = new();
    endfunction  //new()

    int pass_cnt, fail_cnt, total_cnt;

    task run();

        logic [7:0] expected_ram[0:15];
        pass_cnt  = 0;
        fail_cnt  = 0;
        total_cnt = 0;

        forever begin
            mon2scb_mbox.get(tr);
            total_cnt++;
            tr.display("scb");

            cg_sram.sample();
            //pass, fail
            if (tr.we) begin
                expected_ram[tr.addr] = tr.wdata;
                $display("2%h", expected_ram[tr.addr]);
            end else begin
                if (expected_ram[tr.addr] === tr.rdata)  begin
                $display("Pass");
                pass_cnt ++;
                end
                else begin
                    $display(
                        "Fail : expected data = %2h, rdata = %2h",
                        expected_ram[tr.addr],
                        tr.rdata
                    );
                    fail_cnt ++;
                end
            end
            ->gen_next_ev;
        end
    endtask  //run
endclass  //scoreboard


class environment;

    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    virtual sram_interface sram_if;

    event                  gen_next_ev;
    event                  scb2gen_ev;

    function new(virtual sram_interface sram_if);
        this.sram_if = sram_if;
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, sram_if);
        mon = new(mon2scb_mbox, sram_if);
        scb = new(mon2scb_mbox, gen_next_ev);

    endfunction  //new()

    task run();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;
        $display("coverage addr = %d",scb.cg_sram.get_inst_coverage());

        $display("___________________________");
        $display("** 8bit register verifi  **");
        $display("***************************");
        $display("**     Try Count = %3d    **", scb.total_cnt);
        $display("**    PASS Count = %3d    **", scb.pass_cnt);
        $display("**    FAIL Count = %3d    **", scb.fail_cnt);
        $display("***************************");

        $stop;
    endtask  //run
endclass  //environment



module tb_sram ();

    logic clk;
    sram_interface sram_if (clk);
    environment env;

    Sram dut (
        .clk(clk),
        .addr(sram_if.addr),
        .wdata(sram_if.wdata),
        .we(sram_if.we),
        .rdata(sram_if.rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        env = new(sram_if);
        env.run();
    end
endmodule
