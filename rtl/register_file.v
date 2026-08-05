//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2026 10:45:22
// Design Name: 
// Module Name: register_file
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

// IITB-RISC-26 register file with R0 = PC.
// R0 advances to pc_next every cycle, or takes write_data when r0_redirect=1
// (a genuine computed R0 write, e.g. a jump/link). Normal write port never
// touches R0 (write_reg != 0 guard), so reads of R0 return the live PC.
// Reads are combinational with write-first bypass on the two read ports.
module register_file (
    input clk,
    input reset,
    input we,
    input[15:0] pc_next,
    input[2:0] read_reg1,
    input[2:0] read_reg2,
    input[2:0] write_reg,
    input[15:0] write_data,
    input r0_redirect,
    output[15:0] read_data1,
    output[15:0] read_data2,
    output[15:0] pc
);
    reg[15:0] regfile[0:7];
    integer i;

    always @(posedge clk) begin
        if(reset) begin
            for(i=0; i<8; i=i+1)
                regfile[i]<=16'h0000;
        end else begin
            if(r0_redirect) regfile[0]<=write_data;
            else regfile[0]<=pc_next;
            if(we && write_reg!=3'b000)
                regfile[write_reg]<=write_data;
        end
    end

    assign read_data1=(we && write_reg!=3'b000 && write_reg==read_reg1)?write_data:regfile[read_reg1];
    assign read_data2=(we && write_reg!=3'b000 && write_reg==read_reg2)?write_data:regfile[read_reg2];
    assign pc=regfile[0];
endmodule