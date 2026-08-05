`timescale 1ns/1ps
module tb_dmem;
    reg clk; reg [1:0] we; reg [15:0] addr, wr_data; wire [15:0] rd_data;
    integer pass=0, fail=0;
    dmem dut(.clk(clk),.we(we),.addr(addr),.wr_data(wr_data),.rd_data(rd_data));
    always #5 clk=~clk;
    task chk; input [15:0] g,e; input [95:0] nm; begin
        if(g===e) begin pass=pass+1; $display("PASS %0s : %h",nm,g); end
        else begin fail=fail+1; $display("FAIL %0s : %h exp %h",nm,g,e); end
    end endtask
    initial begin
        clk=0; we=0; addr=0; wr_data=0;
        addr=16'h0002; #1 chk(rd_data,16'h0000,"unwritten=0");
        // full word
        @(negedge clk); we=2'b11; addr=16'h0004; wr_data=16'hABCD; @(negedge clk); we=0;
        addr=16'h0004; #1 chk(rd_data,16'hABCD,"full word");
        // low byte over 0x0000
        @(negedge clk); we=2'b11; addr=16'h0006; wr_data=16'h0000; @(negedge clk);
        we=2'b01; addr=16'h0006; wr_data=16'h12EF; @(negedge clk); we=0;
        addr=16'h0006; #1 chk(rd_data,16'h00EF,"low byte");
        // high byte
        @(negedge clk); we=2'b10; addr=16'h0006; wr_data=16'hBE34; @(negedge clk); we=0;
        addr=16'h0006; #1 chk(rd_data,16'hBEEF,"high byte merged");
        // out of bound
        addr=16'hFFFE; #1 chk(rd_data,16'h0000,"out of bound=0");
        $display("----\nPASS=%0d FAIL=%0d",pass,fail);
        if(fail==0) $display("ALL TESTS PASSED"); else $display("SOME FAILED");
        $finish;
    end
endmodule