module vga
(
input	clk,
input clr,
input	dat,
output	hsync,
output	vsync,
output	R,
output	G,
output	B
);
parameter hpix=1056;
parameter hsp=128;
parameter hbp=216;
parameter hfp=1016;
parameter vpix=624;
parameter vsp=4;
parameter vbp=23;
parameter vfp=623;

reg [9:0] hcounter;
reg [9:0] vcounter;

always @(posedge clk or posedge clr)
begin
if (clr == 1)
begin
hcounter <= 0;
vcounter <= 0;
end
else
begin
if (hcounter < hpix - 1)
hcounter <= hcounter +1;
else
begin
hc <= 0;
if (vcounter < vpix -1)
vounter <= vc +1;
else 
vcounter <=0;
end
end
end

assign hsync = (hcounter < hsp) ? 0:1;
assign vsync = (vcounter < vsp) ? 0:1;