module testbench();

	reg clk;
	wire [15:0] ADDRBUS;
	wire [1:0] CTRLBUS;//00 - none //01 - read // 10 - write // 11 - ?
	wire [15:0] DATABUS;
	wire vga;
	wire hsync; 
	wire vsync;
	CPU c0 (
		.clkR (clk),
		.ADDRBUS(ADDRBUS),
		.CTRLBUS(CTRLBUS),
		.DATABUS(DATABUS),
		.vga(vga),
		.hsync(hsync),
		.vsync(vsync)
	);
	
	
	initial begin
		//$monitor ("%g\t clk= addr=%b ctrl=%b data=%b",
		//$time,  ADDRBUS, CTRLBUS, DATABUS);
		//reset = 0;
		$dumpfile("CPU_dump.lxt");
		$dumpvars(0,testbench);
		clk = 1;
		//#15 reset = 1;
		#1000000 $finish;
		
	end
	  
	always begin
		#1 clk =~clk;
	end
	
endmodule