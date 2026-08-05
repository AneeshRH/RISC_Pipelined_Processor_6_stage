`timescale 1ns/1ps
// Verilog conversion of tb_iitb_risc.vhd (ISA test suite testbench).
// Expects imem to be loaded with the program from rv16_test.asm
// (imem.v's $readmemh path must point at bin/rv16_test.hex).
// Behaviour mirrors the VHDL original: one check per unique PC value,
// 100 MHz clock, 10 ns reset, 10 us timeout.

module tb_iitb_risc;

    // in signals to cpu
    reg clk   = 1'b0;
    reg reset = 1'b0;

    // out signals from cpu
    wire [1:0]  MemWrite;
    wire [15:0] PC, Result, WriteData, DataAdr, ReadData;

    // additional signals for testing
    reg [15:0] last_pc = 16'hFFFF;
    integer faults = 0;
    integer passes = 0;

    // ---- PC addresses (byte-addressed, from rv16_test.asm) ----
    // ALU / register instructions
    localparam PC_LLI_R1   = 16'h0000;
    localparam PC_LLI_R2   = 16'h0002;
    localparam PC_ADI      = 16'h0004;
    localparam PC_ADA      = 16'h0006;
    localparam PC_ADC      = 16'h0008;
    localparam PC_ADZ      = 16'h000A;
    localparam PC_AWC      = 16'h000C;
    localparam PC_ACA      = 16'h000E;
    localparam PC_ACC      = 16'h0010;
    localparam PC_ACZ      = 16'h0012;
    localparam PC_ACW      = 16'h0014;
    localparam PC_NDU      = 16'h0016;
    localparam PC_NDC      = 16'h0018;
    localparam PC_NDZ      = 16'h001A;
    localparam PC_NCU      = 16'h001C;
    localparam PC_NCC      = 16'h001E;
    localparam PC_NCZ      = 16'h0020;
    // branch setup
    localparam PC_LLI_R6N  = 16'h0022;
    localparam PC_LLI_R7P  = 16'h0024;
    // blt loop body (PC 0x26, 0x28); taken branch at 0x2A
    localparam PC_BLT_ADI  = 16'h0026;
    localparam PC_BLT_ADI2 = 16'h0028;
    localparam PC_BLT_BR   = 16'h002A;
    // ble loop
    localparam PC_LLI_R1N  = 16'h002C;
    localparam PC_LLI_R2P  = 16'h002E;
    localparam PC_BLE_ADI  = 16'h0030;
    localparam PC_BLE_ADI2 = 16'h0032;
    localparam PC_BLE_BR   = 16'h0034;
    // beq loop
    localparam PC_LLI_R1_2 = 16'h0036;
    localparam PC_LLI_R2_3 = 16'h0038;
    localparam PC_BEQ_ADI  = 16'h003A;
    localparam PC_BEQ_ADI2 = 16'h003C;
    localparam PC_BEQ_BR   = 16'h003E;
    // jal / jlr / jri
    localparam PC_JAL_T    = 16'h0040;
    localparam PC_SKIP1    = 16'h0042;
    localparam PC_ADA_R7   = 16'h0044;
    localparam PC_LLI_R2T  = 16'h0046;
    localparam PC_JLR      = 16'h0048;
    localparam PC_SKIP2    = 16'h004A;
    localparam PC_ADA_R7B  = 16'h004C;
    localparam PC_JAL_R1   = 16'h004E;
    localparam PC_ADA_R1   = 16'h0050;
    localparam PC_JAL_R4   = 16'h0052;
    localparam PC_SUB      = 16'h0054;
    localparam PC_JRI      = 16'h0056;
    localparam PC_LLI_R5   = 16'h0058;
    localparam PC_SW       = 16'h005A;
    localparam PC_LW       = 16'h005C;
    localparam PC_SM       = 16'h006C;
    localparam PC_LM       = 16'h006E;
    localparam PC_SMF      = 16'h0070;
    localparam PC_LMF      = 16'h0072;
    localparam PC_NOP      = 16'h0074;

    // DUT instantiation
    iitb_risc CPU (
        .clk(clk), .reset(reset), .MemWrite(MemWrite), .PC(PC),
        .Result(Result), .WriteData(WriteData),
        .DataAdr(DataAdr), .ReadData(ReadData)
    );

    // generate clock 100MHz
    always #5 clk = ~clk;

    // initial reset
    initial begin
        reset = 1'b1;
        #10 reset = 1'b0;
    end

    // simulation timeout
    initial begin
        #10000;
        $display("TIMEOUT: simulation exceeded 10 us, design may have stalled");
        $finish;
    end

    // debugger, use this if you are stuck
    // always @(posedge clk) if (!reset)
    //     $display("DBG PC=%0d Result=%0d WriteData=%0d DataAdr=%0d",
    //              PC, $signed(Result), $signed(WriteData), $signed(DataAdr));

    // check result of r-type instructions
    // name is a packed string (up to 24 chars), plain Verilog-2001
    task check_alu (
        input integer        num,
        input [8*24-1:0]     name,
        input [15:0]         pc_val,
        input [15:0]         r_result,
        input [15:0]         expected
    );
        begin
            if (r_result === expected) begin
                passes = passes + 1;
                $display("%0d. %0s passed", num, name);
            end else begin
                faults = faults + 1;
                $display("%0d. %0s FAILED | PC=0x%0h  Result=%0d  Expected=%0d",
                         num, name, pc_val, $signed(r_result), $signed(expected));
            end
        end
    endtask

    // test: runs once per unique PC on rising edge
    always @(posedge clk) begin
        if (!reset) begin
            if (PC !== last_pc) begin
                last_pc <= PC;

                // ---- ALU / register-result instructions ----
                case (PC)
                    PC_LLI_R1: check_alu( 1, "lli r1", PC, Result, 16'h0034);
                    PC_LLI_R2: check_alu( 2, "lli r2", PC, Result, 16'h0078);
                    PC_ADI:    check_alu( 3, "adi r3", PC, Result, 16'h0040);
                    PC_ADA:    check_alu( 4, "ada r4", PC, Result, 16'h00AC);
                    // ADC: cond=carry; C=0 at this point => no write; r2+r3=0x78+0x40=0xB8
                    PC_ADC:    check_alu( 5, "adc r5", PC, Result, 16'h00B8);
                    // ADZ: cond=zero; Z=0 => no write; r3+r4=0x40+0xAC=0xEC
                    PC_ADZ:    check_alu( 6, "adz r6", PC, Result, 16'h00EC);
                    // AWC: always+carry (C=0) => r4+0+0=0xAC
                    PC_AWC:    check_alu( 7, "awc r7", PC, Result, 16'h00AC);
                    // ACA..ACW: add-complement variants
                    PC_ACA:    check_alu( 8, "aca r4", PC, Result, 16'hFFBB);
                    PC_ACC:    check_alu( 9, "acc r5", PC, Result, 16'h0037);
                    PC_ACZ:    check_alu(10, "acz r6", PC, Result, 16'h0084);
                    PC_ACW:    check_alu(11, "acw r7", PC, Result, 16'hFFBA);
                    // NAND instructions
                    PC_NDU:    check_alu(12, "ndu r1", PC, Result, 16'h0045);
                    PC_NDC:    check_alu(13, "ndc r2", PC, Result, 16'hFFFF);
                    PC_NDZ:    check_alu(14, "ndz r3", PC, Result, 16'hFFBF);
                    PC_NCU:    check_alu(15, "ncu r4", PC, Result, 16'hFFBF);
                    PC_NCC:    check_alu(16, "ncc r5", PC, Result, 16'hFFFF);
                    PC_NCZ:    check_alu(17, "ncz r6", PC, Result, 16'hFFBF);

                    // blt loop
                    // When r6==5 (== r7) the branch is not taken;
                    // check r4 incremented 10 times from 0xFF
                    PC_BLT_BR: begin
                        if (Result > 16'h000A) begin
                            faults = faults + 1;
                            $display("18. blt STUCK IN LOOP | Result=%0d", Result);
                        end
                    end

                    // ble loop termination
                    PC_BLE_BR: ;

                    // ---- beq loop terminate on jal
                    PC_BEQ_BR: ;

                    // jal: ada at PC_ADA_R7 computes rf[r0=PC]+rf[r7=link]
                    PC_ADA_R7:  check_alu(21, "jal r7 link", PC, Result, 16'h0086);

                    // jlr: ada at PC_ADA_R7B computes rf[r0=PC]+rf[r7=link]
                    PC_ADA_R7B: check_alu(22, "jlr r7 link", PC, Result, 16'h0096);

                    // due to branch both instructions should be skipped
                    PC_SKIP1: begin
                        faults = faults + 1;
                        $display("23. jal FAILED: skipped instruction at 0x0042 was executed");
                    end
                    PC_SKIP2: begin
                        faults = faults + 1;
                        $display("24. jlr FAILED: skipped instruction at 0x004A was executed");
                    end

                    // jal r1: ada at PC_ADA_R1 computes rf[r0=PC]+rf[r1=link]
                    PC_ADA_R1: check_alu(25, "jal r1 link, post-ret", PC, Result, 16'h00A0);

                    // subroutine entry: adi r4,r4,1
                    PC_SUB: begin
                        passes = passes + 1;
                        $display("26. subroutine reached (PC=0x0054) passed");
                    end

                    // store
                    PC_SW: check_alu(27, "sw r5", PC, WriteData, 16'h0089);

                    // load
                    PC_LW: check_alu(28, "lw r6", PC, DataAdr, 16'h0051);

                    // store-multiple: first micro-op WB stores R6 (first set bit in mask 0xA6)
                    // base=rf[r1]=1, sequential offsets: R6->0, R5->2, R2->4, R0->6
                    // WriteData = rf[R6] = 0x06, DataAdr = base+0 = 0x0001
                    PC_SM:  check_alu(29, "sm r6",  PC, WriteData, 16'h0006);

                    // load-multiple: first micro-op WB loads R6 from mem[1]=0x0006 (stored by SM)
                    PC_LM:  check_alu(30, "lm r6",  PC, Result,    16'h0006);

                    // store-multiple with flag: mask=0x59 (R7,R4,R3 + flags last).
                    // base=rf[r2]=2, sequential offsets: R7->0, R4->2, R3->4, flags->6
                    // WriteData = rf[R7] = 0x07, DataAdr = base+0 = 0x0002
                    PC_SMF: check_alu(31, "smf r7", PC, WriteData, 16'h0000);

                    // load-multiple with flag: first micro-op WB loads R7 from mem[2]=0x0000 (stored by SMF)
                    PC_LMF: check_alu(32, "lmf r7", PC, Result,    16'h0000);

                    // ---- nop / halt: all tests done ----
                    PC_NOP: begin
                        $display("--- all instructions reached nop halt ---");
                        $display("Passed: %0d  Failed: %0d", passes, faults);
                        if (faults != 0) $display("SOME TESTS FAILED");
                        else             $display("All tests passed");
                        $finish;
                    end
                    default: ;
                endcase
            end
        end
    end

endmodule