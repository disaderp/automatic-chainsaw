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
int pi100 = 314;
int esc = 033;
int nul = 0x0;

/* multi
   line
   comments */

/* variable declaration */
int x = 0;
char msg[12] = "Hello World"; /* size is required, terminated with 0 by default */

/* conditionals */
if (expression)
    do stuff;
else
    do other stuff;

/* loops */
for (a; b; c)
    statement;