#!/usr/bin/env python3
"""
mycc: compiler for a subset of C -> IITB-RISC-26 machine code.
Variables in registers r1..r5 (r0=PC); expression temps in remaining registers.
Supported: int vars; + - * / % (with parentheses); if/else, while, for;
comparisons < <= == > >= !=.
* / % are compiled to loops (the ISA has no multiply/divide) and assume
NON-NEGATIVE operands. Division/modulo by zero loops forever (like UB).
Limits: variables + expression temps must fit in r1..r7; * needs 4 temps,
/ needs 3, % needs 2, so heavy use of * lowers the variable budget.
"""
import re, sys

TOK = re.compile(r'\s*(?:(\d+)|([A-Za-z_]\w*)|(<=|>=|==|!=|[<>])|(.))')
KEYWORDS = {'int','if','else','while','for'}
def tokenize(s):
    out=[]
    for m in TOK.finditer(s):
        num,ident,cmp,ch=m.groups()
        if num is not None: out.append(('NUM',int(num)))
        elif ident is not None: out.append(('KW',ident) if ident in KEYWORDS else ('ID',ident))
        elif cmp is not None: out.append(('CMP',cmp))
        elif ch is not None and not ch.isspace(): out.append((ch,ch))
    out.append(('EOF',None)); return out

class P:
    def __init__(s,t): s.t=t; s.i=0
    def peek(s): return s.t[s.i]
    def nxt(s): s.i+=1; return s.t[s.i-1]
    def eat(s,k,v=None):
        tk=s.nxt()
        if tk[0]!=k or (v is not None and tk[1]!=v): raise SyntaxError(f"expected {k} {v}, got {tk}")
        return tk
    def program(s):
        st=[]
        while s.peek()[0]!='EOF': st.append(s.stmt())
        return ('block',st)
    def block(s):
        s.eat('{'); st=[]
        while s.peek()[0]!='}': st.append(s.stmt())
        s.eat('}'); return ('block',st)
    def stmt(s):
        k=s.peek()
        if k==('KW','int'):
            s.nxt(); name=s.eat('ID')[1]; init=None
            if s.peek()[0]=='=': s.nxt(); init=s.expr()
            s.eat(';'); return ('decl',name,init)
        if k==('KW','if'):
            s.nxt(); s.eat('('); c=s.cond(); s.eat(')'); th=s.stmt(); el=None
            if s.peek()==('KW','else'): s.nxt(); el=s.stmt()
            return ('if',c,th,el)
        if k==('KW','while'):
            s.nxt(); s.eat('('); c=s.cond(); s.eat(')'); return ('while',c,s.stmt())
        if k==('KW','for'):
            s.nxt(); s.eat('('); init=s.simple(); s.eat(';'); c=s.cond(); s.eat(';')
            upd=s.assign(); s.eat(')'); return ('for',init,c,upd,s.stmt())
        if k[0]=='{': return s.block()
        st=s.simple(); s.eat(';'); return st
    def simple(s):
        if s.peek()==('KW','int'):
            s.nxt(); name=s.eat('ID')[1]; init=None
            if s.peek()[0]=='=': s.nxt(); init=s.expr()
            return ('decl',name,init)
        return s.assign()
    def assign(s):
        name=s.eat('ID')[1]; s.eat('='); return ('assign',name,s.expr())
    def cond(s):
        a=s.expr(); op=s.eat('CMP')[1]; b=s.expr(); return ('cmp',op,a,b)
    def expr(s):                       # + and - (lowest precedence)
        n=s.mul()
        while s.peek()[0] in ('+','-'):
            op=s.nxt()[0]; n=(op,n,s.mul())
        return n
    def mul(s):                        # * / % (higher precedence)
        n=s.factor()
        while s.peek()[0] in ('*','/','%'):
            op=s.nxt()[0]; n=(op,n,s.factor())
        return n
    def factor(s):
        tk=s.nxt()
        if tk[0]=='NUM': return ('num',tk[1])
        if tk[0]=='ID': return ('var',tk[1])
        if tk[0]=='(':
            e=s.expr(); s.eat(')'); return e
        raise SyntaxError(f"bad factor {tk}")

def collect_vars(node, order):
    if node[0]=='decl':
        if node[1] not in order: order.append(node[1])
    elif node[0]=='block':
        for c in node[1]: collect_vars(c, order)
    elif node[0]=='if':
        collect_vars(node[2],order)
        if node[3]: collect_vars(node[3],order)
    elif node[0]=='while': collect_vars(node[2],order)
    elif node[0]=='for':
        collect_vars(node[1],order); collect_vars(node[4],order)

class Gen:
    def __init__(s, varorder):
        s.code=[]; s.lbl=0
        if len(varorder)>5: raise ValueError("too many variables (max 5)")
        s.vreg={v:i+1 for i,v in enumerate(varorder)}
        s.sbase=len(varorder)+1
    def scr(s,d):
        r=s.sbase+d
        if r>7: raise ValueError("expression too complex / too many variables (out of registers)")
        return r
    def L(s,p='L'): s.lbl+=1; return f"{p}{s.lbl}"
    def emit(s,*i): s.code.append(i)
    def gen(s,n):
        t=n[0]
        if t=='block':
            for c in n[1]: s.gen(c)
        elif t=='decl':
            if n[2] is not None: s.assign(n[1],n[2])
        elif t=='assign': s.assign(n[1],n[2])
        elif t=='if':
            _,c,th,el=n; Lt,Le=s.L(),s.L()
            s.btrue(c,Lt)
            if el: s.gen(el)
            s.emit('jmp',Le); s.emit('label',Lt); s.gen(th); s.emit('label',Le)
        elif t=='while':
            _,c,body=n; Lc,Lb,Le=s.L(),s.L(),s.L()
            s.emit('label',Lc); s.btrue(c,Lb); s.emit('jmp',Le)
            s.emit('label',Lb); s.gen(body); s.emit('jmp',Lc); s.emit('label',Le)
        elif t=='for':
            _,init,c,upd,body=n; s.gen(init)
            Lc,Lb,Le=s.L(),s.L(),s.L()
            s.emit('label',Lc); s.btrue(c,Lb); s.emit('jmp',Le)
            s.emit('label',Lb); s.gen(body); s.gen(upd); s.emit('jmp',Lc); s.emit('label',Le)
        else: raise ValueError(n)
    def assign(s,name,e):
        s.eval(e,0); s.emit('adi', s.vreg[name], s.scr(0), 0)
    def eval(s,e,d):
        R=s.scr(d); t=e[0]
        if t=='num':
            if not (-256<=e[1]<=255): raise ValueError(f"literal {e[1]} out of range")
            s.emit('lli',R,e[1])
        elif t=='var':
            s.emit('adi',R, s.vreg[e[1]], 0)
        elif t=='+':
            s.eval(e[1],d); s.eval(e[2],d+1); s.emit('ada',R,R,s.scr(d+1))
        elif t=='-':
            s.eval(e[1],d); s.eval(e[2],d+1); s.emit('aca',R,R,s.scr(d+1)); s.emit('adi',R,R,1)
        elif t=='*':
            # R = a * b  (a,b >= 0), via: res=0; for i in 0..b-1: res+=a
            s.eval(e[1],d); s.eval(e[2],d+1)
            A,LIM,RES,I=s.scr(d),s.scr(d+1),s.scr(d+2),s.scr(d+3)
            Lc,Lb,Le=s.L(),s.L(),s.L()
            s.emit('lli',RES,0); s.emit('lli',I,0)
            s.emit('label',Lc); s.emit('blt',I,LIM,Lb); s.emit('jmp',Le)
            s.emit('label',Lb); s.emit('ada',RES,RES,A); s.emit('adi',I,I,1); s.emit('jmp',Lc)
            s.emit('label',Le); s.emit('adi',R,RES,0)
        elif t=='/':
            # R = a / b  (a>=0, b>0), via repeated subtraction, result = count
            s.eval(e[1],d); s.eval(e[2],d+1)
            REM,B,Q=s.scr(d),s.scr(d+1),s.scr(d+2)
            Lc,Lb,Le=s.L(),s.L(),s.L()
            s.emit('lli',Q,0)
            s.emit('label',Lc); s.emit('ble',B,REM,Lb); s.emit('jmp',Le)
            s.emit('label',Lb); s.emit('aca',REM,REM,B); s.emit('adi',REM,REM,1)
            s.emit('adi',Q,Q,1); s.emit('jmp',Lc)
            s.emit('label',Le); s.emit('adi',R,Q,0)
        elif t=='%':
            # R = a % b  (a>=0, b>0), via repeated subtraction, result = remainder
            s.eval(e[1],d); s.eval(e[2],d+1)
            REM,B=s.scr(d),s.scr(d+1)
            Lc,Lb,Le=s.L(),s.L(),s.L()
            s.emit('label',Lc); s.emit('ble',B,REM,Lb); s.emit('jmp',Le)
            s.emit('label',Lb); s.emit('aca',REM,REM,B); s.emit('adi',REM,REM,1); s.emit('jmp',Lc)
            s.emit('label',Le)   # remainder already in R=scr(d)
        else: raise ValueError(e)
    def btrue(s,cond,label):
        _,op,a,b=cond; s.eval(a,0); s.eval(b,1)
        r1,r2=s.scr(0),s.scr(1)
        if   op=='<':  s.emit('blt',r1,r2,label)
        elif op=='<=': s.emit('ble',r1,r2,label)
        elif op=='==': s.emit('beq',r1,r2,label)
        elif op=='>':  s.emit('blt',r2,r1,label)
        elif op=='>=': s.emit('ble',r2,r1,label)
        elif op=='!=':
            Ls=s.L(); s.emit('beq',r1,r2,Ls); s.emit('jmp',label); s.emit('label',Ls)
        else: raise ValueError(op)

def assemble(code):
    addr=0; labels={}; flat=[]
    for i in code:
        if i[0]=='label': labels[i[1]]=addr
        else: flat.append((addr,i)); addr+=2
    flat.append((addr,('nop',))); halt=addr
    return [encode(i,pc,labels) for pc,i in flat], halt
def rel6(t,pc):
    o=(t-pc)//2
    if not(-32<=o<=31): raise ValueError(f"branch out of range {o}")
    return o & 0x3F
def encode(i,pc,labels):
    op=i[0]
    if op=='nop': return 0
    if op=='lli': return (0b0011<<12)|(i[1]<<9)|(i[2]&0x1FF)
    if op=='adi': return (0b0000<<12)|(i[1]<<9)|(i[2]<<6)|(i[3]&0x3F)
    if op=='ada': return (0b0001<<12)|(i[1]<<9)|(i[2]<<6)|(i[3]<<3)
    if op=='aca': return (0b0001<<12)|(i[1]<<9)|(i[2]<<6)|(i[3]<<3)|(1<<2)
    if op in ('beq','blt','ble'):
        c={'beq':0b1000,'blt':0b1001,'ble':0b1010}[op]
        return (c<<12)|(i[1]<<9)|(i[2]<<6)|rel6(labels[i[3]],pc)
    if op=='jmp': return (0b1000<<12)|rel6(labels[i[1]],pc)
    raise ValueError(i)

def compile_c(src):
    ast=P(tokenize(src)).program()
    order=[]; collect_vars(ast,order)
    g=Gen(order); g.gen(ast)
    words,halt=assemble(g.code)
    return words, g.vreg, halt, g.code

if __name__=='__main__':
    words,vreg,halt,_=compile_c(sys.stdin.read())
    import os; os.makedirs('bin',exist_ok=True)
    open('bin/rv16_test.hex','w').write('\n'.join(f"{w&0xFFFF:04X}" for w in words)+'\n')
    print(f"# {len(words)} words, halt=0x{halt:02X}, vars="+", ".join(f"{n}=r{r}" for n,r in vreg.items()))