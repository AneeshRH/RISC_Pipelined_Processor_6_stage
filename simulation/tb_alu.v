`timescale 1ns/1ps
module tb_alu;
    reg  [15:0] A, B;
    reg  [2:0]  ALU_Sel;
    reg         Carry_in;
    wire [15:0] Result;
    wire        Carry_out, Zero;
    integer pass=0, fail=0;

    alu dut(.A(A),.B(B),.ALU_Sel(ALU_Sel),.Carry_in(Carry_in),
            .Result(Result),.Carry_out(Carry_out),.Zero(Zero));

    task chk;
        input [15:0] r; input co, z; input [79:0] nm;
        begin
            if (Result===r && Carry_out===co && Zero===z) begin
                pass=pass+1; $display("PASS %0s R=%h C=%b Z=%b", nm, Result, Carry_out, Zero);
            end else begin
                fail=fail+1; $display("FAIL %0s R=%h(exp %h) C=%b(exp %b) Z=%b(exp %b)",
                    nm, Result, r, Carry_out, co, Zero, z);
            end
        end
    endtask

    initial begin
        Carry_in=0;
        ALU_Sel=3'b000; A=16'hFFFF; B=16'h0001; #1 chk(16'h0000,1,1,"ADD ovf->0");
        ALU_Sel=3'b000; A=16'h1234; B=16'h1111; #1 chk(16'h2345,0,0,"ADD");
        ALU_Sel=3'b001; A=16'hFFFF; B=16'h0000; Carry_in=1; #1 chk(16'h0000,1,1,"ADC carry");
        Carry_in=0;
        ALU_Sel=3'b010; A=16'hFFFF; B=16'hFFFF; #1 chk(16'h0000,0,1,"NAND->0,Csupp");
        ALU_Sel=3'b010; A=16'hF0F0; B=16'h0F0F; #1 chk(16'hFFFF,0,0,"NAND");
        ALU_Sel=3'b011; B=16'hBEEF; #1 chk(16'hBEEF,0,0,"PASS B");
        ALU_Sel=3'b100; A=16'hDEAD; #1 chk(16'hDEAD,0,0,"PASS A");
        ALU_Sel=3'b101; A=16'h0005; B=16'h0003; #1 chk(16'h0002,0,0,"SUB");
        ALU_Sel=3'b101; A=16'h0000; B=16'h0001; #1 chk(16'hFFFF,1,0,"SUB borrow");

        $display("----\nPASS=%0d FAIL=%0d", pass, fail);
        if (fail==0) $display("ALL TESTS PASSED"); else $display("SOME FAILED");
        $finish;
    end
endmodule