//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2026 10:15:35
// Design Name: 
// Module Name: ls_ucode
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

module ls_ucode (
    input clk,
    input reset,
    input enable,
    input stall,
    input flush,
    input[2:0] rs1_addr,
    input[15:0] rs1_addr_val,
    input[8:0] imm9,
    output[2:0] alu_ctrl,
    output[2:0] rs1,
    output[15:0] addr,
    output[15:0] imm_val,
    output stall_fetch,
    output valid,
    output done,
    output flags_op
);
    localparam IDLE=1'b0, UCODE=1'b1;

    reg state=IDLE;
    reg[7:0] mask;
    reg[15:0] offset;
    reg[15:0] addr_r;
    reg[2:0] alu_ctrl_r;
    reg stall_fetch_r;
    reg done_r;
    reg save_flags=1'b0;

    reg[2:0] next_reg;
    reg valid_bit;

    assign valid=(state==UCODE)?(valid_bit|save_flags):1'b0;
    assign flags_op=(state==UCODE)?save_flags:1'b0;
    assign rs1=(state==UCODE)?next_reg:3'b000;
    assign imm_val=(state==UCODE)?offset:16'h0000;
    assign addr=addr_r;
    assign alu_ctrl=alu_ctrl_r;
    assign stall_fetch=stall_fetch_r;
    assign done=done_r;

    always @(*) begin
        valid_bit=1'b1;
        if(mask[0]) next_reg=3'b111;
        else if(mask[1]) next_reg=3'b110;
        else if(mask[2]) next_reg=3'b101;
        else if(mask[3]) next_reg=3'b100;
        else if(mask[4]) next_reg=3'b011;
        else if(mask[5]) next_reg=3'b010;
        else if(mask[6]) next_reg=3'b001;
        else begin
            valid_bit=1'b0;
            next_reg=3'b000;
        end
    end

    always @(posedge clk) begin
        done_r<=1'b0;
        if(reset || flush || ~enable) begin
            state<=IDLE;
            stall_fetch_r<=1'b0;
            save_flags<=1'b0;
            addr_r<=16'h0000;
            mask<=8'h00;
            alu_ctrl_r<=3'b000;
            offset<=16'h0000;
        end else if(enable && ~stall) begin
            alu_ctrl_r<=3'b000;
            case(state)
                IDLE: begin
                    stall_fetch_r<=1'b1;
                    state<=UCODE;
                    mask<=imm9[7:0];
                    save_flags<=imm9[8];
                    addr_r<=rs1_addr_val;
                    offset<=16'h0000;
                end
                UCODE: begin
                    if(save_flags) begin
                        offset<=offset+16'd2;
                        save_flags<=1'b0;
                    end else if(valid_bit) begin
                        offset<=offset+16'd2;
                        case(next_reg)
                            3'b111: mask[0]<=1'b0;
                            3'b110: mask[1]<=1'b0;
                            3'b101: mask[2]<=1'b0;
                            3'b100: mask[3]<=1'b0;
                            3'b011: mask[4]<=1'b0;
                            3'b010: mask[5]<=1'b0;
                            3'b001: mask[6]<=1'b0;
                            default:;
                        endcase
                    end else begin
                        stall_fetch_r<=1'b0;
                        state<=IDLE;
                        done_r<=1'b1;
                    end
                end
            endcase
        end
    end
endmodule