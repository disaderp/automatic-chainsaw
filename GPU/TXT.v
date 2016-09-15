// jeszcze nie wiem jak to działa, będę musiał to jeszcze raz przenanalizowac i zrozumieć co napisałem XD

module text(
input clk,
input [9:0] hcounter, 
input [9:0] vcounter,
input [7:0} dat,
output out_vga, //vga output
output [11:0] char, 

output reg dis_mem_en,
output reg font_mem_en
);

reg [8:0] line;
reg [11:0] hp;
reg [11:0] vp;

always @ (posedge clk or negedge reset)
begin
	if (!reset) begin
		char <= 0;
		line <= 0;
	end else begin
		char <= 0;
		case (hcounter[2:0])
		3'b110: begin
			hp[11:0] <= { 6'd0, hcounter[9:4] };
			vp[11:0] <= { 6'd0, vcounter[9:4] };
			char[11:0] <= hp + vp * 40;
			dis_mem_en <=1;
			font_mem_en <= 1;
	end
	
		3'b111: begin
		line <= char;
	end
	3'b000: begin
		dis_mem_en <= 0;
		font_mem_en <=0;
	endcase
	end
end

always @ (posedge clk)
begin
	case (hcounter[2:0)
	3'b000: out_vga <= line[7];
	3'b001: out_vga <= line[6];
	3'b011: out_vga <= line[5];
	3'b010: out_vga <= line[4];
	3'b110: out_vga <= line[3];
	3'b111: out_vga <= line[2];
	3'b101: out_vga <= line[1];
	3'b100: out_vga <= line[0];
	endcase
end

endmodule
