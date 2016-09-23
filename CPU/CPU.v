`include "ALU.v"
`include "Buff.v"
`include "SDCard.v"

module CPU(
	input clk,
	input [15:0] in,
	output [15:0] base,
	output [15:0] data,
	output flag,//r/w flag//TODO: inout buffer
	input reset
	);
	
	assign base = bx;//TODO: inout buffer
	assign data = dx;
	reg flag;
	
	reg [15:0] gpuline;//TODO: pilnowac 0
	
	//reg
	reg [15:0] ax;
	reg [15:0] bx;
	reg [15:0] cx;
	reg [15:0] dx;
	reg [15:0] sp;//stackpointer
	reg [15:0] bp;//basepointer
	reg [15:0] pc;//programcounter
	
	//flg
	reg cf;//carry
	reg zf;//zero
	reg of;//overflow
	
	//stack, ram
	reg [15:0] stack[1023:0];
	reg [15:0] ram[2047:0];//ram+programmemory
	
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
	parameter oMOV5 = 16'h2A;
	parameter oMOV6 = 16'h2B;
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
	
	//alumodule
	reg [15:0] ain;
	reg [15:0] bin;
	reg [7:0] op;
	wire c_flag;
	wire z_flag;
	wire o_flag;
	wire [15:0] acc;
	wire [15:0] c;
	
	dALU alu0 (
		.clk (clk),
		.a(ain),
		.b(bin),
		.op(op),
		.cf(cf),
		.c_flag(c_flag),
		.z_flag(z_flag),
		.o_flag(o_flag),
		.acc(acc),
		.c(c)
	);//alumodule
	
	//sdcardmodule
	wire spiClk;
	wire spiMiso;
	wire spiMosi;
	wire spiCS;
	
	wire clk25;
	clock_divider div1(clk, c5);
	clock_divider div2(c5, clk25);
	
	reg rd = 0;
	reg wr = 0;
	reg [7:0] din = 0;
	wire [7:0] dout;
	wire byte_available;
	wire ready;
	wire ready_for_next_byte;
	reg [31:0] adr = 32'h00_00_00_00;
	wire [4:0] state;
	
	assign SD_RESET = 0;
	assign SD_DAT[1] = 1;
	assign SD_DAT[2] = 1;
	assign SD_DAT[3] = spiCS;
	assign spiMiso = SD_DAT[0];
	assign SD_CMD = spiMosi;
	assign SD_SCK = spiClk;
	
	assign adr = bx;
	
	sd_controller sdcont0(.cs(spiCS), .mosi(spiMosi), .miso(spiMiso),
			.sclk(spiClk), .rd(rd), .wr(wr), .reset(!reset),
			.din(din), .dout(dout), .byte_available(byte_available),
			.ready(ready), .address(adr), 
			.ready_for_next_byte(ready_for_next_byte), .clk(clk25), 
			.status(state));
	//sdcardmodule
	
	reg [15:0] opcode;
	reg [15:0] par1;
	reg [15:0] par2;
	reg [15:0] tmp;
	reg alustate;
	
	always @(posedge clk25) begin : SD
		if (!reset) disable SD;
		
	end
	
	always @(posedge clk) begin : res
		if (reset) disable res;
		ax <= 0;
		bx <= 0;
		cx <= 0;
		dx <= 0;
		sp <= 0;
		pc <= 0;
		bp <= 0;
		alustate <= 0;
		flag <= 0;//TODO: inout buffer
		cf <= 0;
		zf <= 0;
		of <= 0;
		gpuline <= 0;
		
		bytes <= 0;
		bytes_read <= 0;
		din <= 0;
		wr <= 0;
		rd <= 0;
		test_state <= STATE_INIT; 
		
		ram[0] <= oNOP;
		ram[1] <= oMOV4;//int to reg
		ram[2] <= 2'b01;//bx
		ram[3] <= 16'd1;//port 1
		ram[4] <= oMOV4;//int to reg
		ram[5] <= 2'b11;//dx
		ram[6] <= 16'd1;//data=10
		ram[7] <= oMOV4;//int to reg
		ram[8] <= 2'b00;//ax
		ram[9] <= 16'd0;//ax=11
		ram[10] <= oSUB;//add with carry//2clock cycles
		ram[11] <= oMOV3;//reg to reg
		ram[12] <= 4'b1100;//dx = ax
		ram[13] <= oOUT;
		ram[14] <= oADD;//add without carry//1clock cycle
		ram[15] <= oMOV3;//reg to reg
		ram[16] <= 4'b1100;//dx=ax
		ram[17] <= oOUT;
		ram[18] <= oNOP;
	end
	
	always @(posedge clk) begin : FSM
		if (!reset) disable FSM;
		flag <= 0;
		gpuline <= 16'h0;
		pc = pc + 1;
		opcode = ram[pc];
		par1 = ram[pc+1];
		par2 = ram[pc+2];
		case (opcode)
			oNOP: begin end
			oSCF: begin 
				cf <= par1;
				pc <= pc + 1;
			end
			oCFF: begin
				dx <= cf;
			end
			oCOF: begin
				dx <= of;
			end
			oCZF: begin
				dx <= zf;
			end
			oMOV1: begin //[adr],xx [adr]<=xx //relative address
				case (par2[1:0]) //00-ax 01-bx 10-cx 11-dx
					2'b00: ram[par1+bp] <= ax;
					2'b01: ram[par1+bp] <= bx;
					2'b10: ram[par1+bp] <= cx;
					2'b11: ram[par1+bp] <= dx;
				endcase
				pc <= pc + 2;
			end
			oMOV2: begin //xx,[adr] xx<=[adr] //relative address
				case (par1[1:0]) //00-ax 01-bx 10-cx 11-dx
					2'b00: ax <= ram[par2+bp];
					2'b01: bx <= ram[par2+bp];
					2'b10: cx <= ram[par2+bp];
					2'b11: dx <= ram[par2+bp];
				endcase
				pc <= pc + 2;
			end
			oMOV5: begin //<adr>,xx <adr><=xx //absolute address
				case (par2[1:0]) //00-ax 01-bx 10-cx 11-dx
					2'b00: ram[par1] <= ax;
					2'b01: ram[par1] <= bx;
					2'b10: ram[par1] <= cx;
					2'b11: ram[par1] <= dx;
				endcase
				pc <= pc + 2;
			end
			oMOV6: begin //xx,<adr> xx<=<adr> //absolute address
				case (par1[1:0]) //00-ax 01-bx 10-cx 11-dx
					2'b00: ax <= ram[par2];
					2'b01: bx <= ram[par2];
					2'b10: cx <= ram[par2];
					2'b11: dx <= ram[par2];
				endcase
				pc <= pc + 2;
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
			end
			oMOV4: begin //xx,(int) xx<=(int)
				case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
					2'b00: ax <= par2;
					2'b01: bx <= par2;
					2'b10: cx <= par2;
					2'b11: dx <= par2;
				endcase
				pc <= pc + 2;
			end
			oLEA: begin //xx,[yy] xx<=[yx]
				case (par1[3:0])//00-ax 01-bx 10-cx 11-dx
					4'b0001: ax <= ram[bx+bp];
					4'b0010: ax <= ram[cx+bp];
					4'b0011: ax <= ram[dx+bp];
					4'b0100: bx <= ram[ax+bp];
					4'b0110: bx <= ram[cx+bp];
					4'b0111: bx <= ram[dx+bp];
					4'b1000: cx <= ram[ax+bp];
					4'b1001: cx <= ram[bx+bp];
					4'b1011: cx <= ram[dx+bp];
					4'b1100: dx <= ram[ax+bp];
					4'b1101: dx <= ram[bx+bp];
					4'b1110: dx <= ram[cx+bp];
				endcase
				pc <= pc + 1;
			end
			oPOP: begin
				sp = sp - 1;
				case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
					2'b00: ax = stack[sp];
					2'b01: bx = stack[sp];
					2'b10: cx = stack[sp];
					2'b11: dx = stack[sp];
				endcase
				pc <= pc + 1;
			end
			oOUT: begin
				//TODO: inout buffer
				$display("Address: %b, Data: %b", bx, dx);
				flag <= 1;
			end
			oIN: begin
				//TODO: inout buffer
				dx <= in;
			end
			oXCH: begin
				case (par1[3:0])//00-ax 01-bx 10-cx 11-dx
					4'b0001: begin tmp = ax; ax = bx; bx = tmp; end
					4'b0010: begin tmp = ax; ax = cx; cx = tmp; end
					4'b0011: begin tmp = ax; ax = dx; dx = tmp; end
					4'b0100: begin tmp = bx; bx = ax; ax = tmp; end
					4'b0110: begin tmp = bx; bx = cx; cx = tmp; end
					4'b0111: begin tmp = bx; bx = dx; dx = tmp; end
					4'b1000: begin tmp = cx; cx = ax; ax = tmp; end
					4'b1001: begin tmp = cx; cx = bx; bx = tmp; end
					4'b1011: begin tmp = cx; cx = dx; dx = tmp; end
					4'b1100: begin tmp = dx; dx = ax; ax = tmp; end
					4'b1101: begin tmp = dx; dx = bx; bx = tmp; end
					4'b1110: begin tmp = dx; dx = cx; cx = tmp; end
				endcase
				pc <= pc + 1;
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
			end
			
			oADD: begin
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						ain <= dx;
						bin <= ax;
						op <= xADD;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						ax <= acc;
						cf <= c_flag;
						zf <= z_flag;
						of <= o_flag;
						alustate <= 0;
					end
				endcase
			end
			oADC: begin
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						ain <= dx;
						bin <= ax;
						op <= xADC;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						ain <= dx;
						bin <= ax;
						ax <= acc;
						cf <= c_flag;
						zf <= z_flag;
						of <= o_flag;
						alustate <= 0;
					end
				endcase
			end
			oSUB: begin
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						ain <= dx;
						bin <= ax;
						op <= xSUB;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						ax <= acc;
						cf <= c_flag;
						zf <= z_flag;
						of <= o_flag;
						alustate <= 0;
					end
				endcase
			end
			oSUC: begin
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						ain <= dx;
						bin <= ax;
						op <= xSUC;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						ax <= acc;
						cf <= c_flag;
						zf <= z_flag;
						of <= o_flag;
						alustate <= 0;
					end
				endcase
			end
			oMUL8: begin
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						ain <= dx;
						bin <= ax;
						op <= xMUL8;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						ax <= acc;
						zf <= z_flag;
						alustate <= 0;
					end
				endcase
			end
			oMUL6: begin
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						ain <= dx;
						bin <= ax;
						op <= xMUL6;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						ax <= acc;
						bx <= c;
						zf <= z_flag;
						alustate <= 0;
					end
				endcase
			end
			oDIV8: begin
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						ain <= dx;
						bin <= ax;
						op <= xDIV8;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						ax <= acc;
						zf <= z_flag;
						alustate <= 0;
					end
				endcase
			end
			oDIV6: begin
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						ain <= dx;
						bin <= ax;
						op <= xDIV6;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						ax <= acc;
						bx <= c;
						zf <= z_flag;
						alustate <= 0;
					end
				endcase
			end
			oCMP: begin
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						ain <= dx;
						bin <= ax;
						op <= xCMP;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						cf <= c_flag;
						zf <= z_flag;
						of <= o_flag;
						alustate <= 0;
					end
				endcase
			end
			
			oAND: begin //xx,yx xx <= xx&&yx
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						case (par1[3:2])//00-ax 01-bx 10-cx 11-dx
							2'b00: ain <= ax;
							2'b01: ain <= bx;
							2'b10: ain <= cx;
							2'b11: ain <= dx;
						endcase
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: bin <= ax;
							2'b01: bin <= bx;
							2'b10: bin <= cx;
							2'b11: bin <= dx;
						endcase
						op <= xAND;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						case (par1[3:2])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= acc;
							2'b01: bx <= acc;
							2'b10: cx <= acc;
							2'b11: dx <= acc;
						endcase
						alustate <= 0;
						pc <= pc + 1;
					end
				endcase
			end
			oNEG: begin //xx xx <= ~xx
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ain <= ax;
							2'b01: ain <= bx;
							2'b10: ain <= cx;
							2'b11: ain <= dx;
						endcase
						op <= xNEG;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= acc;
							2'b01: bx <= acc;
							2'b10: cx <= acc;
							2'b11: dx <= acc;
						endcase
						alustate <= 0;
						pc <= pc + 1;
					end
				endcase
			end
			oNOT: begin //xx xx <= !xx
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ain <= ax;
							2'b01: ain <= bx;
							2'b10: ain <= cx;
							2'b11: ain <= dx;
						endcase
						op <= xNOT;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= acc;
							2'b01: bx <= acc;
							2'b10: cx <= acc;
							2'b11: dx <= acc;
						endcase
						alustate <= 0;
						pc <= pc + 1;
					end
				endcase
			end
			oOR: begin //xx,yx xx <= xx||yx
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						case (par1[3:2])//00-ax 01-bx 10-cx 11-dx
							2'b00: ain <= ax;
							2'b01: ain <= bx;
							2'b10: ain <= cx;
							2'b11: ain <= dx;
						endcase
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: bin <= ax;
							2'b01: bin <= bx;
							2'b10: bin <= cx;
							2'b11: bin <= dx;
						endcase
						op <= xOR;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						case (par1[3:2])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= acc;
							2'b01: bx <= acc;
							2'b10: cx <= acc;
							2'b11: dx <= acc;
						endcase
						alustate <= 0;
						pc <= pc + 1;
					end
				endcase
			end
			oSHL: begin //xx xx <= xx << 1
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ain <= ax;
							2'b01: ain <= bx;
							2'b10: ain <= cx;
							2'b11: ain <= dx;
						endcase
						op <= xSHL;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= acc;
							2'b01: bx <= acc;
							2'b10: cx <= acc;
							2'b11: dx <= acc;
						endcase
						alustate <= 0;
						pc <= pc + 1;
					end
				endcase
			end
			oSHR: begin //xx xx <= xx >> 1
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ain <= ax;
							2'b01: ain <= bx;
							2'b10: ain <= cx;
							2'b11: ain <= dx;
						endcase
						op <= xSHR;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= acc;
							2'b01: bx <= acc;
							2'b10: cx <= acc;
							2'b11: dx <= acc;
						endcase
						alustate <= 0;
						pc <= pc + 1;
					end
				endcase
			end
			oXOR: begin //xx,yx xx <= xx^yx
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						case (par1[3:2])//00-ax 01-bx 10-cx 11-dx
							2'b00: ain <= ax;
							2'b01: ain <= bx;
							2'b10: ain <= cx;
							2'b11: ain <= dx;
						endcase
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: bin <= ax;
							2'b01: bin <= bx;
							2'b10: bin <= cx;
							2'b11: bin <= dx;
						endcase
						op <= xXOR;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						case (par1[3:2])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= acc;
							2'b01: bx <= acc;
							2'b10: cx <= acc;
							2'b11: dx <= acc;
						endcase
						alustate <= 0;
						pc <= pc + 1;
					end
				endcase
			end
			oTEST: begin //xx,yx xx ?= yx
				case (alustate) //0- not initiated 1-waiting
					1'b0: begin
						case (par1[3:2])//00-ax 01-bx 10-cx 11-dx
							2'b00: ain <= ax;
							2'b01: ain <= bx;
							2'b10: ain <= cx;
							2'b11: ain <= dx;
						endcase
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: bin <= ax;
							2'b01: bin <= bx;
							2'b10: bin <= cx;
							2'b11: bin <= dx;
						endcase
						op <= xTEST;
						pc <= pc - 1;
						alustate <= 1;
					end
					1'b1: begin
						zf <= z_flag;
						alustate <= 0;
						pc <= pc + 1;
					end
				endcase
			end
			
			oINT: begin//absolute address
				stack[sp] <= bp;
				stack[sp+1] <= pc + 1;
				sp <= sp + 2;
				pc <= par1 - 1;
				bp <= par1;
			end
			oCALL: begin//relative address
				stack[sp] <= bp;
				stack[sp+1] <= pc + 1;
				sp <= sp + 2;
				pc <= par1 + bp - 1;
				bp <= par1;
			end
			oRET: begin
				pc <= stack[sp-1];
				bp <= stack[sp-2];
				sp <= sp - 2;
			end
			oJMP: begin
				pc <= par1 + bp - 1;
			end
			oJC: begin
				if (cf) pc <= par1 + bp - 1;
				else pc <= pc + 1;
			end
			oJNC: begin
				if (!cf) pc <= par1 + bp - 1;
				else pc <= pc + 1;
			end
			oJZ: begin
				if (zf) pc <= par1 + bp - 1;
				else pc <= pc + 1;
			end
			oJNZ: begin
				if (!zf) pc <= par1 + bp - 1;
				else pc <= pc + 1;
			end
			oJO: begin
				if (of) pc <= par1 + bp - 1;
				else pc <= pc + 1;
			end
			oJNO: begin
				if (!of) pc <= par1 + bp - 1;
				else pc <= pc + 1;
			end
			default: begin//unrecognized cmd//maybe gpu
				if (!alustate) begin
					pc <= pc - 1;
					gpuline <= opcode;
					alustate <= 1;
				else begin
					pc <= pc + 1;
					gpuline <= par1;
					alustate <= 0;
				end
		endcase
	end
endmodule