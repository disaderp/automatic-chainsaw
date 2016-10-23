/*
FILE SYSTEM HEADER

CHAIN
FILE
SYSTEM

*/

#include "HAL.h"
#include "OPER.h"
#define	MAX_FILENAME_LENGTH 10

bool read_cfs(char *c_name){
	int u_address = 0; int i = 0; int u_temp = 0;
	char c_temp[MAX_FILENAME_LENGTH];
	
	while (1)
	{
		while (i < MAX_FILENAME_LENGTH){
		c_temp[i] = readbyte (u_address);
		}
		if (char_compare_l(c_temp,c_name, MAX_FILENAME_LENGTH)){
			break;
		}
		//replace with shift instruction
		u_temp = u_address + 256*(readbyte(u_address + 11)) +(readbyte(u_address + 12) + 12;
		
		//Check if procedure is running correctly
		if (u_address < u_temp){
			u_address = u_temp;
		}
		else{
			return false;
		}
	}
	
	// ----------------------------------------------------------------------------------
	// NOT SURE IF THIS WILL WORK!!
	u_temp = u_address + 256*(readbyte(u_address + 11)) +(readbyte(u_address + 12) + 12;
	//Check if procedure is running correctly
		if (u_address < u_temp){
			u_address = u_temp;
		}
		else{
			return false;
		}
	//TODO - WRITE CODE HERE TO DO SOMETHING WITH THE FOUND DATA!
	
	return true;
	//FUNCTION TYPE PROBABLY WILL BE CHANGED (PROBABLY IT'LL RETURN DATA ADDRESS AND LENGTH)
}

bool write_cfs (char *c_data, char *c_name)
{
	//TODO - CHECK IF THE FILE NAME ALREADY EXISTS!
	
	//TODO - FIND IF THERE IS PLACE FOR FILE OF THIS SIZE
	
	//TODO - SAVE FILE
	
	return true;
}