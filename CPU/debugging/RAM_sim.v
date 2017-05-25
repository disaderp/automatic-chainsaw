module RAM(
	input [11:0] ADDR1,
	input [11:0] ADDR2,
	input [11:0] ADDR3,
	input [11:0] ADDR4,
	input [11:0] ADDW1,
	input [15:0] DATA,
	input WREN,
	output reg [15:0] DATA1,
	output reg [15:0] DATA2,
	output reg [15:0] DATA3,
	output reg [15:0] DATA4,
	input clk);
	
	reg [15:0] ram [4091:0];
	always @(posedge clk) begin
		DATA1 = ram[ADDR1];
		DATA2 = ram[ADDR2];
		DATA3 = ram[ADDR3];
		DATA4 = ram[ADDR4];
		if (WREN) ram[ADDW1] = DATA;
	end
	initial begin
		
		//(SIM)DONOTREMOVE//
		
	end
endmodule