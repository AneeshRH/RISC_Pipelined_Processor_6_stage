`timescale 1ns/1ps
module tb_hazard_unit;
    reg [2:0] rb_or,rc_or,ra_or,rc_ex,ra_ex,write_reg_ex,write_reg_mem,write_reg_wb;
    reg regwrite_ex,regwrite_mem,regwrite_wb; reg [1:0] res_src_ex,pc_sel_or;
    wire [1:0] fwd_a,fwd_b; wire stall_if,stall_id,stall_or,flush_s1,flush_s2,flush_s3;
    integer pass=0, fail=0;
    hazard_unit dut(.rb_or(rb_or),.rc_or(rc_or),.ra_or(ra_or),.rc_ex(rc_ex),.ra_ex(ra_ex),
        .write_reg_ex(write_reg_ex),.regwrite_ex(regwrite_ex),.res_src_ex(res_src_ex),
        .write_reg_mem(write_reg_mem),.regwrite_mem(regwrite_mem),
        .write_reg_wb(write_reg_wb),.regwrite_wb(regwrite_wb),.pc_sel_or(pc_sel_or),
        .fwd_a(fwd_a),.fwd_b(fwd_b),.stall_if(stall_if),.stall_id(stall_id),.stall_or(stall_or),
        .flush_s1(flush_s1),.flush_s2(flush_s2),.flush_s3(flush_s3));
    task chk; input g,e; input [95:0] nm; begin
        if(g===e) begin pass=pass+1; $display("PASS %0s",nm); end
        else begin fail=fail+1; $display("FAIL %0s got %b exp %b",nm,g,e); end
    end endtask
    task chk2; input [1:0] g,e; input [95:0] nm; begin
        if(g===e) begin pass=pass+1; $display("PASS %0s",nm); end
        else begin fail=fail+1; $display("FAIL %0s got %b exp %b",nm,g,e); end
    end endtask
    initial begin
        {rb_or,rc_or,ra_or,rc_ex,ra_ex,write_reg_ex,write_reg_mem,write_reg_wb}=0;
        {regwrite_ex,regwrite_mem,regwrite_wb}=0; res_src_ex=0; pc_sel_or=0;
        // load-use
        res_src_ex=2'b01; regwrite_ex=1; write_reg_ex=3'd3; rc_or=3'd3; #1;
        chk(stall_if,1,"loaduse stall_if"); chk(flush_s3,1,"loaduse flush_s3");
        chk(flush_s1,0,"loaduse no flush_s1");
        // no load-use when dest=0
        write_reg_ex=3'd0; #1; chk(stall_if,0,"no loaduse dest0");
        // control hazard
        res_src_ex=0; regwrite_ex=0; rc_or=0; pc_sel_or=2'b01; #1;
        chk(flush_s1,1,"ctrl flush_s1"); chk(flush_s2,1,"ctrl flush_s2");
        // control hazard suppressed by load-use
        res_src_ex=2'b01; regwrite_ex=1; write_reg_ex=3'd4; ra_or=3'd4; pc_sel_or=2'b01; #1;
        chk(flush_s1,0,"loaduse suppresses ctrl flush");
        chk(stall_or,1,"loaduse still stalls");
        // forwarding priority MEM > WB on fwd_a
        res_src_ex=0; regwrite_ex=0; write_reg_ex=0; rc_or=0; ra_or=0; pc_sel_or=0;
        rc_ex=3'd5; regwrite_mem=1; write_reg_mem=3'd5; regwrite_wb=1; write_reg_wb=3'd5; #1;
        chk2(fwd_a,2'b10,"fwd_a MEM priority");
        // WB only
        regwrite_mem=0; #1; chk2(fwd_a,2'b01,"fwd_a WB");
        // none
        regwrite_wb=0; #1; chk2(fwd_a,2'b00,"fwd_a none");
        // fwd_b via ra_ex
        ra_ex=3'd6; regwrite_mem=1; write_reg_mem=3'd6; #1; chk2(fwd_b,2'b10,"fwd_b MEM");
        // R0 never forwarded
        rc_ex=3'd0; write_reg_mem=3'd0; #1; chk2(fwd_a,2'b00,"R0 not forwarded");
        $display("----\nPASS=%0d FAIL=%0d",pass,fail);
        if(fail==0) $display("ALL TESTS PASSED"); else $display("SOME FAILED");
        $finish;
    end
endmodule