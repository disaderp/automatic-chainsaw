# automatic-chainsaw Simulator

*maintainer: [@disaderp](https://github.com/disaderp) / [@winek](https://github.com/winek) (Linux launcher)*

Simulator for automatic-chainsaw computer.

## features

Depending on the input filetype, it will:

- Compile(if .c)
- Assemble
- Update .v code to contain your code on startup
- Compile .v
- Run the simulator 
- **[UPDATE]** Show result using `gtkwave`

## setting up

Open `automatic_chainsaw_simulator.bat` and edit paths if you are using custom directories.
If you have default paths from repository, you do not have to modify anything.

Download Icarus Verilog(versions below 0.10 DO NOT work), 
- Windows binaries are avaliable [here](http://bleyer.org/icarus/).
- On Debian/Ubuntu, use `sudo apt install verilog`, on Arch Linux use `pacman -S iverilog`.

Download GTKWave. 
- Windows binaries [here](https://sourceforge.net/projects/gtkwave/files/)
- Linux `@TODO: winek`

## usage

- Windows: open `cmd.exe` and type: `automatic_chainsaw_simulator FILE`
- Linux: `bash automatic_chainsaw_simulator.sh FILE`

## requirements && outputting

```asm

'to print to console use OUT at port other than 000xxxxxxxxxxxxx
MOV BX,(1110000000000000)
MOV DX,(01000001)
OUT
