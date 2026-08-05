//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.07.2026 21:50:35
// Design Name: 
// Module Name: pl_s5
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

// Pipeline register S5: MEM/WB. Carries pc, control, ALU result, store data,
// memory read data, destination index, and flags.
// NOTE: on flush, pc_plus2_w resets to 0 (not FFFE) -- preserved from the source.
module pl_s5 (
    input clk,
    input reset,
    input stall,
    input flush,
    input[15:0] pc_m,
    input[15:0] pc_plus2_m,
    input reg_write_m,
    input[1:0] mem_write_m,
    input[1:0] res_src_m,
    input[15:0] alu_result_m,
    input[15:0] store_data_m,
    input[15:0] rd_data_m,
    input[2:0] write_reg_m,
    input[1:0] flags_m,
    input flags_op_m,
    output reg[15:0] pc_w,
    output reg[15:0] pc_plus2_w,
    output reg reg_write_w,
    output reg[1:0] mem_write_w,
    output reg[1:0] res_src_w,
    output reg[15:0] alu_result_w,
    output reg[15:0] store_data_w,
    output reg[15:0] rd_data_w,
    output reg[2:0] write_reg_w,
    output reg[1:0] flags_w,
    output reg flags_op_w
);
    always @(posedge clk) begin
        if(reset || flush) begin
            pc_w<=16'hFFFE;
            pc_plus2_w<=16'h0000;
            reg_write_w<=1'b0;
            mem_write_w<=2'b00;
            res_src_w<=2'b00;
            alu_result_w<=16'h0000;
            store_data_w<=16'h0000;
            rd_data_w<=16'h0000;
            write_reg_w<=3'b000;
            flags_w<=2'b00;
            flags_op_w<=1'b0;
        end else if(~stall) begin
            pc_w<=pc_m;
            pc_plus2_w<=pc_plus2_m;
            reg_write_w<=reg_write_m;
            mem_write_w<=mem_write_m;
            res_src_w<=res_src_m;
            alu_result_w<=alu_result_m;
            store_data_w<=store_data_m;
            rd_data_w<=rd_data_m;
            write_reg_w<=write_reg_m;
            flags_w<=flags_m;
            flags_op_w<=flags_op_m;
        end
    end
endmodule