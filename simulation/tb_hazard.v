`timescale 1ns/1ps
// ============================================================================
// tb_hazards: directed hazard-handling verification for the IITB-RISC-26
// 6-stage pipeline. Self-contained: the program is written directly into
// instruction memory (hierarchical path CPU.DP.IMEM.memory), so no hex file
// is required.
//
// What it verifies, and how:
//   T1  EX forwarding (RAW chain)   back-to-back dependent ALU ops must give
//                                   correct results with ZERO stall cycles.
//   T2  Load-use stall + forward    lw followed immediately by a dependent
//                                   ALU op: correct result, EXACTLY 1 stall.
//   T3  Load -> branch forwarding   lw followed immediately by a dependent
//       (the bug that was fixed)    beq: branch must take the CORRECT path
//                                   (stale data would fall through), 1 stall.
//   T4  Branch flush                wrong-path shadow instructions (lli r7,255)
//                                   sit after each taken branch; if any commits,
//                                   r7 is poisoned to 255 and the test fails.
//   T5  RR forwarding to branch     ALU result produced 2 instrs before a
//                                   branch that consumes it: correct path,
//                                   zero stalls.
// Counters cross-check the mechanisms: total load-use stall cycles must be
// exactly 2 (T2 + T3) and taken-branch flush events exactly 2 (T3 + T5).
//
// Directed program (byte addr: instruction -> effect):
//   0x00: lli r1,10        r1 = 10
//   0x02: adi r2,r1,5      r2 = 15   <- RAW on r1 (MEM->EX forward)
//   0x04: adi r3,r2,3      r3 = 18   <- RAW on r2 (MEM->EX forward)
//   0x06: ada r4,r2,r3     r4 = 33   <- RAW on r3 (MEM->EX) and r2 (WB->EX)
//   0x08: lli r5,64        r5 = 64   (data-memory base)
//   0x0A: sw  r1,r5,0      mem[64] = 10
//   0x0C: lw  r6,r5,0      r6 = 10
//   0x0E: adi r2,r6,1      r2 = 11   <- LOAD-USE: 1 stall + forward
//   0x10: lw  r6,r5,0      r6 = 10
//   0x12: beq r6,r1,+2     TAKEN     <- LOAD->BRANCH: 1 stall + late-data fwd
//   0x14: lli r7,255       WRONG PATH (must be flushed)
//   0x16: adi r7,r6,2      r7 = 12
//   0x18: adi r3,r1,0      r3 = 10
//   0x1A: beq r3,r1,+2     TAKEN     <- RR forward of ALU result, no stall
//   0x1C: lli r7,255       WRONG PATH (must be flushed)
//   0x1E: adi r4,r4,1      r4 = 34
//   0x20: nop (halt)
//
// Expected final state: r1=10 r2=11 r3=10 r4=34 r5=64 r6=10 r7=12, mem[64]=10
// Expected counters:    load-use stalls = 2, taken-branch flushes = 2
// ============================================================================
module tb_hazards;
    reg clk, reset;
    wire [1:0]  MemWrite;
    wire [15:0] PC, Result, WriteData, DataAdr, ReadData;

    iitb_risc CPU (.clk(clk), .reset(reset), .MemWrite(MemWrite), .PC(PC),
                   .Result(Result), .WriteData(WriteData),
                   .DataAdr(DataAdr), .ReadData(ReadData));

    always #5 clk = ~clk;

    localparam HALT_PC = 16'h0020;

    integer i, cycles, drain;
    integer stall_cyc, flush_ev, fwd_ex_cyc;
    integer pass, fail;
    reg done;
    reg r7_poisoned;   // latches if the wrong-path lli r7,255 ever commits

    task chk (input [8*32-1:0] name, input [15:0] got, input [15:0] exp);
        begin
            if (got === exp) begin
                pass = pass + 1; $display("PASS  %-32s = %0d", name, $signed(got));
            end else begin
                fail = fail + 1; $display("FAIL  %-32s = %0d  (expected %0d)",
                                          name, $signed(got), $signed(exp));
            end
        end
    endtask

    initial begin
        clk = 0; reset = 1; done = 0; r7_poisoned = 0;
        cycles = 0; stall_cyc = 0; flush_ev = 0; fwd_ex_cyc = 0;
        pass = 0; fail = 0;

        // load the directed program (overrides whatever imem read from file)
        #1;
        for (i = 0; i <= 256; i = i + 1) CPU.DP.IMEM.memory[i] = 16'h0000;
        CPU.DP.IMEM.memory[ 0] = 16'h320A;  // lli r1,10
        CPU.DP.IMEM.memory[ 1] = 16'h0445;  // adi r2,r1,5
        CPU.DP.IMEM.memory[ 2] = 16'h0683;  // adi r3,r2,3
        CPU.DP.IMEM.memory[ 3] = 16'h1898;  // ada r4,r2,r3
        CPU.DP.IMEM.memory[ 4] = 16'h3A40;  // lli r5,64
        CPU.DP.IMEM.memory[ 5] = 16'h5340;  // sw  r1,r5,0
        CPU.DP.IMEM.memory[ 6] = 16'h4D40;  // lw  r6,r5,0
        CPU.DP.IMEM.memory[ 7] = 16'h0581;  // adi r2,r6,1   (load-use)
        CPU.DP.IMEM.memory[ 8] = 16'h4D40;  // lw  r6,r5,0
        CPU.DP.IMEM.memory[ 9] = 16'h8C42;  // beq r6,r1,+2  (load->branch)
        CPU.DP.IMEM.memory[10] = 16'h3EFF;  // lli r7,255    (wrong path)
        CPU.DP.IMEM.memory[11] = 16'h0F82;  // adi r7,r6,2
        CPU.DP.IMEM.memory[12] = 16'h0640;  // adi r3,r1,0
        CPU.DP.IMEM.memory[13] = 16'h8642;  // beq r3,r1,+2  (RR forward)
        CPU.DP.IMEM.memory[14] = 16'h3EFF;  // lli r7,255    (wrong path)
        CPU.DP.IMEM.memory[15] = 16'h0901;  // adi r4,r4,1
        CPU.DP.IMEM.memory[16] = 16'h0000;  // halt

        #21 reset = 0;
    end

    // cycle-by-cycle monitors
    always @(posedge clk) if (!reset && !done) begin
        cycles = cycles + 1;
        if (CPU.DP.HU.load_use)                                   stall_cyc = stall_cyc + 1;
        if (CPU.DP.HU.control_hazard && !CPU.DP.HU.load_use)      flush_ev  = flush_ev  + 1;
        if (CPU.DP.fwd_a != 2'b00 || CPU.DP.fwd_b != 2'b00)       fwd_ex_cyc = fwd_ex_cyc + 1;
        if (CPU.DP.RF.regfile[7] === 16'd255)                     r7_poisoned = 1;
        if (PC == HALT_PC) begin done = 1; drain = cycles + 5; end
        if (cycles > 5000) begin $display("TIMEOUT"); $finish; end
    end

    // final checks after the pipeline drains
    always @(posedge clk) if (done) begin
        if (cycles < drain) cycles = cycles + 1;
        else begin
            $display("=== hazard-handling checks ===");
            // r4 = 34 requires r2=15, r3=18 at 0x06 (T1 forwarding chain)
            // AND the taken branch at 0x1A to reach the +1 at 0x1E (T5).
            chk("T1/T5 fwd chain + RR branch: r4", CPU.DP.RF.regfile[4], 16'd34);
            chk("T2 load-use stall+fwd: r2",       CPU.DP.RF.regfile[2], 16'd11);
            chk("T3 load->branch path: r7",        CPU.DP.RF.regfile[7], 16'd12);
            chk("T4 flush, no wrong-path commit",  {15'd0, r7_poisoned}, 16'd0);
            chk("T5 branch target reached: r3",    CPU.DP.RF.regfile[3], 16'd10);
            chk("memory: mem[64] = 10",          CPU.DP.DMEM.memory[32], 16'd10);
            chk("counter: load-use stalls",      stall_cyc[15:0], 16'd2);
            chk("counter: taken-branch flushes", flush_ev[15:0],  16'd2);
            $display("----");
            $display("cycles=%0d  ex-forwarding active on %0d cycles", cycles, fwd_ex_cyc);
            if (fail == 0) $display("ALL HAZARD TESTS PASSED (%0d checks)", pass);
            else           $display("HAZARD TESTS FAILED: %0d of %0d checks", fail, pass + fail);
            $finish;
        end
    end
endmodule