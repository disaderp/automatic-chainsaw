# CPU

*maintainer: @disaderp*

A 16-bit RISC CPU architecture.

## registers

- `AX`, `BX`, `CX`, `DX` - general purpose 16-bit registers
- `SP` - 16-bit stack pointer, accessible by `push`, `call` and `pop`
- `PC` - 16-bit program counter
- `BP` - 16-bit base pointer

## flags

- `CF` - carry flag
- `ZF` - zero flag
- `OF` - overflow flag
