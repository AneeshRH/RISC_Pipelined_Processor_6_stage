`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2026 10:10:15
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
module datapath (
    input clk,
    input reset,
    output [15:0] PC_out,
    output [15:0] Result_out,
    output [15:0] WriteData,
    output [15:0] DataAdr,
    output [15:0] ReadData,
    output [1:0] MemWrite_out
);
    wire [15:0] pc_if, pc_plus2_if, instr_if, pc_next_if;
    wire [15:0] s1_pc, s1_pc_plus2, s1_instr;
    wire s1_stall, s1_flush;
    wire id_reg_write, id_alu_src, id_imm_src0, id_imm_src1;
    wire [1:0] id_mem_write, id_res_src, id_pc_src, id_imm_src, id_alu_flags;
    wire [2:0] id_alu_ctrl;
    wire [15:0] s2_pc, s2_pc_plus2;
    wire s2_reg_write, s2_alu_src, s2_stall, s2_flush;
    wire [1:0] s2_mem_write, s2_imm_src, s2_res_src, s2_pc_src;
    wire [2:0] s2_alu_ctrl, s2_rb, s2_rc, s2_ra;
    wire [5:0] s2_imm6;
    wire [8:0] s2_imm9;
    wire [3:0] s2_op;
    wire [2:0] or_reg2_addr;
    wire [15:0] or_rd1, or_rd2, or_imm_ext, or_rd1_eff, or_rd2_eff, or_sub_result;
    wire or_sub_reduce, or_branch_taken, or_blt_neg, or_ble_cond;
    wire [15:0] or_branch_tgt, or_jri_tgt, or_jlr_tgt, or_imm6_x2, or_imm9_x2, or_imm6_sext, or_imm9_sext;
    wire [1:0] or_pc_sel;
    reg c_flag_reg, z_flag_reg;
    wire [15:0] s3_pc, s3_pc_plus2, s3_rd1, s3_rd2, s3_imm_ext;
    wire s3_reg_write, s3_alu_src, s3_stall, s3_flush, s3_flags_op;
    wire [1:0] s3_mem_write, s3_imm_src, s3_res_src, s3_flags;
    wire [2:0] s3_alu_ctrl, s3_rc, s3_ra, s3_write_reg;
    wire [15:0] ex_alu_a, ex_alu_b_reg, ex_alu_b, ex_alu_result;
    wire ex_carry_out, ex_zero;
    wire [1:0] fwd_a, fwd_b;
    wire [15:0] wb_write_data, s4_pc, s4_pc_plus2, s4_alu_result, s4_store_data;
    wire s4_reg_write, s4_stall, s4_flush, s4_flags_op;
    wire [1:0] s4_mem_write, s4_res_src, s4_flags;
    wire [2:0] s4_write_reg;
    wire [15:0] mem_rd_data, s5_pc, s5_pc_plus2, s5_alu_result, s5_store_data, s5_rd_data;
    wire s5_reg_write, s5_stall, s5_flush, s5_flags_op;
    wire [1:0] s5_mem_write, s5_res_src, s5_flags;
    wire [2:0] s5_write_reg;
    wire stall_if, stall_id, stall_or, flush_s1, flush_s2, flush_s3, wb_r0_wr;
    wire ls_op_in_or, ls_is_load, ls_stall_fetch, ls_flush_s3, ls_flush_s2;
    wire ls_entry, ls_valid, ls_done, ls_flags_op;
    wire [2:0] ls_rs1, ls_alu_ctrl, hu_rc_or, hu_ra_or, hu_rb_or;
    wire [15:0] ls_addr, ls_imm_val, s3_in_rd1, s3_in_rd2, s3_in_imm_ext;
    wire [2:0] s3_in_write_reg, s3_in_rc, s3_in_ra;
    wire s3_in_reg_write, s3_in_alu_src, s3_in_flags_op;
    wire [1:0] s3_in_mem_write, s3_in_res_src, s3_in_imm_src;

    // IF stage
    imem IMEM(
        .addr(pc_if),
        .instr(instr_if)
    );
    assign pc_plus2_if = pc_if + 16'd2;
    assign wb_r0_wr = (s5_reg_write && s5_write_reg == 3'b000 && s5_pc != 16'hFFFE);
    assign pc_next_if = (stall_if | ls_stall_fetch | ls_entry | ls_done) ? pc_if :
                        wb_r0_wr ? wb_write_data :
                        (or_pc_sel == 2'b01) ? or_branch_tgt :
                        (or_pc_sel == 2'b10) ? or_jlr_tgt :
                        (or_pc_sel == 2'b11) ? or_jri_tgt : pc_plus2_if;
    assign s1_stall = stall_id | ls_stall_fetch | ls_entry | ls_done;
    assign s1_flush = flush_s1 | wb_r0_wr;
    pl_s1 S1(
        .clk(clk),
        .reset(reset),
        .stall(s1_stall),
        .flush(s1_flush),
        .pc_f(pc_if),
        .pc_plus2_f(pc_plus2_if),
        .instr_f(instr_if),
        .pc_d(s1_pc),
        .pc_plus2_d(s1_pc_plus2),
        .instr_d(s1_instr)
    );

    // ID stage
    assign id_alu_flags = s4_reg_write ? s4_flags : s5_reg_write ? s5_flags : {c_flag_reg, z_flag_reg};
    controller CTRL(
        .Op(s1_instr[15:12]),
        .Complement(s1_instr[2]),
        .Cond(s1_instr[2:0]),
        .ALUFlags(id_alu_flags),
        .RegWrite(id_reg_write),
        .MemWrite(id_mem_write),
        .ALUSrc(id_alu_src),
        .ALUControl(id_alu_ctrl),
        .ImmSrc(id_imm_src0),
        .ResultSrc(id_res_src),
        .PCSrc(id_pc_src)
    );
    assign id_imm_src = {s1_instr[2], id_imm_src0};
    assign s2_stall = stall_or | ls_stall_fetch | ls_entry;
    assign s2_flush = flush_s2 | ls_flush_s2 | wb_r0_wr;
    pl_s2 S2(
        .clk(clk),
        .reset(reset),
        .stall(s2_stall),
        .flush(s2_flush),
        .pc_d(s1_pc),
        .pc_plus2_d(s1_pc_plus2),
        .reg_write_d(id_reg_write),
        .mem_write_d(id_mem_write),
        .alu_src_d(id_alu_src),
        .alu_ctrl_d(id_alu_ctrl),
        .imm_src_d(id_imm_src),
        .res_src_d(id_res_src),
        .pc_src_d(id_pc_src),
        .rb_d(s1_instr[11:9]),
        .rc_d(s1_instr[8:6]),
        .ra_d(s1_instr[5:3]),
        .imm6_d(s1_instr[5:0]),
        .imm9_d(s1_instr[8:0]),
        .op_d(s1_instr[15:12]),
        .pc_r(s2_pc),
        .pc_plus2_r(s2_pc_plus2),
        .reg_write_r(s2_reg_write),
        .mem_write_r(s2_mem_write),
        .alu_src_r(s2_alu_src),
        .alu_ctrl_r(s2_alu_ctrl),
        .imm_src_r(s2_imm_src),
        .res_src_r(s2_res_src),
        .pc_src_r(s2_pc_src),
        .rb_r(s2_rb),
        .rc_r(s2_rc),
        .ra_r(s2_ra),
        .imm6_r(s2_imm6),
        .imm9_r(s2_imm9),
        .op_r(s2_op)
    );

    // OR stage
    assign ls_op_in_or = (s2_op == 4'b0110 || s2_op == 4'b0111);
    assign ls_is_load = ~s2_op[0];
    assign ls_entry = ls_op_in_or & ~ls_stall_fetch & ~ls_done;
    assign ls_flush_s3 = ls_entry | ls_done;
    assign ls_flush_s2 = ls_done;
    ls_ucode LS(
        .clk(clk),
        .reset(reset),
        .enable(ls_op_in_or),
        .stall(stall_or),
        .flush(flush_s2 | ls_done),
        .rs1_addr(s2_rb),
        .rs1_addr_val(or_rd2_eff),
        .imm9(s2_imm9),
        .alu_ctrl(ls_alu_ctrl),
        .rs1(ls_rs1),
        .addr(ls_addr),
        .imm_val(ls_imm_val),
        .stall_fetch(ls_stall_fetch),
        .valid(ls_valid),
        .done(ls_done),
        .flags_op(ls_flags_op)
    );
    assign s3_in_rd2 = (ls_stall_fetch && ls_flags_op) ? {14'b0, c_flag_reg, z_flag_reg} : or_rd2_eff;
    assign s3_in_flags_op = ls_stall_fetch ? ls_flags_op : 1'b0;
    assign or_reg2_addr = ls_stall_fetch ? ls_rs1 : ((s2_op[3:2] == 2'b10)|(s2_op == 4'b0101)|(s2_op == 4'b1111)|(s2_op == 4'b0110)|(s2_op == 4'b0111)) ? s2_rb : s2_ra;
    register_file RF(
        .clk(clk),
        .reset(reset),
        .we(s5_reg_write),
        .pc_next(pc_next_if),
        .read_reg1(s2_rc),
        .read_reg2(or_reg2_addr),
        .write_reg(s5_write_reg),
        .write_data(wb_write_data),
        .read_data1(or_rd1),
        .read_data2(or_rd2),
        .pc(pc_if),
        .r0_redirect(wb_r0_wr)
    );
    assign or_rd1_eff = (s2_rc == 3'b000) ? s2_pc : (s3_reg_write && s3_write_reg != 3'b000 && s3_write_reg == s2_rc && s3_res_src != 2'b01) ? ex_alu_result : (s4_reg_write && s4_write_reg != 3'b000 && s4_write_reg == s2_rc) ? (s4_res_src == 2'b01 ? mem_rd_data : s4_alu_result) : (s5_reg_write && s5_write_reg != 3'b000 && s5_write_reg == s2_rc) ? wb_write_data : or_rd1;
    assign or_rd2_eff = (or_reg2_addr == 3'b000 && ls_stall_fetch == 1'b0) ? s2_pc : (s3_reg_write && s3_write_reg != 3'b000 && s3_write_reg == or_reg2_addr && s3_res_src != 2'b01) ? ex_alu_result : (s4_reg_write && s4_write_reg != 3'b000 && s4_write_reg == or_reg2_addr) ? (s4_res_src == 2'b01 ? mem_rd_data : s4_alu_result) : (s5_reg_write && s5_write_reg != 3'b000 && s5_write_reg == or_reg2_addr) ? wb_write_data : or_rd2;
    sign_extender SIEXT(
        .imm6(s2_imm6),
        .imm9(s2_imm9),
        .sel(s2_imm_src[0]),
        .out16(or_imm_ext)
    );
    assign or_imm6_sext = {{10{s2_imm6[5]}}, s2_imm6};
    assign or_imm9_sext = {{7{s2_imm9[8]}}, s2_imm9};
    assign or_imm6_x2 = {or_imm6_sext[14:0], 1'b0};
    assign or_imm9_x2 = {or_imm9_sext[14:0], 1'b0};
    assign or_branch_tgt = s2_pc + or_imm6_x2;
    assign or_jri_tgt = (s2_op == 4'b1111) ? (or_rd2_eff + or_imm9_x2) : (s2_pc + or_imm9_x2);
    assign or_jlr_tgt = or_rd1_eff;
    assign or_sub_result = or_rd2_eff - or_rd1_eff;
    assign or_blt_neg = or_sub_result[15];
    assign or_sub_reduce = |or_sub_result;
    assign or_ble_cond = or_sub_result[15] | (~or_sub_reduce);
    assign or_branch_taken = ((s2_op[1:0] == 2'b00) && (or_sub_result == 16'h0000)) ? 1'b1 : ((s2_op[1:0] == 2'b01) && or_blt_neg) ? 1'b1 : ((s2_op[1:0] == 2'b10) && or_ble_cond) ? 1'b1 : 1'b0;
    assign or_pc_sel = ((s2_pc_src == 2'b01) && (or_branch_taken == 1'b0)) ? 2'b00 : s2_pc_src;
    assign s3_in_rd1 = ls_stall_fetch ? ls_addr : or_rd1_eff;
    assign s3_in_imm_ext = ls_stall_fetch ? ls_imm_val : or_imm_ext;
    assign s3_in_write_reg = ls_stall_fetch ? ls_rs1 : s2_rb;
    assign s3_in_reg_write = ls_stall_fetch ? ls_is_load : s2_reg_write;
    assign s3_in_mem_write = ls_stall_fetch ? {(~ls_is_load), (~ls_is_load)} : s2_mem_write;
    assign s3_in_alu_src = ls_stall_fetch ? 1'b1 : s2_alu_src;
    assign s3_in_res_src = (ls_stall_fetch && ls_is_load) ? 2'b01 : ls_stall_fetch ? 2'b00 : s2_res_src;
    assign s3_in_imm_src = ls_stall_fetch ? 2'b00 : s2_imm_src;
    assign s3_in_rc = ls_stall_fetch ? 3'b000 : s2_rc;
    assign s3_in_ra = ls_stall_fetch ? ls_rs1 : s2_ra;
    assign s3_stall = 1'b0;
    assign s3_flush = flush_s3 | ls_flush_s3 | (ls_stall_fetch & ~ls_valid) | wb_r0_wr;
    pl_s3 S3(
        .clk(clk),
        .reset(reset),
        .stall(s3_stall),
        .flush(s3_flush),
        .pc_r(s2_pc),
        .pc_plus2_r(s2_pc_plus2),
        .reg_write_r(s3_in_reg_write),
        .mem_write_r(s3_in_mem_write),
        .alu_src_r(s3_in_alu_src),
        .alu_ctrl_r(s2_alu_ctrl),
        .imm_src_r(s3_in_imm_src),
        .res_src_r(s3_in_res_src),
        .rd1_r(s3_in_rd1),
        .rd2_r(s3_in_rd2),
        .imm_ext_r(s3_in_imm_ext),
        .rc_r(s3_in_rc),
        .ra_r(s3_in_ra),
        .write_reg_r(s3_in_write_reg),
        .flags_r({c_flag_reg, z_flag_reg}),
        .flags_op_r(s3_in_flags_op),
        .pc_e(s3_pc),
        .pc_plus2_e(s3_pc_plus2),
        .reg_write_e(s3_reg_write),
        .mem_write_e(s3_mem_write),
        .alu_src_e(s3_alu_src),
        .alu_ctrl_e(s3_alu_ctrl),
        .imm_src_e(s3_imm_src),
        .res_src_e(s3_res_src),
        .rd1_e(s3_rd1),
        .rd2_e(s3_rd2),
        .imm_ext_e(s3_imm_ext),
        .rc_e(s3_rc),
        .ra_e(s3_ra),
        .write_reg_e(s3_write_reg),
        .flags_e(s3_flags),
        .flags_op_e(s3_flags_op)
    );

    // EX stage
    assign ex_alu_a = (fwd_a == 2'b10) ? s4_alu_result : (fwd_a == 2'b01) ? wb_write_data : s3_rd1;
    assign ex_alu_b_reg = (fwd_b == 2'b10) ? s4_alu_result : (fwd_b == 2'b01) ? wb_write_data : s3_rd2;
    assign ex_alu_b = s3_alu_src ? s3_imm_ext : s3_imm_src[1] ? ~ex_alu_b_reg : ex_alu_b_reg;
    alu ALU_INST(
        .A(ex_alu_a),
        .B(ex_alu_b),
        .ALU_Sel(s3_alu_ctrl),
        .Carry_in(s3_flags[1]),
        .Result(ex_alu_result),
        .Carry_out(ex_carry_out),
        .Zero(ex_zero)
    );
    assign s4_stall = 1'b0;
    assign s4_flush = wb_r0_wr;
    pl_s4 S4(
        .clk(clk),
        .reset(reset),
        .stall(s4_stall),
        .flush(s4_flush),
        .pc_e(s3_pc),
        .pc_plus2_e(s3_pc_plus2),
        .reg_write_e(s3_reg_write),
        .mem_write_e(s3_mem_write),
        .res_src_e(s3_res_src),
        .alu_result_e(ex_alu_result),
        .store_data_e(ex_alu_b_reg),
        .write_reg_e(s3_write_reg),
        .flags_e({ex_carry_out, ex_zero}),
        .flags_op_e(s3_flags_op),
        .pc_m(s4_pc),
        .pc_plus2_m(s4_pc_plus2),
        .reg_write_m(s4_reg_write),
        .mem_write_m(s4_mem_write),
        .res_src_m(s4_res_src),
        .alu_result_m(s4_alu_result),
        .store_data_m(s4_store_data),
        .write_reg_m(s4_write_reg),
        .flags_m(s4_flags),
        .flags_op_m(s4_flags_op)
    );

    // MEM stage
    dmem DMEM(
        .clk(clk),
        .we(s4_mem_write),
        .addr(s4_alu_result),
        .wr_data(s4_store_data),
        .rd_data(mem_rd_data)
    );
    assign s5_stall = 1'b0;
    assign s5_flush = 1'b0;
    pl_s5 S5(
        .clk(clk),
        .reset(reset),
        .stall(s5_stall),
        .flush(s5_flush),
        .pc_m(s4_pc),
        .pc_plus2_m(s4_pc_plus2),
        .reg_write_m(s4_reg_write),
        .mem_write_m(s4_mem_write),
        .res_src_m(s4_res_src),
        .alu_result_m(s4_alu_result),
        .store_data_m(s4_store_data),
        .rd_data_m(mem_rd_data),
        .write_reg_m(s4_write_reg),
        .flags_m(s4_flags),
        .flags_op_m(s4_flags_op),
        .pc_w(s5_pc),
        .pc_plus2_w(s5_pc_plus2),
        .reg_write_w(s5_reg_write),
        .mem_write_w(s5_mem_write),
        .res_src_w(s5_res_src),
        .alu_result_w(s5_alu_result),
        .store_data_w(s5_store_data),
        .rd_data_w(s5_rd_data),
        .write_reg_w(s5_write_reg),
        .flags_w(s5_flags),
        .flags_op_w(s5_flags_op)
    );

    // WB stage
    assign wb_write_data = (s5_res_src == 2'b00) ? s5_alu_result : (s5_res_src == 2'b01) ? s5_rd_data : s5_pc_plus2;
    always @(posedge clk) begin
        if(reset) begin
            c_flag_reg <= 1'b0;
            z_flag_reg <= 1'b0;
        end else if(s5_flags_op && s5_res_src == 2'b01) begin
            c_flag_reg <= s5_rd_data[1];
            z_flag_reg <= s5_rd_data[0];
        end else if(s5_reg_write) begin
            c_flag_reg <= s5_flags[1];
            z_flag_reg <= s5_flags[0];
        end
    end

    // Hazard Unit
    assign hu_rc_or = ls_stall_fetch ? 3'b000 : s2_rc;
    assign hu_ra_or = ls_stall_fetch ? 3'b000 : s2_ra;
    assign hu_rb_or = ls_stall_fetch ? 3'b000 : s2_rb;
    hazard_unit HU(
        .rb_or(hu_rb_or),
        .rc_or(hu_rc_or),
        .ra_or(hu_ra_or),
        .rc_ex(s3_rc),
        .ra_ex(s3_ra),
        .write_reg_ex(s3_write_reg),
        .regwrite_ex(s3_reg_write),
        .res_src_ex(s3_res_src),
        .write_reg_mem(s4_write_reg),
        .regwrite_mem(s4_reg_write),
        .write_reg_wb(s5_write_reg),
        .regwrite_wb(s5_reg_write),
        .pc_sel_or(or_pc_sel),
        .fwd_a(fwd_a),
        .fwd_b(fwd_b),
        .stall_if(stall_if),
        .stall_id(stall_id),
        .stall_or(stall_or),
        .flush_s1(flush_s1),
        .flush_s2(flush_s2),
        .flush_s3(flush_s3)
    );

    assign PC_out = s5_pc;
    assign Result_out = wb_write_data;
    assign WriteData = s5_store_data;
    assign DataAdr = s5_alu_result;
    assign ReadData = s5_rd_data;
    assign MemWrite_out = s5_mem_write;
endmodule