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

'init 512*4 loop
MOV 