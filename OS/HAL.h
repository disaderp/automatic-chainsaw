fastcall void print(char x) {
	asm("X10111111");
	asm("X[" + &x + "]");
}
void printf(char *text, int length){
	int i;
	for(i = 0; i<length; i++){
		print(*x);
		x++;
	}
}
void initGPU(int mode) {
	if(mode == 0) {//textmode
		asm("X11000000");
		asm("X0");
		return;
	}
	else {
		//not implemented
	}
}
void scan(char x) {
	asm("MOV BX,(0010000000000000)");
	asm("IN");
	asm("CZF");
	int zf;
	asm("MOV [" + &zf + "], DX";
	if(zf == 0) {//no data in buffer
		asm("MOV DX,(0)");
		asm("PUSH DX");
	}else{
		asm("PUSH DX");
	}
}

char readbyte(int address) {
	asm("MOV BX,[" + &address + "]");
	asm("IN");
	asm("PUSH DX");
}
void writebyte(int address, char data) {
	asm("MOV BX,[" + &address + "]");
	asm("MOV DX,[" + &data + "]");
	asm("OUT");
}