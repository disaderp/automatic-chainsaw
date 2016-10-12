module VGA
(
	input clk,	//clock
	input clr,	//clear
	output reg[9:0] pixv,	//pixel vertical location
	output reg[9:0] pixh	//pixel horizontal location
	
);
	parameter hpix=1056;    //horizontal pixel count
	parameter hsp=128;      //horizontal sync pulse
	parameter hbp=216;      //horizontal back porch
	parameter hfp=1016;     //horizontal front porch
	parameter vpix=628;     //vertical pixel count
	parameter vsp=4;        //vertical sync pulse
	parameter vbp=23;       //vertical back porch
	parameter vfp=627;      //vertical front porch
	
reg [9:0] hcounter;     //horizontal counter
reg [9:0] vcounter;     //vertical counter

//only triggered on signal transitions or edges
//posedge = falling edge = rising edge and negedge
always @(posedge clk) begin
	if (clr == 1) begin //reset requirement
			hcounter <= 0;
			vcounter <= 0;
	end else begin //counts until end of the line 
		if (hcounter < hpix - 1)
			hcounter <= hcounter +1;
		else begin
			//end of the line = horizontal counter reset + vertical counter increase
			//if vertical counter is at the end = reset of both counters
			hcounter <= 0;
			if (vcounter < vpix - 1)
				vcounter <= vcounter +1;
			else 
				vcounter <=0;
		end
	end
	if (vcounter >= vbp+vsp && vcounter < vfp) begin
		if (hcounter >= 256 && hcounter < hpix) begin
			pixh <= hcounter - 10'd256;
			pixv <= vcounter - 10'd27;
		end
	end
end

//synchronization pulses generation
assign hsync = (hcounter < hsp) ? 0:1;    //horizontal sync pulse gen
assign vsync = (vcounter < vsp) ? 0:1;    //vertical sync pulse gen

endmodule