module CPU(
	input clk,
	input KINPIN,
	input [3:0] SD_DAT,
	output SD_SCK,
	output SD_CMD,
	output reg [15:0] gpuline
	);
	
	reg reset = 0;
	wire clk;
	//reg
	reg [15:0] ax = 0;
	reg [15:0] bx = 0;
	reg [15:0] cx = 0;
	reg [15:0] dx = 0;
	reg [15:0] sp = 0;//stackpointer
	reg [15:0] bp = 0;//basepointer
	reg [15:0] pc = 0;//programcounter
	
	//reg [15:0] gpuline;
	
	//flg
	reg cf = 0;//carry
	reg zf = 0;//zero
	reg of = 0;//overflow
	
	//stack, ram
	reg [15:0] stack[63:0];
	reg [11:0] ADDR1 = 0;
    reg [11:0] ADDR2;
    reg [11:0] ADDR3;
    reg [11:0] ADDR4;
    reg [11:0] ADDW1;
    reg [15:0] DATA;
    reg WREN = 0;
    wire [15:0] DATA1;
    wire [15:0] DATA2;
    wire [15:0] DATA3;
    wire [15:0] DATA4;
    reg RAMState = 0;
	RAM r(ADDR1, ADDR2, ADDR3, ADDR4, ADDW1, DATA, WREN, DATA1, DATA2, DATA3, DATA4, clk);
	//reg [15:0] ram[10:0];//ram+programmemory
	
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
	parameter oDIV8 = 16'h12;
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
	parameter oJMP1 = 16'h20;
	parameter oJMP2 = 16'h31;
	parameter oJMP3 = 16'h32;
	parameter oJMP4 = 16'h33;
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
	parameter xDIV8 = 8'h7;
	parameter xCMP = 8'h9;

	
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
	//wire KINPIN;//assign to PS/2 output
	wire keydata;
	reg kread = 0;
	wire ktoread;
	
	InBuff #(.WIDTH(1)) keyboard0(.clk(clk),.in(KINPIN),.out(keydata),.read(kread),.clkdiv(10'd1000),.outclk(),.toread(ktoread));
	//keyboard
	
	reg [15:0] opcode = 0;
	reg [15:0] par1 = 0;
	reg [15:0] par2 = 0;
	reg [15:0] tmp = 0;
	reg alustate = 0;
	
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
	reg [15:0] adr = 0;// = 32'h00_00_00_00;
	wire [4:0] state;
	reg flush = 0;//set before power off
	
	reg [7:0] sdcard [10:0];//temp
	reg [2:0] stat = 0;
	reg [8:0] sdpointer = 0;
	
	wire [3:0] SD_DAT;
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
	
	//bootloader
		initial begin 
		/*ram[0] <= 16'b0000000000000000;
    	ram[1] <= 16'b0000000011000000;
    	ram[2] <= 16'b0000000000000000;
    	ram[3] <= 16'b0000000011000001;
    	ram[4] <= 16'b0000000001101100;
    	ram[5] <= 16'b0000000011000001;
    	ram[6] <= 16'b0000000001101111;
    	ram[7] <= 16'b0000000011000001;
    	ram[8] <= 16'b0000000001100001;
    	ram[9] <= 16'b0000000011000001;*/
    	
    	end
	
	/*
	always @(posedge clk25) begin : SD
		//if (!reset) disable SD;
		adr <= 0;//temp only 512bytes
		case (stat)
			0: begin//load all data
				din <= 0;
				wr <= 0;
				sdpointer <= 0;
				
				rd <= 1;
				stat <= 1;
			end
			1: begin //start loading
				rd <= 0;
				sdcard[sdpointer] <= dout;
				if (byte_available) begin
					sdpointer <= sdpointer + 1;
				end
				if (sdpointer == 9'd511) begin
					stat <= 2;
					//zf <= 1;//zero flag when done
				end
			end
			3'd2: begin //wait for flush
				if(flush) begin
					wr <= 1;
					sdpointer <= 0;
					stat <= 3'd3;
					//zf <= 0;
				end
			end
			3'd3: begin //probably shutdown
			     din <= sdcard[sdpointer];
				if (ready_for_next_byte) begin
					sdpointer <= sdpointer + 1;
				end
				if (sdpointer == 9'd511) begin
					stat <= 3'd4;
				end
			end
			3'd4: begin 
				//ready to shutdown 
				//zf <= 1;//zero flag when done@TODO: diff flag
			end
		endcase
	end
	*/
	always @(posedge clk) begin : FSM
		
			if (kread) begin
				kread <= 0;
				dx <= keydata;
			end
			
			WREN = 0;
			gpuline <= 16'h0;
			pc = pc + 1;
			ADDR1 = pc;
			opcode = DATA1;
			//rdataaddr;ram[pc];
			ADDR2 = pc+1;
			par1 = DATA2;
			//rdataadd = pc;
			ADDR3 = pc+2;
			par2 = DATA3;
			//par2 = rout;
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
					ADDW1 = par1+bp;
					case (par2[1:0]) //00-ax 01-bx 10-cx 11-dx
						 2'b00: DATA = ax;
						 2'b01: DATA = bx;
						 2'b10: DATA = cx;
						 2'b11: DATA = dx;
					endcase
					WREN = 1;
					pc <= pc + 2;
				end
				oMOV2: begin //xx,[adr] xx<=[adr] //relative address
					case (RAMState)
						1'b0: begin
							ADDR4 = par2+bp;
							pc <= pc - 1;
							RAMState = 1;
						end
						1'b1: begin
							case (par1[1:0]) //00-ax 01-bx 10-cx 11-dx
								2'b00: ax <= DATA4;
								2'b01: bx <= DATA4;
								2'b10: cx <= DATA4;
								2'b11: dx <= DATA4;
							endcase
							pc <= pc + 2;
							RAMState = 0;
						end
					endcase
				end
				oMOV5: begin //<adr>,xx <adr><=xx //absolute address
					ADDW1 = par1;
					case (par2[1:0]) //00-ax 01-bx 10-cx 11-dx
						2'b00: DATA = ax;
						2'b01: DATA = bx;
						2'b10: DATA = cx;
						2'b11: DATA = dx;
					endcase
					WREN = 1;
					pc <= pc + 2;
				end
				oMOV6: begin //xx,<adr> xx<=<adr> //absolute address
					case (RAMState)
						1'b0: begin
							ADDR4 = par2;
							pc <= pc - 1;
							RAMState = 1;
						end
						1'b1: begin
							case (par1[1:0]) //00-ax 01-bx 10-cx 11-dx
								2'b00: ax <= DATA4;
								2'b01: bx <= DATA4;
								2'b10: cx <= DATA4;
								2'b11: dx <= DATA4;
							endcase
							pc <= pc + 2;
							RAMState = 0;
						end
					endcase
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
					case (RAMState)
						1'b0: begin
							case (par1[1:0])
								2'b00: ADDR4 = ax+bp;
								2'b01: ADDR4 = bx+bp;
								2'b10: ADDR4 = cx+bp;
								2'b11: ADDR4 = dx+bp;
							endcase
							pc <= pc - 1;
							RAMState = 1;
						end
						1'b1: begin
							case (par1[3:2])//00-ax 01-bx 10-cx 11-dx
								2'b00: ax <= DATA4;
								2'b01: bx <= DATA4;
								2'b10: cx <= DATA4;
								2'b11: dx <= DATA4;
							endcase
							pc <= pc + 1;
							RAMState = 0;
						end
					endcase
				end
				oLEA2: begin //[xx],yy [xx]<=yy
					case (par1[3:0])//00-ax 01-bx 10-cx 11-dx
						4'b0001: begin ADDW1 = ax+bp; DATA = bx; end
						4'b0010: begin ADDW1 = ax+bp; DATA = cx; end
						4'b0011: begin ADDW1 = ax+bp; DATA = dx; end
						4'b0100: begin ADDW1 = bx+bp; DATA = ax; end
						4'b0110: begin ADDW1 = bx+bp; DATA = cx; end
						4'b0111: begin ADDW1 = bx+bp; DATA = dx; end
						4'b1000: begin ADDW1 = cx+bp; DATA = ax; end
						4'b1001: begin ADDW1 = cx+bp; DATA = bx; end
						4'b1011: begin ADDW1 = cx+bp; DATA = dx; end
						4'b1100: begin ADDW1 = dx+bp; DATA = ax; end
						4'b1101: begin ADDW1 = dx+bp; DATA = bx; end
						4'b1110: begin ADDW1 = dx+bp; DATA = cx; end
					endcase
					WREN = 1;
					pc <= pc + 1;
				end
				oLEA3: begin //xx,<yy> xx<=<yx>
					case (RAMState)
						1'b0: begin
							case (par1[1:0])
								2'b00: ADDR4 = ax;
								2'b01: ADDR4 = bx;
								2'b10: ADDR4 = cx;
								2'b11: ADDR4 = dx;
							endcase
							pc <= pc - 1;
							RAMState = 1;
						end
						1'b1: begin
							case (par1[3:2])//00-ax 01-bx 10-cx 11-dx
								2'b00: ax <= DATA4;
								2'b01: bx <= DATA4;
								2'b10: cx <= DATA4;
								2'b11: dx <= DATA4;
							endcase
							pc <= pc + 1;
							RAMState = 0;
						end
					endcase
				end
				oLEA4: begin //<xx>,yy <xx><=yy
					case (par1[3:0])//00-ax 01-bx 10-cx 11-dx //ABS
						4'b0001: begin ADDW1 = ax; DATA = bx; end
						4'b0010: begin ADDW1 = ax; DATA = cx; end
						4'b0011: begin ADDW1 = ax; DATA = dx; end
						4'b0100: begin ADDW1 = bx; DATA = ax; end
						4'b0110: begin ADDW1 = bx; DATA = cx; end
						4'b0111: begin ADDW1 = bx; DATA = dx; end
						4'b1000: begin ADDW1 = cx; DATA = ax; end
						4'b1001: begin ADDW1 = cx; DATA = bx; end
						4'b1011: begin ADDW1 = cx; DATA = dx; end
						4'b1100: begin ADDW1 = dx; DATA = ax; end
						4'b1101: begin ADDW1 = dx; DATA = bx; end
						4'b1110: begin ADDW1 = dx; DATA = cx; end
					endcase
					WREN = 1;
					pc <= pc + 1;
				end
				oPOP: begin
					case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
						2'b00: ax <= stack[sp-1];
						2'b01: bx <= stack[sp-1];
						2'b10: cx <= stack[sp-1];
						2'b11: dx <= stack[sp-1];
					endcase
					sp <= sp - 1;
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
						end
						else begin
							zf <= 0;
							kread <= 1;
						end
					end
				end
				oXCH: begin
					case (par1[3:0])//00-ax 01-bx 10-cx 11-dx
						4'b0001: begin ax <= bx; bx <= ax; end
						4'b0010: begin ax <= cx; cx <= ax; end
						4'b0011: begin ax <= dx; dx <= ax; end
						4'b0100: begin bx <= ax; ax <= bx; end
						4'b0110: begin bx <= cx; cx <= bx; end
						4'b0111: begin bx <= dx; dx <= bx; end
						4'b1000: begin cx <= ax; ax <= cx; end
						4'b1001: begin cx <= bx; bx <= cx; end
						4'b1011: begin cx <= dx; dx <= cx; end
						4'b1100: begin dx <= ax; ax <= dx; end
						4'b1101: begin dx <= bx; bx <= dx; end
						4'b1110: begin dx <= cx; cx <= dx; end
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
					if (par1 == 16'h1) begin
						zf <= 0;
						flush <= 1;
					end else begin
					stack[sp] <= bp;
					stack[sp+1] <= pc + 1;
					sp <= sp + 2;
					pc <= par1 - 1;
					bp <= par1;
					end
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
				oJMP3: begin
					case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
						2'b00: pc <= ax + bp - 1;
						2'b01: pc <= bx + bp - 1;
						2'b10: pc <= cx + bp - 1;
						2'b11: pc <= dx + bp - 1;
					endcase
				end
				oJMP4: begin
					case (par1[1:0])//00-ax 01-bx 10-cx 11-dx
						2'b00: pc <= ax - 1;
						2'b01: pc <= bx - 1;
						2'b10: pc <= cx - 1;
						2'b11: pc <= dx - 1;
					endcase
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
				16'hBF: begin //putchar from mem
					if (!alustate) begin
						pc <= pc - 1;
						gpuline <= opcode;
						ADDR4 = par2+bp;
						alustate <= 1;
					end
					else begin
						pc <= pc + 1;
						//gpuline <= ram[par1 + bp];
						gpuline <= DATA4;
						alustate <= 0;
					end
				end
				default: begin//unrecognized cmd//maybe gpu
					if (!alustate) begin
						pc <= pc - 1;
						gpuline <= opcode;
						alustate <= 1;
					end
					else begin
						pc <= pc + 1;
						gpuline <= par1;
						alustate <= 0;
					end
				end
			endcase
		end
endmodule