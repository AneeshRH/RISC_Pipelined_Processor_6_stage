//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.06.2026 20:17:15
// Design Name: 
// Module Name: hello
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
module imem (
    input      [15:0] addr,
    output     [15:0] instr
);
    reg [15:0] memory [0:256];
    integer i;

    initial begin
        for (i = 0; i <= 256; i = i + 1) memory[i] = 16'h0000;  // zero-fill remaining
        $readmemh("C:/Users/Aneesh R H/Documents/IITG Docs/verilogcodes/pipelined_processor/bin/rv16_test.hex", memory);             // use absolute path in Vivado
    end

    assign instr = memory[addr[15:1]];
endmodule