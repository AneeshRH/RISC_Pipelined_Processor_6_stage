`timescale 1ns/1ps
module tb_controller;
    reg  [3:0] Op; reg Complement; reg [2:0] Cond; reg [1:0] ALUFlags;
    wire RegWrite, ALUSrc, ImmSrc;
    wire [1:0] MemWrite, ResultSrc, PCSrc; wire [2:0] ALUControl;
    integer pass=0, fail=0;

    controller dut(.Op(Op),.Complement(Complement),.Cond(Cond),.ALUFlags(ALUFlags),
        .RegWrite(RegWrite),.MemWrite(MemWrite),.ALUSrc(ALUSrc),.ALUControl(ALUControl),
        .ImmSrc(ImmSrc),.ResultSrc(ResultSrc),.PCSrc(PCSrc));

    task chk; input got, exp; input [95:0] nm; begin
        if (got===exp) begin pass=pass+1; $display("PASS %0s", nm); end
        else begin fail=fail+1; $display("FAIL %0s got %b exp %b", nm, got, exp); end
    end endtask

    initial begin
        Complement=0;
        // add uncond
        Op=4'b0001; Cond=3'b000; ALUFlags=2'b00; #1;
        chk(RegWrite,1,"add uncond RW"); chk(ALUControl==3'b000,1,"add ALUctrl");
        // add-if-carry: C=1 commits, C=0 not
        Op=4'b0001; Cond=3'b010; ALUFlags=2'b10; #1; chk(RegWrite,1,"adc C=1 RW");
        Op=4'b0001; Cond=3'b010; ALUFlags=2'b00; #1; chk(RegWrite,0,"adc C=0 noRW");
        // add-if-zero: Z=1 commits
        Op=4'b0001; Cond=3'b001; ALUFlags=2'b01; #1; chk(RegWrite,1,"adz Z=1 RW");
        Op=4'b0001; Cond=3'b001; ALUFlags=2'b00; #1; chk(RegWrite,0,"adz Z=0 noRW");
        // awc: ALUControl=001
        Op=4'b0001; Cond=3'b011; ALUFlags=2'b00; #1;
        chk(RegWrite,1,"awc RW"); chk(ALUControl==3'b001,1,"awc ALUctrl=001");
        // nand uncond
        Op=4'b0010; Cond=3'b000; #1; chk(RegWrite,1,"nand RW"); chk(ALUControl==3'b010,1,"nand ctrl");
        // lli
        Op=4'b0011; #1; chk(ALUControl==3'b011,1,"lli PASSB"); chk(ImmSrc,1,"lli imm");
        // adi
        Op=4'b0000; #1; chk(RegWrite,1,"adi RW"); chk(ALUSrc,1,"adi ALUSrc");
        // lw
        Op=4'b0100; #1; chk(RegWrite,1,"lw RW"); chk(ResultSrc==2'b01,1,"lw ResSrc");
        // sw
        Op=4'b0101; #1; chk(MemWrite==2'b11,1,"sw MemWrite"); chk(RegWrite,0,"sw noRW");
        // branch
        Op=4'b1000; #1; chk(PCSrc==2'b01,1,"branch PCSrc");
        // jal / jlr / jri
        Op=4'b1100; #1; chk(RegWrite,1,"jal RW"); chk(PCSrc==2'b11,1,"jal PCSrc");
        Op=4'b1101; #1; chk(PCSrc==2'b10,1,"jlr PCSrc");
        Op=4'b1111; #1; chk(RegWrite,0,"jri noRW"); chk(PCSrc==2'b11,1,"jri PCSrc");

        $display("----\nPASS=%0d FAIL=%0d", pass, fail);
        if(fail==0) $display("ALL TESTS PASSED"); else $display("SOME FAILED");
        $finish;
    end
endmodule