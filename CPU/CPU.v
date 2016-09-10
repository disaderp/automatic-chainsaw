`include 'ALU.v'

module CPU(
	input clk,
	input [15:0] in,
	output [15:0] base,
	output [15:0] data
	);
	
	//reg
	reg [15:0] ax;
	reg [15:0] bx;
	reg [15:0] cx;
	reg [15:0] dx;
	reg [15:0] sp;
	reg [15:0] pc;
	
	//flg
	reg cf;
	reg zf;
	reg of;
	
	//stack, ram
	reg [1023:0] stack[15:0];
	reg [1023:0] ram[15:0];
	reg [1023:0] pmem[15:0];
	
	//op
	parameter oNOP = 16'h0;
	//trans
	parameter oSCF = 16'h1;
	parameter oCFF = 16'h2;
	parameter oCOF = 16'h3;
	parameter oCZF = 16'h4;
	parameter oMOV1 = 16'h5;
	parameter oMOV2 = 16'h6;
	parameter oMOV3 = 16'h7;
	parameter oMOV4 = 16'h8;
	parameter oLEA = 16'h27;
	parameter oPOP = 16'h9;
	parameter oOUT = 16'hA;
	parameter oIN = 16'h28;
	parameter oXCH = 16'h29;
	parameter oPUSH = 16'hB;
	//arithm
	parameter oADD = 16'hC;
	parameter oADC = 16'hD;
	parameter oSUB = 16'hE;
	parameter oSUC = 16'hF;
	parameter oMUL8 = 16'h10;
	parameter oMUL6 = 16'h11;
	parameter oDIV8 = 16'h12;
	parameter oDIV6 = 16'h13;
	parameter oCMP = 16'h14;
	//logic
	parameter oAND = 16'h15;
	parameter oNEG = 16'h16;
	parameter oNOT = 16'h17;
	parameter oOR = 16'h18;
	parameter oSHL = 16'h19;
	parameter oSHR = 16'h1A;
	parameter oXOR = 16'h1B;
	parameter oTEST = 16'h1C;
	//jumps
	parameter oINT = 16'h1D;
	parameter oCALL = 16'h1E;
	parameter oRET = 16'h1F;
	parameter oJMP = 16'h20;
	parameter oJC = 16'h21;
	parameter oJNC = 16'h22;
	parameter oJZ = 16'h23;
	parameter oJNZ = 16'h24;
	parameter oJO = 16'h25;
	parameter oJNO = 16'h26;
	//alu params
	parameter xADD = 8'h1;
	parameter xADC = 8'h2;
	parameter xSUB = 8'h3;
	parameter xSUC = 8'h4;
	parameter xMUL8 = 8'h5;
	parameter xMUL6 = 8'h6;
	parameter xDIV8 = 8'h7;
	parameter xDIV6 = 8'h8;
	parameter xCMP = 8'h9;

	parameter xAND = 8'hA;
	parameter xNEG = 8'hB;
	parameter xNOT = 8'hC;
	parameter xOR = 8'hD;
	parameter xSHL = 8'hE;
	parameter xSHR = 8'hF;
	parameter xXOR = 8'h10;
	parameter xTEST = 8'h11;
	
	//fsm
	reg [15:0] state;
	reg [15:0] nstate;
	
	reg [15:0] opcode;
	reg [15:0] par1;
	reg [15:0] par2;
	reg [15:0] tmp;
	
	
	always @(posedge clk) begin : FSM
		nstate <= 0;
		case (state)
			16'h0 : begin
				pc = pc + 1;
				opcode <= pmem[pc];
				par1 <= pmem[pc+1];
				par2 <= pmem[pc+2];
				case (pcmem[pc])
					oNOP: nstate <= 16'h0;
					oSCF: begin 
						cf <= par1;
						nstate <= 16'h0;
						pc <= pc + 1;
					end
					oCFF: begin
						dx <= cf;
						nstate <= 16'h0;
					end
					oCOF: begin
						dx <= of;
						nstate <= 16'h0;
					end
					oCZF: begin
						dx <= zf;
						nstate <= 16'h0;
					end
					oMOV1: begin //[adr],xx [adr]<=xx
						case (par2[1:0]) //00-ax 01-bx 10-cx 11-dx
							2'b00: ram[par2] <= ax;
							2'b01: ram[par2] <= bx;
							2'b10: ram[par2] <= cx;
							2'b11: ram[par2] <= dx;
						endcase
						pc <= pc + 2;
						nstate <= 16'h0;
					end
					oMOV2: begin //xx,[adr] xx<=[adr]
						case (par1[1:0]) //00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= ram[par2];
							2'b01: bx <= ram[par2];
							2'b10: cx <= ram[par2];
							2'b11: dx <= ram[par2];
						endcase
						pc <= pc + 2;
						nstate <= 16'h0;
					end
					oMOV3: begin //xx,yx xx<=yx 
						case (par1[3:0])//00-ax 01-bx 10-cx 11-dx
							4'b0001: ax <= bx;
							4'b0010: ax <= cx;
							4'b0011: ax <= dx;
							4'b0100: bx <= ax;
							4'b0110: bx <= cx;
							4'b0111: bx <= dx;
							4'b1000: cx <= ax;
							4'b1001: cx <= bx;
							4'b1011: cx <= dx;
							4'b1100: dx <= ax;
							4'b1101: dx <= bx;
							4'b1110: dx <= cx;
						endcase
						pc <= pc + 1;
						nstate <= 16'h0;
					end
					oMOV4: begin //xx,(int) xx<=(int)
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= par2;
							2'b01: bx <= par2;
							2'b10: cx <= par2;
							2'b11: dx <= par2;
						endcase
						pc <= pc + 2;
						nstate <= 16'h0;
					end
					oLEA: begin //xx,[yy] xx<=[yx]
						case (par1[3:0])//00-ax 01-bx 10-cx 11-dx
							4'b0001: ax <= ram[bx];
							4'b0010: ax <= ram[cx];
							4'b0011: ax <= ram[dx];
							4'b0100: bx <= ram[ax];
							4'b0110: bx <= ram[cx];
							4'b0111: bx <= ram[dx];
							4'b1000: cx <= ram[ax];
							4'b1001: cx <= ram[bx];
							4'b1011: cx <= ram[dx];
							4'b1100: dx <= ram[ax];
							4'b1101: dx <= ram[bx];
							4'b1110: dx <= ram[cx];
						endcase
						pc <= pc + 1;
						nstate <= 16'h0;
					end
					oPOP: begin
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= stack[sp];
							2'b01: bx <= stack[sp];
							2'b10: cx <= stack[sp];
							2'b11: dx <= stack[sp];
						endcase
						sp <= sp - 1;
						pc <= pc + 1;
						nstate <= 16'h0;
					end
					oOUT: begin
						//idk
						nstate <= 16'h0;
					end
					oIN: begin
						//idk
						nstate <= 16'h0;
					end
					oXCH: begin
						case (par1[3:0])//00-ax 01-bx 10-cx 11-dx
							4'b0001: begin tmp = ax; ax <= bx; bx <= tmp; end//idk
							4'b0010: begin tmp = ax; ax <= cx; cx <= tmp; end//idk
							4'b0011: begin tmp = ax; ax <= dx; dx <= tmp; end//idk
							4'b0100: begin tmp = bx; bx <= ax; ax <= tmp; end//idk
							4'b0110: begin tmp = bx; bx <= cx; cx <= tmp; end//idk
							4'b0111: begin tmp = bx; bx <= dx; dx <= tmp; end//idk
							4'b1000: begin tmp = cx; cx <= ax; ax <= tmp; end//idk
							4'b1001: begin tmp = cx; cx <= bx; bx <= tmp; end//idk
							4'b1011: begin tmp = cx; cx <= dx; dx <= tmp; end//idk
							4'b1100: begin tmp = dx; dx <= ax; ax <= tmp; end//idk
							4'b1101: begin tmp = dx; dx <= bx; bx <= tmp; end//idk
							4'b1110: begin tmp = dx; dx <= cx; cx <= tmp; end//idk
						endcase
						pc <= pc + 1;
						nstate <= 16'h0;
					end
					oPUSH: begin
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: stack[sp] <= ax;
							2'b01: stack[sp] <= bx;
							2'b10: stack[sp] <= cx;
							2'b11: stack[sp] <= dx;
						endcase
						sp <= sp + 1;
						pc <= pc + 1;
						nstate <= 16'h0;
					end
					
					
					
					
					
					
					