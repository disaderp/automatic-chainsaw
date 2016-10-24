# C--

*maintainer: [@disaderp](https://github.com/disaderp)*

Compiler for a (not in a strict sense) subset of C.

## syntactics

```c
// C99-style comments

int fn(int a, int *x) {
    other(a);
    return 0;
}

void f() { /* empty param list -> no arguments! */
    return;
}

fn(arg1, arg2);

// numbers
int pi100 = 314, esc = 033, nul = 0x0;

/* multi
   line
   comments */

/* variable declaration */
int x = 0;
char msg[12] = { 'H', 'e', 'l', 'l', 'o', ' ', 'W', 'o', 'r', 'l', 'd', 0 }; /* size is required */

/* conditionals */
if (expression)
    do stuff;
else
    do other stuff;

/* loops */
for (a; b; c)
    statement;
```

## semantics

- `char` has 8 bits
- `int` has 16 bits

## functions calls

|type|example|arguments|limitations|speed|
|---|---|---|---|---|
|fastcall|```fastcall void function()```|arguments are put into registers AX,BX,CX,DX|max 4 16bits arguments, result passed in AX|might be much faster than stdcall, not always avaliable|
|stdcall|```stdcall void function()```|arguments and result are put into stack|can be used always|takes more clock instructions than fastcall, as all arguments have to be loaded into registrers then put to stack and then back to registers|
