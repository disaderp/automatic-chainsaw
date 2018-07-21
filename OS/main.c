#include "HAL.h"
#include "FUNC.h"
#include "OPER.h"
#include "CFS.h"

#define enter 13
#define backspace 8
#define max_buffer_size 63
#define function_name_lenght 6

void main ()
{
initGPU(0);
/*WELCOME MESSAGE*/
print_const("Welcome to Brain_OS 0.1a");

/*BASIC VARIABLES*/
char c_user_buffer[64];
c_user_buffer[max_buffer_size] = 0;

int p_user_buffer = 0;
/*bool b_isEnterPressed = false;*/

/* MAIN SYSTEM LOOP*/
while (1){
	/*Get key pressed by user*/
	print_const(">");
	while (1){
	char c_temp = scan();
		if (c_temp != 0){
			if (c_temp == enter){
				/*b_isEnterPressed = true;*/
				c_user_buffer[p_user_buffer] = 0;
				p_user_buffer = 0;
				newline();
				break;
			}

			if (c_temp == backspace){
				if (p_user_buffer != 0){
					p_user_buffer = p_user_buffer - 1;
					delchar();
					continue;
				}
			}

			c_user_buffer[p_user_buffer] = c_temp;
			print(c_temp);

			if (p_user_buffer < max_buffer_size) {
				p_user_buffer = p_user_buffer + 1;
			}
			else{
				newline();
				c_user_buffer[max_buffer_size] = 0;
				break;
			}

		}
	}
	/* Check if buffer contains function
	 First characters contains function name. The rest is either parameters, null or gibberish. */

	/*TODO (CREATE FUNCTION CHECKER)*/

#define enter 13
#define backspace 8
#define max_buffer_size 63
#define function_name_lenght 6
		if (char_compare_l (c_user_buffer, "helpme",6)){
		/*TODO (CREATE PARAMETER CHECKER AND RELAY)*/
	}
	else if (char_compare_l (c_user_buffer, "exec",4)){

	}
	else if (char_compare_l (c_user_buffer, "shutdown",8)){
		shutdown();
		print_const("Pull out the plug and lets hope for the best :)")
		while (1){}
	}
	else if (char_compare_l (c_user_buffer, "login",5)){

	}
	else if (char_compare_l (c_user_buffer, "logout",6)){

	}

	/*b_isEnterPressed = false;*/
}
}
