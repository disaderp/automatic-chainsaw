module CPUclk(
	input CLK_IN1,
	output reg CLK_OUT1);
	
	always @(posedge CLK_IN1) begin
		CLK_OUT1 =~CLK_OUT1;
	end
	
	initial begin
		CLK_OUT1 = 1;
	end
endmodule