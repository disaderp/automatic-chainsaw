// jeszcze nie wiem jak to działa, będę musiał to jeszcze raz przenanalizowac i zrozumieć co napisałem XD

module text(
input clk,		//clock
input clr,		//clear
input [9:0] pixh, 	//pixel localization
input [9:0] pixv,	//pixel localization
input [7:0} dat,	//data
output out_vga, //vga output
output reg [11:0] ascii, 	//idk

output reg dis_mem_en,		//enables display memory
output reg font_mem_en		//enables font memory
);

reg [8:0] line;		//sth
reg [11:0] hp;		//sth else
reg [11:0] vp;		//sth else2

always @ (posedge clk or negedge clr)
begin
	if (clr = 1)		//reset of all registers 
		begin	
		ascii <= 0;
		line <= 0;
		dis_mem_en <= 0;
		font_mem_en <= 0;
	end 
		else 
		begin
			ascii <= 0;
				case (pixh[2:0])
					3'b110: begin
					hp[11:0] <= { 6'd0, pixh[9:4] };
					vp[11:0] <= { 6'd0, pixv[9:4] };
					ascii[11:0] <= hp + vp * 40;
					dis_mem_en <=1;
					font_mem_en <= 1;
				end
	
				3'b111: begin
				line <= ascii;
			end
				3'b000: begin
				dis_mem_en <= 0;
				font_mem_en <=0;
		endcase
	end
end

always @ (posedge clk)
begin
	case (pixh[2:0)
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
