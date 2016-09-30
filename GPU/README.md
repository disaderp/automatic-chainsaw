# GPU

*maintainer: @Vanderpool0312*

## opcodes

| instruction | function                        | parameters     |
|-------------|---------------------------------|----------------|
| `00h`       | no-op                           | 0              |
| `C0h`       | text/graphical mode             | 0 or 1         |
| `C1h`       | character at the end of buffer  | 16-bit char    |
| `C2h`       | delete last character           | 0              |
| `C3h`       | go to line X                    | 16-bit number  |
| `C4h`       | go to row Y                     | 16-bit number  |
| `C5h`       | delete everything               | 0              |
| `C6h`       | go to new line                  | 0              |

## output

VGA.

## resolution

800x600.
