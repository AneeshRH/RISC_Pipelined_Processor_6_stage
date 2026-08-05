//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.07.2026 16:32:05
// Design Name: 
// Module Name: pl_s4
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

// Pipeline register S4: EX/MEM. Carries pc, control, ALU result, store data,
// destination index, and flags.
module pl_s4 (
    input clk,
    input reset,
    input stall,
    input flush,
    input[15:0] pc_e,
    input[15:0] pc_plus2_e,
    input reg_write_e,
    input[1:0] mem_write_e,
    input[1:0] res_src_e,
    input[15:0] alu_result_e,
    input[15:0] store_data_e,
    input[2:0] write_reg_e,
    input[1:0] flags_e,
    input flags_op_e,
    output reg[15:0] pc_m,
    output reg[15:0] pc_plus2_m,
    output reg reg_write_m,
    output reg[1:0] mem_write_m,
    output reg[1:0] res_src_m,
    output reg[15:0] alu_result_m,
    output reg[15:0] store_data_m,
    output reg[2:0] write_reg_m,
    output reg[1:0] flags_m,
    output reg flags_op_m
);
    always @(posedge clk) begin
        if(reset || flush) begin
            pc_m<=16'hFFFE;
            pc_plus2_m<=16'hFFFE;
            reg_write_m<=1'b0; mem_write_m<=2'b00;
            res_src_m<=2'b00;
            alu_result_m<=16'h0000;
            store_data_m<=16'h0000;
            write_reg_m<=3'b000;
            flags_m<=2'b00;
            flags_op_m<=1'b0;
        end else if(~stall) begin
            pc_m<=pc_e;
            pc_plus2_m<=pc_plus2_e;
            reg_write_m<=reg_write_e; mem_write_m<=mem_write_e;
            res_src_m<=res_src_e;
            alu_result_m<=alu_result_e;
            store_data_m<=store_data_e;
            write_reg_m<=write_reg_e;
            flags_m<=flags_e;
            flags_op_m<=flags_op_e;
        end
    end
endmodule