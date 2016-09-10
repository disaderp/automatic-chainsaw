module vga
(
  input	clk,    //clock
  input clr,    //clear
  input	dat,    //data input
  output	hsync,    //horizontal sync
  output	vsync,    //vertical sync
  output	R,    //red
  output	G,    //green
  output	B     //blue
);
  parameter hpix=1056;    //horizontal pixel count
  parameter hsp=128;      //horizontal sync pulse
  parameter hbp=216;      //horizontal back porch
  parameter hfp=1016;     //horizontal front porch
  parameter vpix=624;     //vertical pixel count
  parameter vsp=4;        //vertical sync pulse
  parameter vbp=23;       //vertical back porch
  parameter vfp=623;      //vertical front porch
    
reg [9:0] hcounter;     //horizontal counter
reg [9:0] vcounter;     //vertical counter

//only triggered on signal transitions or edges
//posedge = falling edge = rising edge and negedge
always @(posedge clk or posedge clr)  
  begin
    if (clr == 1)   //reset requirement
      begin
        hcounter <= 0;
        vcounter <= 0;
      end
    else
  begin
      //counts until end of the line 
    if (hcounter < hpix - 1)
      hcounter <= hcounter +1;
  else
  //end of the line = horizontal counter reset + vertical counter increase
  //if vertical counter is at the end = reset of both counters
    begin
      hc <= 0;
        if (vcounter < vpix -1)
          vounter <= vc +1;
  else 
    vcounter <=0;
        end
    end
  end
//synchronization pulses generation
assign hsync = (hcounter < hsp) ? 0:1;    //horizontal sync pulse gen
assign vsync = (vcounter < vsp) ? 0:1;    //vertical sync pulse gen
