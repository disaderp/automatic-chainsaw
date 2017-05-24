#!/bin/bash
set -ev

if [ "${BUILD}" = "ASM" ]; then
	xbuild /p:Configuration=Release ../ASM/CPUAssembler/CPUAssembler.sln
elif [ "${BUILD}" = "COM" ]; then
	node -c compile.js
elif [ "${BUILD}" = "CPU" ]; then
	verilog -Wall -g2012 -s CPU -o tmp/compiled.vvp ../CPU/ALU.v   ../CPU/RAM.v ../CPU/CPU.v ../GPU/Font_ROM.v ../GPU/TXT.v ../GPU/VGA.v ../GPU/GPU.v
elif [ "${BUILD}" = "GPU" ]; then
	verilog -Wall -g2012 -s GPU -o tmp/compiled.vvp ../GPU/Font_ROM.v ../GPU/TXT.v ../GPU/VGA.v ../GPU/GPU.v
elif [ "${BUILD}" = "OS" ]; then
	node compile.js ../OS/main.c
fi