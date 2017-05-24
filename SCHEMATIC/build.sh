#!/bin/bash
set -ev

if [ "${BUILD}" = "ASM" ]; then
	xbuild /p:Configuration=Release ./ASM/CPUAssembler/CPUAssembler.sln
elif [ "${BUILD}" = "COM" ]; then
	node ./COMPILER/compile.js ./COMPILER/define.cmm
elif [ "${BUILD}" = "CPU" ]; then
	./verilog-10.1.1/iverilog-vpi -Wall -g2012 -s CPU -o compiled.vvp ./CPU/ALU.v   ./CPU/RAM.v ./CPU/CPU.v ./GPU/Font_ROM.v ./GPU/TXT.v ./GPU/VGA.v ./GPU/GPU.v
elif [ "${BUILD}" = "GPU" ]; then
	./verilog-10.1.1/iverilog-vpi -Wall -g2012 -s GPU -o compiled.vvp ./GPU/Font_ROM.v ./GPU/TXT.v ./GPU/VGA.v ./GPU/GPU.v
	./verilog-10.1.1/iverilog-vpi -h
elif [ "${BUILD}" = "OS" ]; then
	node ./COMPILER/compile.js ./OS/main.c
fi