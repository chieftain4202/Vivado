

module tb_fork_join ();

/*
    //1
    initial begin
        #1 $display("%t : start  fork - join", $time);

        fork
            // task A
            #10 A_thread();
            // task B
            #20 B_thread();
            // task C
            #15 C_thread();
        join

        #10 $display("%t : end  fork - join", $time);
    end

    
    //2
    initial begin
        #1 $display("%t : start fork - join_any", $time);

        fork
            // task A
            #10 A_thread();
            // task B
            #20 B_thread();
            // task C
            #15 C_thread();
        join_any

        #10 $display("%t : end fork - join_any", $time);
    end


    //3
    initial begin
        #1 $display("%t : start  fork - join_none", $time);

        fork
            // task A
            #10 A_thread();
            // task B
            #20 B_thread();
            // task C
            #15 C_thread();
        join_none

        #10 $display("%t : end  fork - join_none", $time);
    end
*/

    //4
    initial begin
        #1 $display("%t : start fork_fork - join_any", $time);

        fork
            // task A
            #10 A_thread();

            fork
                // task B
                #20 B_thread();
                #50 B_thread();
            join

            // task C
            #30 C_thread();
        join_any

        #10 $display("%t : end fork_fork - join_any", $time);
    end

/*
    //5
    initial begin
        #1 $display("%t : start fork_disable - join_any", $time);

        fork
            // task A
            A_thread();
            // task B
            B_thread();
            // task C
            C_thread();
        join_any

        #10 $display("%t : end fork - join", $time);
        disable fork; // fork 내에서 실행 중인 다른 프로세스들을 종료함
        $stop;
    end
*/
    task A_thread();
        repeat(5) $display("%t : A thread", $time);
    endtask  //A_thread

    task B_thread();
        forever begin
        $display("%t : B thread", $time);
        #5;
        end
    endtask  //B_thread

    task C_thread();
    forever begin
        $display("%t : C thread", $time);
        #10;
    end
    endtask  //C_thread



endmodule
