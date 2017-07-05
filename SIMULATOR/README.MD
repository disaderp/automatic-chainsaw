# automatic-chainsaw Simulator

*maintainer: [@disaderp](https://github.com/disaderp) / [@winek](https://github.com/winek) (Linux launcher)*

Simulator for automatic-chainsaw computer.

## features

Depending on the input filetype, it will:

- Compile(if .c)
- Assemble
- Update CPU.v code to contain your code on startup
- Compile .v
- Run the simulator 
- **[UPDATE]** view result using `gtkwave`

## setting up

Open `automatic_chainsaw_simulator.bat` and edit paths if you are using custom directories.
If you have default paths from repository, you do not have to modify anything.

Download Icarus Verilog(versions below 0.10 DO NOT work), Windows binaries are avaliable [here](http://bleyer.org/icarus/). Make sure to use version above 0.9. On Debian/Ubuntu, use `sudo apt install verilog`, on Arch Linux use `pacman -S iverilog`.
Download GTKWave. Windows binaries [here](https://sourceforge.net/projects/gtkwave/files/)

## usage

- Windows: open `cmd.exe` and type: `automatic_chainsaw_simulator FILE`
- Linux: `bash automatic_chainsaw_simulator.sh FILE`

## requirements && outputting

```asm
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
JMP .inf
```
