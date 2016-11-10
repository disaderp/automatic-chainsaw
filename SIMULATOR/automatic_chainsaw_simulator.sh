#!/usr/bin/env bash

set -o errexit

ROOTDIR=$(dirname $(dirname $(realpath $0)))
ASSEMBLER="mono $ROOTDIR/ASM/CPUAssembler/bin/Debug/CPUAssembler.exe"
CPUFILES=$ROOTDIR/CPU
IVERILOG=iverilog
TMPDIR=$(mktemp -d)
INPUT="$1"

cd $ROOTDIR/SIMULATOR

function bail {
  echo $* 1>&2
  exit 1
}

function assemble {
  $ASSEMBLER -ram $TMPDIR/ram.v $INPUT
  local TOTAL=$(wc -l $CPUFILES/CPU.v | cut -d' ' -f1)
  local BREAK=$(grep --line-number DONOTREMOVE $CPUFILES/CPU.v | cut -f1 -d:)
  (head -n$BREAK $CPUFILES/CPU.v && cat $TMPDIR/ram.v && tail -n$((TOTAL-BREAK)) $CPUFILES/CPU.v) > $TMPDIR/CPU_modified.v
  iverilog -Wall -g2012 -s testbench -o $TMPDIR/compiled.vvp $CPUFILES/ALU.v $CPUFILES/Buff.v $CPUFILES/SDCard.v $TMPDIR/CPU_modified.v testbench.v
  vvp $TMPDIR/compiled.vvp
}

case "$INPUT" in
  *.ASM|*.asm) assemble ;;
  *) bail "wrong file extension"
esac
