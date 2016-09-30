`include "ALU.v"
`include "Buff.v"
`include "SDCard.v"

module CPU(
	input clk,
	input reset,
	output [15:0] gpuline
	);
	
	reg [15:0] gpuline;
	
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
	parameter oCBP = 16'h2D;
	parameter oCPC = 16'h2E;
	parameter oMOV1 = 16'h5;
	parameter oMOV2 = 16'h6;
	parameter oMOV3 = 16'h7;
	parameter oMOV4 = 16'h8;
	parameter oMOV5 = 16'h2A;
	parameter oMOV6 = 16'h2B;
	parameter oLEA1 = 16'h27;
	parameter oLEA2 = 16'h2C;
	parameter oLEA3 = 16'h2F;
	parameter oLEA4 = 16'h30;
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
	
	//keyboard
	wire KINPIN;//assign to PS/2 output
	wire keydata;
	reg kread;
	wire ktoread;
	
	keyboard0 #(1) InBuff(.clk(clk),.in(KINPIN),.out(keydata),.read(kread),.clkdiv(10'd1000),.outclk(),.toread(ktoread);
	//keyboard
	
	reg [15:0] opcode;
	reg [15:0] par1;
	reg [15:0] par2;
	reg [15:0] tmp;
	reg alustate;
	
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
	reg [15:0] adr;// = 32'h00_00_00_00;
	wire [4:0] state;
	reg flush;//set before power off
	
	reg [7:0] sdcard [511:0];//temp
	reg [2:0] stat;
	reg [8:0] sdpointer;
	
	assign SD_RESET = 0;
	assign SD_DAT[1] = 1;
	assign SD_DAT[2] = 1;
	assign SD_DAT[3] = spiCS;
	assign spiMiso = SD_DAT[0];
	assign SD_CMD = spiMosi;
	assign SD_SCK = spiClk;
	
	sd_controller sdcont0(.cs(spiCS), .mosi(spiMosi), .miso(spiMiso),
			.sclk(spiClk), .rd(rd), .wr(wr), .reset(!reset),
			.din(din), .dout(dout), .byte_available(byte_available),
			.ready(ready), .address(adr), 
			.ready_for_next_byte(ready_for_next_byte), .clk(clk25), 
			.status(state));
	//sdcardmodule
	
	always @(posedge clk25) begin : SD
		if (!reset) disable SD;
		adr <= 0;//temp only 512bytes
		case (stat)
			0: begin//load all data
				rd <= 1;
				stat <= 1;
			end
			1: begin //start loading
				rd <= 0;
				if (byte_available) begin
					sdcard[sdpointer] <= dout;
					sdpointer <= sdpointer + 1;
				end
				if (sdpointer == 9'd511) begin
					stat <= 2;
					zf <= 1;//zero flag when done
				end
			end
			3'd2: begin //occasional flush
				wr <= 1;
				sdpointer <= 0;
				stat <= 3'd3;
			end
			3'd3: begin //probably shutdown
				if (ready_for_next_byte) begin
					din <= sdcard[sdpointer];
					sdpointer <= sdpointer + 1;
				end
				if (sdpointer == 9'd511) begin
					stat <= 3'd4;
				end
			end
			3'd4: begin 
				//ready to shutdown 
				zf <= 1;//zero flag when done
			end
		endcase
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
		stat <= 0;
		sdpointer <= 0;
		flush <= 0;
		
		kread <= 0;
		
		//bootloader
		ram[0] <= 16'b0000000000000000;
		ram[1] <= 16'b0000000011000000;
		ram[2] <= 16'b0000000000000000;
		ram[3] <= 16'b0000000011000001;
		ram[4] <= 16'b0000000001101100;
		ram[5] <= 16'b0000000011000001;
		ram[6] <= 16'b0000000001101111;
		ram[7] <= 16'b0000000011000001;
		ram[8] <= 16'b0000000001100001;
		ram[9] <= 16'b0000000011000001;
		ram[10] <= 16'b0000000001100100;
		ram[11] <= 16'b0000000011000001;
		ram[12] <= 16'b0000000001101001;
		ram[13] <= 16'b0000000011000001;
		ram[14] <= 16'b0000000001101110;
		ram[15] <= 16'b0000000011000001;
		ram[16] <= 16'b0000000001100111;
		ram[17] <= 16'b0000000000100100;
		ram[18] <= 16'b0000000000010001;
		ram[19] <= 16'b0000000000001000;
		ram[20] <= 16'b0000000000000010;
		ram[21] <= 16'b0000000001100100;
		ram[22] <= 16'b0000000000001000;
		ram[23] <= 16'b0000000000000001;
		ram[24] <= 16'b0000000000000000;
		ram[25] <= 16'b0000000000001000;
		ram[26] <= 16'b0000000000000000;
		ram[27] <= 16'b0000000000000001;
		ram[28] <= 16'b0000000000101000;
		ram[29] <= 16'b0000000000110000;
		ram[30] <= 16'b0000000000001011;
		ram[31] <= 16'b0000000000001100;
		ram[32] <= 16'b0000000000001000;
		ram[33] <= 16'b0000000000001100;
		ram[34] <= 16'b0000000000000100;
		ram[35] <= 16'b0000000000001000;
		ram[36] <= 16'b0000000000000011;
		ram[37] <= 16'b0000000001100100;
		ram[38] <= 16'b0000000000011100;
		ram[39] <= 16'b0000000000000111;
		ram[40] <= 16'b0000000000100100;
		ram[41] <= 16'b0000000000011100;
		ram[42] <= 16'b0000000000110001;
		ram[43] <= 16'b0000000001100100;
	end
	
	always @(posedge clk) begin : FSM
		if (!reset) disable FSM;
		
		if (kread) begin
			kread <= 0;
			dx <= keydata;
		end
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
			oCBP: begin
				dx <= bp;
			end
			oCPC: begin
				dx <= pc;
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
			oLEA1: begin //xx,[yy] xx<=[yx]
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
			oLEA2: begin //[xx],yy [xx]<=yy
				case (par1[3:0])//00-ax 01-bx 10-cx 11-dx
					4'b0001: ram[ax+bp] <= bx;
					4'b0010: ram[ax+bp] <= cx;
					4'b0011: ram[ax+bp] <= dx;
					4'b0100: ram[bx+bp] <= ax;
					4'b0110: ram[bx+bp] <= cx;
					4'b0111: ram[bx+bp] <= dx;
					4'b1000: ram[cx+bp] <= ax;
					4'b1001: ram[cx+bp] <= bx;
					4'b1011: ram[cx+bp] <= dx;
					4'b1100: ram[dx+bp] <= ax;
					4'b1101: ram[dx+bp] <= bx;
					4'b1110: ram[dx+bp] <= cx;
				endcase
				pc <= pc + 1;
			end
			oLEA3 begin //xx,<yy> xx<=<yx>
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
			end
			oLEA4: begin //<xx>,yy <xx><=yy
				case (par1[3:0])//00-ax 01-bx 10-cx 11-dx
					4'b0001: ram[ax] <= bx;
					4'b0010: ram[ax] <= cx;
					4'b0011: ram[ax] <= dx;
					4'b0100: ram[bx] <= ax;
					4'b0110: ram[bx] <= cx;
					4'b0111: ram[bx] <= dx;
					4'b1000: ram[cx] <= ax;
					4'b1001: ram[cx] <= bx;
					4'b1011: ram[cx] <= dx;
					4'b1100: ram[dx] <= ax;
					4'b1101: ram[dx] <= bx;
					4'b1110: ram[dx] <= cx;
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
				if (bx[15:13] == 0) begin//sdcard
					sdcard[bx[12:0]] <= dx;
				end
				$display("Address: %b, Data: %b", bx, dx);
			end
			oIN: begin
				if (bx[15:13] == 0) begin//sdcard
					dx <= sdcard[bx[12:0]];
				end
				if (bx[15:13] == 1) begin//keyboard
					if (!ktoread) begin
						zf <= 1;//no data to read zf=0
					else begin
						zf <= 0;
						kread <= 1;
					end
				end
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
						op <= xADD;
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
						pc <= pc + 1;
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
						op <= xADC;
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
						pc <= pc + 1;
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
						op <= xSUB;
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
						pc <= pc + 1;
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
						op <= xSUC;
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
						pc <= pc + 1;
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
						op <= xMUL8;
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
						pc <= pc + 1;
						zf <= z_flag;
						alustate <= 0;
					end
				endcase
			end
			oMUL6: begin
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
						op <= xMUL6;
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
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= c;
							2'b01: bx <= c;
							2'b10: cx <= c;
							2'b11: dx <= c;
						endcase
						pc <= pc + 1;
						zf <= z_flag;
						alustate <= 0;
					end
				endcase
			end
			oDIV8: begin
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
						op <= xDIV8;
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
						pc <= pc + 1;
						zf <= z_flag;
						alustate <= 0;
					end
				endcase
			end
			oDIV6: begin
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
						op <= xDIV6;
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
						case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= c;
							2'b01: bx <= c;
							2'b10: cx <= c;
							2'b11: dx <= c;
						endcase
						pc <= pc + 1;
						zf <= z_flag;
						alustate <= 0;
					end
				endcase
			end
			oCMP: begin
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
				case (par1[3:0])//00-ax 01-bx 10-cx 11-dx
					4'b0001: ax <= (ax & bx);
					4'b0010: ax <= (ax & cx);
					4'b0011: ax <= (ax & dx);
					4'b0100: bx <= (bx & ax);
					4'b0110: bx <= (bx & cx);
					4'b0111: bx <= (bx & dx);
					4'b1000: cx <= (cx & ax);
					4'b1001: cx <= (cx & bx);
					4'b1011: cx <= (cx & dx);
					4'b1100: dx <= (dx & ax);
					4'b1101: dx <= (dx & bx);
					4'b1110: dx <= (dx & cx);
				endcase
				pc <= pc + 1;
			end
			oNEG: begin //xx xx <= ~xx
				case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= ~ax;
							2'b01: bx <= ~bx;
							2'b10: cx <= ~cx;
							2'b11: dx <= ~dx;
				endcase
				pc <= pc + 1;
			end
			oNOT: begin //xx xx <= !xx
				case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= !ax;
							2'b01: bx <= !bx;
							2'b10: cx <= !cx;
							2'b11: dx <= !dx;
				endcase
				pc <= pc + 1;
			end
			oOR: begin //xx,yx xx <= xx||yx
				case (par1[3:0])//00-ax 01-bx 10-cx 11-dx
					4'b0001: ax <= (ax | bx);
					4'b0010: ax <= (ax | cx);
					4'b0011: ax <= (ax | dx);
					4'b0100: bx <= (bx | ax);
					4'b0110: bx <= (bx | cx);
					4'b0111: bx <= (bx | dx);
					4'b1000: cx <= (cx | ax);
					4'b1001: cx <= (cx | bx);
					4'b1011: cx <= (cx | dx);
					4'b1100: dx <= (dx | ax);
					4'b1101: dx <= (dx | bx);
					4'b1110: dx <= (dx | cx);
				endcase
				pc <= pc + 1;
			end
			oSHL: begin //xx xx <= xx << 1
				case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= ax << 1;
							2'b01: bx <= bx << 1;
							2'b10: cx <= cx << 1;
							2'b11: dx <= dx << 1;
				endcase
				pc <= pc + 1;
			end
			oSHR: begin //xx xx <= xx >> 1
				case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
							2'b00: ax <= ax >> 1;
							2'b01: bx <= bx >> 1;
							2'b10: cx <= cx >> 1;
							2'b11: dx <= dx >> 1;
				endcase
				pc <= pc + 1;
			end
			oXOR: begin //xx,yx xx <= xx^yx
				case (par1[3:0])//00-ax 01-bx 10-cx 11-dx
					4'b0001: ax <= (ax ^ bx);
					4'b0010: ax <= (ax ^ cx);
					4'b0011: ax <= (ax ^ dx);
					4'b0100: bx <= (bx ^ ax);
					4'b0110: bx <= (bx ^ cx);
					4'b0111: bx <= (bx ^ dx);
					4'b1000: cx <= (cx ^ ax);
					4'b1001: cx <= (cx ^ bx);
					4'b1011: cx <= (cx ^ dx);
					4'b1100: dx <= (dx ^ ax);
					4'b1101: dx <= (dx ^ bx);
					4'b1110: dx <= (dx ^ cx);
				endcase
				pc <= pc + 1;
			end
			oTEST: begin //xx,yx xx ?= yx
				case (par1[3:0])//00-ax 01-bx 10-cx 11-dx
					4'b0001: zf <= (ax == bx);
					4'b0010: zf <= (ax == cx);
					4'b0011: zf <= (ax == dx);
					4'b0100: zf <= (ax == bx);
					4'b0110: zf <= (cx == bx);
					4'b0111: zf <= (dx == bx);
					4'b1000: zf <= (ax == cx);
					4'b1001: zf <= (cx == bx);
					4'b1011: zf <= (cx == dx);
					4'b1100: zf <= (ax == dx);
					4'b1101: zf <= (dx == bx);
					4'b1110: zf <= (dx == cx);
				endcase
				pc <= pc + 1;
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
			oJMP1: begin
				pc <= par1 + bp - 1;
			end
			oJMP2: begin
				pc <= par1 - 1;
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