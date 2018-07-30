'simulation must start with NOP
NOP

'there are two ways of communicating with console


'1: by OUT at port other than 000xxxxxxxxxxxxx
MOV BX,(1110000000000000)
MOV DX,(01000001)
OUT

'2: by gpu memory print function
MOV DX,(01001000)
MOV [10],DX
X10111111
X10
MOV DX,(01000101)
MOV [10],DX
X10111111
X10
MOV DX,(01001100)
MOV [10],DX
X10111111
X10
MOV DX,(01001100)
MOV [10],DX
X10111111
X10
MOV DX,(01001111)
MOV [10],DX
X10111111
X10

'simulation must end with inf loop
.inf
JMP [.inf]