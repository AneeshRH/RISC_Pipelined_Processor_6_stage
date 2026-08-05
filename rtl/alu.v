`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.07.2026 21:40:15
// Design Name: 
// Module Name: alu
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


module alu (
    input[15:0] A,
    input[15:0] B,
    input[2:0] ALU_Sel,
    input Carry_in,
    output reg[15:0] Result,
    output reg Carry_out,
    output Zero
);
    reg[16:0] temp;

    assign Zero=(Result==16'h0000);

    always @(*) begin
        case(ALU_Sel)
            3'b000: temp={1'b0,A}+{1'b0,B};
            3'b001: temp={1'b0,A}+{1'b0,B}+{16'b0,Carry_in};
            3'b010: temp={1'b0,~(A&B)};
            3'b011: temp={1'b0,B};
            3'b100: temp={1'b0,A};
            3'b101: temp={1'b0,A}-{1'b0,B};
            default: temp=17'b0;
        endcase
        Result=temp[15:0];
        if(ALU_Sel==3'b000 || ALU_Sel==3'b001 || ALU_Sel==3'b101)
            Carry_out=temp[16];
        else
            Carry_out=1'b0;
    end
endmodule