//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2026 10:10:15
// Design Name: 
// Module Name: pl_s1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module pl_s1 (
    input clk,
    input reset,
    input stall,
    input flush,
    input [15:0] pc_f,
    input [15:0] pc_plus2_f,
    input [15:0] instr_f,
    output reg [15:0] pc_d,
    output reg [15:0] pc_plus2_d,
    output reg [15:0] instr_d
);
    always @(posedge clk) begin
        if (reset || flush) begin
            pc_d       <= 16'hFFFE;
            pc_plus2_d <= 16'hFFFE;
            instr_d    <= 16'h0000;   // NOP
        end else if (~stall) begin
            pc_d       <= pc_f;
            pc_plus2_d <= pc_plus2_f;
            instr_d    <= instr_f;
        end
        // stall=1, flush=0: hold current values
    end
endmodule