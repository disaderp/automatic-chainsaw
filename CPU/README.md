# ChainsawCPU

*maintainer: [@disaderp](https://github.com/disaderp)*

A custom architecture 16-bit RISC CPU created in Verilog.

## registers

- `AX`, `BX`, `CX`, `DX` - general purpose 16-bit registers
- `SP` - 16-bit stack pointer, accessible by `push`, `call` and `pop`
- `PC` - 16-bit program counter
- `BP` - 16-bit base pointer

## flags

- `CF` - carry flag
- `ZF` - zero flag
- `OF` - overflow flag

## opcodes

- See a [complete list of opcodes](https://github.com/disaderp/automatic-chainsaw/blob/master/SCHEMATIC/op.txt).

## memory

- stack - 64 *16bites
- RAM - 4092 *16bites

## how to run gtkwave

- compile source to `CPU_c.vvp` file (with `-s testbench`, and files from `debugging` folder(`RAM_sim.v` and `cpu_testbench.v`)
- `vvp CPU_c.vvp -lxt2`
- `gtkwave CPU_dump.lxt`