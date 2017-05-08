module TXT(
input clk,		//clock
input clr,		//clear
input [7:0] char_line_dat,	//data
output reg out_vga, //vga output
output reg [11:0] asciiaddress = 0, 
output reg dis_mem_en = 0,		//enables display memory
output reg font_mem_en = 0,		//enables font memory
output [9:0] pix_x,
output [9:0] pix_y,
output hsync, output vsync
);

reg [7:0] line;		//sth
reg [11:0] hp;		//sth else
reg [11:0] vp;		//sth else2
//wire [9:0] pixv;	//pixel vertical location
//wire [9:0] pixh;
VGA z0 (
		.clk (clk),
		//.clr (clr),
		.pixv (pix_x),
		.pixh (pix_y),
		.hsync(hsync),
		.vsync(vsync)
		);
//assign pix_x = pixh;
//assign pix_y = pixv;

always @ (posedge clk)//or negedge clr
begin

		asciiaddress <= 0;
			case (pix_x[2:0])
				3'b110: begin
					hp[11:0] <= { 6'd0, pix_x[9:4] };
					vp[11:0] <= { 6'd0, pix_y[9:4] };
					asciiaddress[11:0] <= hp + (vp << 5) + (vp << 3); //40 = 2*2*2*2*2 + 2*2*2
					dis_mem_en <= 1;
					font_mem_en <= 1;
				end
	
				3'b111: begin
					line <= char_line_dat;
				end
				3'b000: begin
					dis_mem_en <= 0;
					font_mem_en <=0;
				end
			endcase
end

always @ (posedge clk)
begin
	case (pix_x[2:0])
	3'b000: out_vga <= line[7];
	3'b001: out_vga <= line[6];
	3'b010: out_vga <= line[5];
	3'b011: out_vga <= line[4];
	3'b100: out_vga <= line[3];
	3'b101: out_vga <= line[2];
	3'b110: out_vga <= line[1];
	3'b111: out_vga <= line[0];
	endcase
end

endmodule