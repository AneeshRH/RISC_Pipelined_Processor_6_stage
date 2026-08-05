`timescale 1ns/1ps
module tb_register_file;
    reg         clk, reset, we, r0_redirect;
    reg  [15:0] pc_next, write_data;
    reg  [2:0]  read_reg1, read_reg2, write_reg;
    wire [15:0] read_data1, read_data2, pc;
    integer pass=0, fail=0;

    register_file dut(.clk(clk),.reset(reset),.we(we),.pc_next(pc_next),
        .read_reg1(read_reg1),.read_reg2(read_reg2),.write_reg(write_reg),
        .write_data(write_data),.r0_redirect(r0_redirect),
        .read_data1(read_data1),.read_data2(read_data2),.pc(pc));

    always #5 clk=~clk;

    task chk; input [15:0] got, exp; input [127:0] nm; begin
        if (got===exp) begin pass=pass+1; $display("PASS %0s : %h", nm, got); end
        else begin fail=fail+1; $display("FAIL %0s : %h exp %h", nm, got, exp); end
    end endtask

    initial begin
        clk=0; reset=0; we=0; r0_redirect=0; pc_next=0; write_data=0;
        read_reg1=0; read_reg2=0; write_reg=0;

        reset=1; @(negedge clk); reset=0;
        read_reg1=0; read_reg2=3; #1;
        chk(pc,16'h0000,"reset pc=0"); chk(read_data2,16'h0000,"reset R3=0");

        // normal PC advance
        @(negedge clk); pc_next=16'h0002; we=0; r0_redirect=0;
        @(negedge clk); #1; chk(pc,16'h0002,"advance to 0002");
        pc_next=16'h0004; @(negedge clk); #1; chk(pc,16'h0004,"advance to 0004");

        // r0_redirect overrides pc_next
        @(negedge clk); r0_redirect=1; write_data=16'h0100; pc_next=16'h0006;
        @(negedge clk); #1; chk(pc,16'h0100,"redirect to 0100");
        r0_redirect=0;

        // normal register write to R3
        @(negedge clk); we=1; write_reg=3'd3; write_data=16'hABCD; pc_next=16'h0102;
        @(negedge clk); we=0;
        read_reg1=3; #1; chk(read_data1,16'hABCD,"R3 written"); chk(pc,16'h0102,"pc still advances");

        // write_reg=000 guard: must NOT corrupt PC with write_data
        @(negedge clk); we=1; write_reg=3'd0; write_data=16'hDEAD; pc_next=16'h0104; r0_redirect=0;
        @(negedge clk); we=0;
        #1; chk(pc,16'h0104,"guard: pc from pc_next not DEAD");

        // write-first bypass, both ports, same cycle (combinational)
        @(negedge clk); we=1; write_reg=3'd5; write_data=16'hCAFE; read_reg1=5;
        #1; chk(read_data1,16'hCAFE,"bypass port1 R5");
        we=1; write_reg=3'd6; write_data=16'hF00D; read_reg2=6;
        #1; chk(read_data2,16'hF00D,"bypass port2 R6");
        @(negedge clk); we=0;

        // reading R0 returns current PC, never bypassed to pc_next
        read_reg1=0; pc_next=16'h9999; #1;
        chk(read_data1,pc,"R0 read = current pc");

        $display("----\nPASS=%0d FAIL=%0d", pass, fail);
        if(fail==0) $display("ALL TESTS PASSED"); else $display("SOME FAILED");
        $finish;
    end
endmodule