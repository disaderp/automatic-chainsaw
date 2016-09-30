'bootloader code by disa
NOP
'init textmode
X11000000
X0
'put text: loading
X11000001
X01101100

X11000001
X01101111

X11000001
X01100001

X11000001
X01100100

X11000001
X01101001

X11000001
X01101110

X11000001
X01100111

'wait until sdcard load is complete
.wait
JNZ .wait

'OSbootsector in first 100
'CX start sector of OS
'DX data from sdcard
'AX tmp address
MOV CX,(1100100)
MOV BX,(0)
MOV AX,(1)
.loadall
IN
LEA <CX>,DX
ADD CX,AX
ADD BX,AX
'TEST if 100
MOV DX,(1100100)
TEST BX,DX
JNZ .loadall

'loaded
JMP <1100100>