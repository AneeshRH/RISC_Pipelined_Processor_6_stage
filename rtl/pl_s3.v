//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2026 11:20:10
// Design Name: 
// Module Name: pl_s3
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

// Pipeline register S3: OR/EX. Carries pc, control, register reads, immediate,
// source/destination indices, and flags (with the LMF/SMF flags_op marker).
module pl_s3 (
    input clk,
    input reset,
    input stall,
    input flush,
    input[15:0] pc_r,
    input[15:0] pc_plus2_r,
    input reg_write_r,
    input[1:0] mem_write_r,
    input alu_src_r,
    input[2:0] alu_ctrl_r,
    input[1:0] imm_src_r,
    input[1:0] res_src_r,
    input[15:0] rd1_r,
    input[15:0] rd2_r,
    input[15:0] imm_ext_r,
    input[2:0] rc_r,
    input[2:0] ra_r,
    input[2:0] write_reg_r,
    input[1:0] flags_r,
    input flags_op_r,
    output reg[15:0] pc_e,
    output reg[15:0] pc_plus2_e,
    output reg reg_write_e,
    output reg[1:0] mem_write_e,
    output reg alu_src_e,
    output reg[2:0] alu_ctrl_e,
    output reg[1:0] imm_src_e,
    output reg[1:0] res_src_e,
    output reg[15:0] rd1_e,
    output reg[15:0] rd2_e,
    output reg[15:0] imm_ext_e,
    output reg[2:0] rc_e,
    output reg[2:0] ra_e,
    output reg[2:0] write_reg_e,
    output reg[1:0] flags_e,
    output reg flags_op_e
);
    always @(posedge clk) begin
        if(reset || flush) begin
            pc_e<=16'hFFFE;
            pc_plus2_e<=16'hFFFE;
            reg_write_e<=1'b0; mem_write_e<=2'b00; alu_src_e<=1'b0;
            alu_ctrl_e<=3'b000;
            imm_src_e<=2'b00;
            res_src_e<=2'b00;
            rd1_e<=16'h0000;
            rd2_e<=16'h0000;
            imm_ext_e<=16'h0000;
            rc_e<=3'b000;
            ra_e<=3'b000;
            write_reg_e<=3'b000;
            flags_e<=2'b00;
            flags_op_e<=1'b0;
        end else if(~stall) begin
            pc_e<=pc_r;
            pc_plus2_e<=pc_plus2_r;
            reg_write_e<=reg_write_r; mem_write_e<=mem_write_r;
            alu_src_e<=alu_src_r; alu_ctrl_e<=alu_ctrl_r;
            imm_src_e<=imm_src_r; res_src_e<=res_src_r;
            rd1_e<=rd1_r; rd2_e<=rd2_r;
            imm_ext_e<=imm_ext_r;
            rc_e<=rc_r; ra_e<=ra_r;
            write_reg_e<=write_reg_r;
            flags_e<=flags_r;
            flags_op_e<=flags_op_r;
        end
    end
endmodule