{ kind: 'AssignmentStatement',
  leftHandSide: { kind: 'Identifier', toString: [Function: toString] },
  rightHandSide:
   { kind: 'BinaryOperator',
     leftOperand: { kind: 'Identifier', toString: [Function: toString] },
     operator: '+',
     rightOperand:
      { kind: 'Integer', toString: [Function: toString], value: 1 } } }
ERROR: TYPE: Error: todo todo todo
    at Object.AssignmentStatement (/home/o/workspace/automatic-chainsaw/COMPILER/compile.js:89:15)
    at statements.forEach (/home/o/workspace/automatic-chainsaw/COMPILER/compile.js:333:24)
    at Array.forEach (<anonymous>)
    at visit (/home/o/workspace/automatic-chainsaw/COMPILER/compile.js:328:14)
    at compile (/home/o/workspace/automatic-chainsaw/COMPILER/compile.js:14:3)
    at Object.<anonymous> (/home/o/workspace/automatic-chainsaw/COMPILER/cli.js:77:13)
    at Module._compile (internal/modules/cjs/loader.js:702:30)
    at Object.Module._extensions..js (internal/modules/cjs/loader.js:713:10)
    at Module.load (internal/modules/cjs/loader.js:612:32)
    at tryModuleLoad (internal/modules/cjs/loader.js:551:12) CODE: undefinedEND ERROR 

{ kind: 'AssignmentStatement',
  leftHandSide: { kind: 'Identifier', toString: [Function: toString] },
  rightHandSide:
   { kind: 'UnaryOperator',
     operand: { kind: 'Identifier', toString: [Function: toString] },
     operator: '!' } }
ERROR: TYPE: Error: todo todo todo
    at Object.AssignmentStatement (/home/o/workspace/automatic-chainsaw/COMPILER/compile.js:89:15)
    at statements.forEach (/home/o/workspace/automatic-chainsaw/COMPILER/compile.js:333:24)
    at Array.forEach (<anonymous>)
    at visit (/home/o/workspace/automatic-chainsaw/COMPILER/compile.js:328:14)
    at compile (/home/o/workspace/automatic-chainsaw/COMPILER/compile.js:14:3)
    at Object.<anonymous> (/home/o/workspace/automatic-chainsaw/COMPILER/cli.js:77:13)
    at Module._compile (internal/modules/cjs/loader.js:702:30)
    at Object.Module._extensions..js (internal/modules/cjs/loader.js:713:10)
    at Module.load (internal/modules/cjs/loader.js:612:32)
    at tryModuleLoad (internal/modules/cjs/loader.js:551:12) CODE: undefinedEND ERROR 

LEA DX,.n
PUSH DX
MOV DX,(1)
POP AX
ADD AX,DX
LEA AX,.n
MOV .pi,AX
MOV .esc,(5)
MOV .[object Object],(3)
.funcwrite
MOV .buf,AX
LEA AX,.x
POP DX
JMP DX
.funcf
POP DX
MOV .s,DX
POP DX
MOV .flags,DX
.whilewtvfs
LEA DX,.s
PUSH DX
MOV DX,(1)
POP AX
SUB AX,DX
MOV CX,(0)
TEST AX,CX
JZ .endwhilewtvfs
CPC 
PUSH DX
LEA DX,.s
PUSH DX
JMP .funcprintn
JMP .whilewtvfs
.endwhilewtvfs
LEA AX,.s
MOV CX,(0)
TEST AX,CX
JZ .elseifbxtfn
CPC 
PUSH DX
LEA DX,.s
PUSH DX
JMP .funcprint
JMP .endifbxtfn
.elseifbxtfn
X11000001
X01100110
X11000001
X01100001
X11000001
X01110100
X11000001
X01100001
X11000001
X01101100
X11000001
X0
.endifbxtfn
MOV AX,(0)
POP DX
JMP DX
CPC 
PUSH DX
MOV DX,(1)
PUSH DX
LEA DX,.a
PUSH DX
JMP .funcf
LEA AX,.a
NOT AX
CPC 
PUSH DX
JMP .funcwrite
.pi
X100111010
.esc
X11011
.hello
X01001000
X01100101
X01101100
X01101100
X01101111
X00100000
X01010111
X01101111
X01110010
X01101100
X01100100
.T
X00000000
X00000000
X00000000
X00000000
X00000000
X00000000
X00000000
X00000000
X00000000
X00000000
.buf
X00000000
