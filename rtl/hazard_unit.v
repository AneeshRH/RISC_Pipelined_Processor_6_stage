//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.07.2026 21:45:05
// Design Name: 
// Module Name: hazard_unit
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
module hazard_unit (
    input[2:0] rb_or,
    input[2:0] rc_or,
    input[2:0] ra_or,
    input[2:0] rc_ex,
    input[2:0] ra_ex,
    input[2:0] write_reg_ex,
    input regwrite_ex,
    input[1:0] res_src_ex,
    input[2:0] write_reg_mem,
    input regwrite_mem,
    input[2:0] write_reg_wb,
    input regwrite_wb,
    input[1:0] pc_sel_or,
    output[1:0] fwd_a,
    output[1:0] fwd_b,
    output stall_if,
    output stall_id,
    output stall_or,
    output flush_s1,
    output flush_s2,
    output flush_s3
);
    wire load_use=(res_src_ex==2'b01 && regwrite_ex && write_reg_ex!=3'b000 &&
                   (rc_or==write_reg_ex || ra_or==write_reg_ex || rb_or==write_reg_ex));
    wire control_hazard=(pc_sel_or!=2'b00);

    assign stall_if=load_use;
    assign stall_id=load_use;
    assign stall_or=load_use;
    assign flush_s3=load_use;
    assign flush_s1=control_hazard && ~load_use;
    assign flush_s2=control_hazard && ~load_use;

    assign fwd_a=
        (regwrite_mem && write_reg_mem!=3'b000 && write_reg_mem==rc_ex)?2'b10:
        (regwrite_wb && write_reg_wb!=3'b000 && write_reg_wb==rc_ex)?2'b01:2'b00;

    assign fwd_b=
        (regwrite_mem && write_reg_mem!=3'b000 && write_reg_mem==ra_ex)?2'b10:
        (regwrite_wb && write_reg_wb!=3'b000 && write_reg_wb==ra_ex)?2'b01:2'b00;
endmodule