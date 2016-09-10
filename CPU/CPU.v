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
	//fsm
	reg [15:0] state;
	reg [15:0] nstate;
	
	reg [15:0] opcode;
	reg [15:0] par1;
	reg [15:0] par2;
	
	always @(posedge clk) begin : FSM
		nstate <= 0;
		case (state)
			16'h00 : begin
				pc = pc + 1;
				opcode <= pmem[pc];
				par1 <= pmem[pc+1];
				par2 <= pmem[pc+2];
				