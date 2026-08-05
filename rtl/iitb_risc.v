
module iitb_risc (
    input clk,
    input reset,
    output [1:0]  MemWrite,
    output [15:0] PC,
    output [15:0] Result,
    output [15:0] WriteData,
    output [15:0] DataAdr,
    output [15:0] ReadData
);
    datapath DP (
        .clk(clk),
        .reset(reset),
        .PC_out(PC),
        .Result_out(Result),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .ReadData(ReadData),
        .MemWrite_out(MemWrite)
    );
endmodule