module dispram(
input clk,
input [11:0] address,
output reg [7:0] out);

reg [7:0] dispram [4095:0];

initial begin : once
	dispram[0] <= 8'b00000000;
end

always @(posedge clk) begin
	out <= dispram[address];
end

endmodule