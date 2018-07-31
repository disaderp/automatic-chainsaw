# ChainsawAssembler

*maintainer: [@disaderp](https://github.com/disaderp)*

Assembler for the machine code.

## usage

- Windows: `CPUAssembler <params>`
- Linux: `mono CPUAssembler.exe <params>`

| params                  | purpose                      |
|-------------------------|------------------------------|
| `-plain <input>`        | print 0s and 1s              |
| `-ram <output> <input>` | writes in RAM Verilog format |
| `-bin <output> <input>` | writes raw bytes             |

## syntax

```
' copy DX to  absolute address 01100 - abs values in < >
MOV <01100>,DX
' copy a 16-bit immediate value to AX, exact values in ( ) - binary form
MOV AX,(1001)
' declare a label
.loop
' jump to a label, addresses in [ ] - label or exact
JMP [.loop]
```

See a [complete list of opcodes](https://github.com/disaderp/automatic-chainsaw/blob/master/SCHEMATIC/op.txt).
