//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2026 09:45:12
// Design Name: 
// Module Name: pl_s2
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

// Pipeline register S2: ID/OR.c arries pc, pc_plus2, control signals,
// register indices, and raw immediate fields.
module pl_s2 (
    input clk,
    input reset,
    input stall,
    input flush,
    input[15:0] pc_d,
    input[15:0] pc_plus2_d,
    input reg_write_d,
    input[1:0] mem_write_d,
    input alu_src_d,
    input[2:0] alu_ctrl_d,
    input[1:0] imm_src_d,
    input[1:0] res_src_d,
    input[1:0] pc_src_d,
    input[2:0] rb_d,
    input[2:0] rc_d,
    input[2:0] ra_d,
    input[5:0] imm6_d,
    input[8:0] imm9_d,
    input[3:0] op_d,
    output reg[15:0] pc_r,
    output reg[15:0] pc_plus2_r,
    output reg reg_write_r,
    output reg[1:0] mem_write_r,
    output reg alu_src_r,
    output reg[2:0] alu_ctrl_r,
    output reg[1:0] imm_src_r,
    output reg[1:0] res_src_r,
    output reg[1:0] pc_src_r,
    output reg[2:0] rb_r,
    output reg[2:0] rc_r,
    output reg[2:0] ra_r,
    output reg[5:0] imm6_r,
    output reg[8:0] imm9_r,
    output reg[3:0] op_r
);
    always @(posedge clk) begin
        if(reset || flush) begin
            pc_r<=16'hFFFE;
            pc_plus2_r<=16'hFFFE;
            reg_write_r<=1'b0; mem_write_r<=2'b00; alu_src_r<=1'b0;
            alu_ctrl_r<=3'b000;
            imm_src_r<=2'b00;
            res_src_r<=2'b00;
            pc_src_r<=2'b00;
            rb_r<=3'b000;
            rc_r<=3'b000;
            ra_r<=3'b000;
            imm6_r<=6'b000000;
            imm9_r<=9'b000000000;
            op_r<=4'b0000;
        end else if(~stall) begin
            pc_r<=pc_d;
            pc_plus2_r<=pc_plus2_d;
            reg_write_r<=reg_write_d; mem_write_r<=mem_write_d;
            alu_src_r<=alu_src_d; alu_ctrl_r<=alu_ctrl_d;
            imm_src_r<=imm_src_d; res_src_r<=res_src_d;
            pc_src_r<=pc_src_d;
            rb_r<=rb_d; rc_r<=rc_d;
            ra_r<=ra_d;
            imm6_r<=imm6_d; imm9_r<=imm9_d;
            op_r<=op_d;
        end
    end
endmodule