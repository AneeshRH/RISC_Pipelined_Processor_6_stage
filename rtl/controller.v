//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.06.2026 14:25:40
// Design Name: 
// Module Name: controller
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
module controller (
    input[3:0] Op,
    input Complement,
    input[2:0] Cond,
    input[1:0] ALUFlags,
    output reg RegWrite,
    output reg[1:0] MemWrite,
    output reg ALUSrc,
    output reg[2:0] ALUControl,
    output reg ImmSrc,
    output reg[1:0] ResultSrc,
    output reg[1:0] PCSrc
);
    wire C_flag=ALUFlags[1];
    wire Z_flag=ALUFlags[0];

    always @(*) begin
        RegWrite=1'b0;
        MemWrite=2'b00;
        ALUSrc=1'b0;
        ALUControl=3'b000;
        ImmSrc=1'b0;
        ResultSrc=2'b00;
        PCSrc=2'b00;

        case (Op[3:2])
            2'b00: begin
                case (Op[1:0])
                    2'b11: begin
                        RegWrite=1'b1; ALUSrc=1'b1;
                        ALUControl=3'b011;
                        ImmSrc=1'b1;
                    end
                    2'b00: begin
                        RegWrite=1'b1; ALUSrc=1'b1;
                        ALUControl=3'b000;
                        ImmSrc=1'b0;
                    end
                    2'b01: begin
                        if(Cond[1:0]==2'b00) begin RegWrite=1'b1; ALUControl=3'b000; end
                        else if(Cond[1:0]==2'b10) begin RegWrite=C_flag; ALUControl=3'b000; end
                        else if(Cond[1:0]==2'b01) begin RegWrite=Z_flag; ALUControl=3'b000; end
                        else if(Cond[1:0]==2'b11) begin RegWrite=1'b1; ALUControl=3'b001; end
                    end
                    2'b10: begin
                        ALUControl=3'b010;
                        if(Cond[1:0]==2'b00) RegWrite=1'b1;
                        else if(Cond[1:0]==2'b10) RegWrite=C_flag;
                        else if(Cond[1:0]==2'b01) RegWrite=Z_flag;
                    end
                    default:;
                endcase
            end
            2'b01: begin
                ALUSrc=1'b1; ImmSrc=1'b0;
                case (Op[1:0])
                    2'b00: begin RegWrite=1'b1; ResultSrc=2'b01; end
                    2'b01: MemWrite=2'b11;
                    default:;
                endcase
            end
            2'b10: begin
                ImmSrc=1'b0; PCSrc=2'b01;
            end
            2'b11: begin
                ResultSrc=2'b10; ImmSrc=1'b1;
                case (Op[1:0])
                    2'b00: begin RegWrite=1'b1; PCSrc=2'b11; end
                    2'b01: begin RegWrite=1'b1; PCSrc=2'b10; end
                    2'b11: begin RegWrite=1'b0; PCSrc=2'b11; end
                    default:;
                endcase
            end
            default:;
        endcase
    end
endmodule