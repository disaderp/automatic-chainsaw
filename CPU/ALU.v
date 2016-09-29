module dALU (
	input clk,
	input [15:0] a,
	input [15:0] b,
	input [7:0] op,
	input cf,
	output c_flag,
	output z_flag,
	output o_flag,
	output [15:0] acc,
	output [15:0] c);
	
	reg c_flag;
	reg [15:0] c;
	reg [15:0] acc;
	reg o_flag;
	reg z_flag;
	
	parameter xADD = 8'h1;
	parameter xADC = 8'h2;
	parameter xSUB = 8'h3;
	parameter xSUC = 8'h4;
	parameter xMUL8 = 8'h5;
	parameter xMUL6 = 8'h6;
	parameter xDIV8 = 8'h7;
	parameter xDIV6 = 8'h8;
	parameter xCMP = 8'h9;
	
	always @(posedge clk) begin
		case (op)
			xADD: begin {c_flag, acc} = {a[15], a} + {b[15], b}; o_flag = c_flag ^ acc[15]; z_flag = acc[15:0] == 0;end
			xADC: begin {c_flag, acc} = {a[15], a} + {b[15], b} + cf; o_flag = c_flag ^ acc[15]; z_flag = acc[15:0] == 0;end
			xSUB: begin {c_flag, acc} = {a[15], a} - {b[15], b}; o_flag = c_flag ^ acc[15]; z_flag = acc[15:0] == 0;end
			xSUC: begin {c_flag, acc} = {a[15], a} - {b[15], b} - cf; o_flag = c_flag ^ acc[15]; z_flag = acc[15:0] == 0;end
			xMUL8: begin acc = a[7:0] * b[7:0]; z_flag = acc[15:0] == 0;end
			xMUL6: begin {c, acc} = a * b; z_flag = acc[15:0] == 0;end
			xDIV8: begin acc = a[7:0] / b[7:0]; z_flag = acc[15:0] == 0;end
			xDIV6: begin {c, acc} = a / b; z_flag = acc[15:0] == 0;end
			xCMP: begin
				if (a==b) begin z_flag = 1; c_flag = 0; o_flag = 0; end
				if (a<b) begin z_flag = 0; c_flag = 1; o_flag = 0; end
				if (a>b) begin z_flag = 0; c_flag = 0; o_flag = 1; end
			end
		endcase
	end
endmodule