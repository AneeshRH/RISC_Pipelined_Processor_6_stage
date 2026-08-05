//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.07.2026 21:42:10
// Design Name: 
// Module Name: dmem
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

module dmem (
    input clk,
    input[1:0] we,
    input[15:0] addr,
    input[15:0] wr_data,
    output[15:0] rd_data
);
    reg[15:0] memory[0:512];
    wire[14:0] widx=addr[15:1];
    integer i;

    initial for(i=0; i<=512; i=i+1) memory[i]=16'h0000;

    assign rd_data=(widx<=15'd512)?memory[widx]:16'h0000;

    always @(posedge clk) begin
        if(widx<=15'd512) begin
            if(we==2'b11) memory[widx]<=wr_data;
            else if(we==2'b01) memory[widx][7:0]<=wr_data[7:0];
            else if(we==2'b10) memory[widx][15:8]<=wr_data[15:8];
        end
    end
endmodule