# GPU

*maintainer: @Vanderpool0312*

## opcodes

| instruction | function                        | parameters     |
|-------------|---------------------------------|----------------|
| `00h`       | no-op                           | -              |
| `C0h`       | text/graphical mode             | 0 or 1         |
| `C1h`       | character at the end of buffer  | 16-bit char    |
| `C2h`       | delete last character           | -              |
| `C3h`       | go to line X                    | 16-bit number  |
| `C4h`       | go to row Y                     | 16-bit number  |
| `C5h`       | delete everything               | -              |
| `C6h`       | go to new line                  | -              |

## output

VGA.

## resolution

800x600.
