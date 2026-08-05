hex_code=open('bin/rv16_test.hex').read().splitlines()
rf=[0]*8; dmem=[0]*256; PC=0
def se(v,b): s=1<<(b-1); return (v&(s-1))-(v&s)
def to16(v): return v&0xFFFF
def s16(v): v&=0xFFFF; return v if v<0x8000 else v-0x10000
def wreg(r,v):
    if r: rf[r]=to16(v)
def dec(h):
    b=bin(int(h,16))[2:].zfill(16); return b,b[0:4],int(b[4:7],2),int(b[7:10],2),int(b[10:13],2)
ct={"0000":"ADI","0011":"LLI","0100":"LW","0101":"SW","1000":"BEQ","1001":"BLT","1010":"BLE","0001":"ADD"}
while True:
    instr=hex_code[PC//2]
    if instr=="0000": break
    rf[0]=PC; b,op,rs1,rs2,rd=dec(instr); imm6=se(int(b[10:16],2),6); c=ct.get(op,"NOP"); nPC=PC+2
    if c=="LLI": wreg(rs1, se(int(b[7:16],2),9))
    elif c=="ADI": wreg(rs1, rf[rs2]+imm6)
    elif c=="ADD":
        comp=(int(b[13:16],2)>>2)&1; ob=to16(~rf[rd]) if comp else rf[rd]; wreg(rs1, rf[rs2]+ob)
    elif c=="LW": wreg(rs1, dmem[(rf[rs2]+imm6)//2 & 0xFF])
    elif c=="SW": dmem[(rf[rs2]+imm6)//2 & 0xFF]=rf[rs1]
    elif c=="BLT":
        if s16(rf[rs1])<s16(rf[rs2]): nPC=PC+imm6*2
    elif c=="BLE":
        if s16(rf[rs1])<=s16(rf[rs2]): nPC=PC+imm6*2
    elif c=="BEQ":
        if s16(rf[rs1])==s16(rf[rs2]): nPC=PC+imm6*2
    PC=nPC; rf[0]=PC
halt_pc=PC
open('expected.hex','w').write(f"{halt_pc:04X}\n"+'\n'.join(f"{rf[i]:04X}" for i in range(1,8))+'\n')
print(f"halt_pc=0x{halt_pc:04X}  r1..r7={[s16(rf[i]) for i in range(1,8)]}")
