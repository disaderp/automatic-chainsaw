module InBuff(
	input clk,
	input [15:0] in,
	output [15:0] out,
	input readdone,
	input clkdiv,
	output outclk,
	output toread);
	
	reg [15:0] out;
	
	reg [15:0] inbuf [100:0];
	
	reg [15:0] counter = 0;
	reg outclk;
	reg oldread = 0;
	reg [6:0] bufpointer = 0;
	
	assign toread = (bufpointer > 0);
	
	
	always @(posedge clk) begin
		if (counter > clkdiv) begin
			outclk <= !outclk;
			counter <= 0;
			inbuf[bufpointer + 1] <= in;
			bufpointer <= bufpointer + 1;
		end
		if (!oldread) begin
			if (readdone) begin
				if(bufpointer > 0) begin
					out = inbuf[bufpointer];
					bufpointer = bufpointer - 1;
					oldread = 1;
				end
			end
			if (!readdone) begin
				oldread <= 0;
			end
		end
	end
end module

module OutBuff(
	input clk,
	input [15:0] in,
	output [15:0] out,
	input writedone,
	input clkdiv,
	output outclk,
	output toread);
	
	reg [15:0] out;
	
	reg [15:0] outbuf [100:0];
	
	reg [15:0] counter = 0;
	reg outclk;
	reg oldwrite = 0;
	reg [6:0] bufpointer = 0;
	
	assign towrite = (bufpointer < 90);
	
	
	always @(posedge clk) begin
		if (counter > clkdiv) begin
			outclk <= !outclk;
			counter <= 0;
			out <= outbuf[bufpointer + 1]
			bufpointer <= bufpointer + 1;
		end
		if (!oldwrite) begin
			if (writedone) begin
				if(bufpointer > 0) begin
					in = inbuf[bufpointer];
					bufpointer = bufpointer - 1;
					oldwrite = 1;
				end
			end
			if (!writedone) begin
				oldwrite <= 0;
			end
		end
	end
end module