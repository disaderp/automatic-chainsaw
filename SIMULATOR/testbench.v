module testbench();

	reg clk;
	reg reset;
	CPU c0 (
		.clk (clk),
		.KINPIN(),
		.SD_SCK(),
		.SD_CMD(),
		.gpuline()
	);
	
	
	initial begin
		//$monitor ("%g\t clk=%b ",
		//$time, clk);
		reset = 0;
		clk = 1;
		#15 reset = 1;
		#2000 $finish;
	end
	  
	always begin
		#5 clk =~clk;
	end
	
endmodule