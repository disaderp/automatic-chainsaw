#!/bin/bash
set -ev

if [ "${BUILD}" = "COM" ]; then
	node ./COMPILER/cli.js ./COMPILER/define.cmm
elif [ "${BUILD}" = "CPU" ]; then
	iverilog -Wall -g2012 -s CPU -o compiled.vvp ./CPU/ALU.v ./CPU/debugging/RAM_sim.v ./CPU/CPU.v ./GPU/Font_ROM.v ./GPU/disp_RAM.v ./GPU/TXT.v ./GPU/VGA.v ./GPU/GPU.v
elif [ "${BUILD}" = "GPU" ]; then
	iverilog -Wall -g2012 -s GPU -o compiled.vvp ./GPU/Font_ROM.v ./GPU/disp_RAM.v ./GPU/TXT.v ./GPU/VGA.v ./GPU/GPU.v
elif [ "${BUILD}" = "OS" ]; then
	node ./COMPILER/cli.js ./OS/main.c
elif [ "${BUILD}" = "SIM" ]; then
	cd ./ASM/CPUAssembler
	mkdir bin
	cd ./bin
	mkdir Debug
	cd ./Debug
	wget https://github.com/disaderp/automatic-chainsaw/releases/download/ASM/CPUAssembler.exe -O CPUAssembler.exe
	chmod a+x ./CPUAssembler.exe
	cd ../../../../
	echo "exit 0" > gtkwave.sh
	chmod a+x gtkwave.sh
	chmod a+x ./SIMULATOR/automatic_chainsaw_simulator.sh
	./SIMULATOR/automatic_chainsaw_simulator.sh test.asm
fi