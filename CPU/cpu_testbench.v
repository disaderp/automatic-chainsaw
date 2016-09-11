module testbench();

	reg clk;
	reg [15:0] in;
	wire [15:0] base;
	wire [15:0] data;
	wire flag;//r/w flag
	reg reset;
	CPU c0 (
		.clk (clk),
		.in(in),
		.base(base),
		.data(data),
		.flag(flag) ,
		.reset(reset)
	);
	
	
	initial begin
		$monitor ("%g\t clk=%b in=%b base=%b data=%b flag=%b",
		$time, clk, in, base, data, flag);
		reset = 0;
		clk = 1;
		#15 reset = 1;
		#250 $finish;
	end
	  
	always begin
		#5 clk =~clk;
	end
	
endmodule