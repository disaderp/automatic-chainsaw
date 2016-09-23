module font_rom(
input clk,
input [11:0] address,
output [7:0] out);

reg [7:0] font_rom [11:0];
reg [7:0] out;

font_rom[0] <= ;

always @(posedge clk) begin
	out <= font_rom[address];
end

endmodule