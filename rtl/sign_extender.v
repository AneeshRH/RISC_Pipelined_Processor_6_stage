// Sign extender. sel=0 -> sign-extend imm6, sel=1 -> sign-extend imm9, to 16 bits.
module sign_extender (
    input  [5:0]  imm6,
    input  [8:0]  imm9,
    input         sel,
    output [15:0] out16
);
    assign out16 = (sel == 1'b0) ? {{10{imm6[5]}}, imm6}
                                 : {{7{imm9[8]}},  imm9};
endmodule