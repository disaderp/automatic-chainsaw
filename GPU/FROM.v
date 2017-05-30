module font_rom(
input clk,
input [11:0] address,
output reg [7:0] out);

FROM rom(.addra(address), .clka(clk), .douta(out));

//Source file: Untitled.raw
//Size: 65536 bytes

//Output file: Untitled.raw.dat
//ASCII 0x00 ' '

endmodule