module alu (
	input clk,
	input [15:0] a,
	input [15:0] b,
	input [7:0] op,
	input cf,
	output c_flag,
	output z_flag,
	output o_flag,
	output [15:0] acc
	output [15:0] c;);

	reg [15:0] acc;
	assign z_flag = acc[15:0] == 0;
	assign o_flag = c_flag ^ acc[15];
	//assign value  = acc;

	parameter xADD = 8'h1;
	parameter xADC = 8'h2;
	parameter xSUB = 8'h3;
	parameter xSUC = 8'h4;
	parameter xMUL8 = 8'h5;
	parameter xMUL6 = 8'h6;
	parameter xDIV8 = 8'h7;
	parameter xDIV6 = 8'h8;
	parameter xCMP = 8'h9;

	parameter xAND = 8'hA;
	parameter xNEG = 8'hB;
	parameter xNOT = 8'hC;
	parameter xOR = 8'hD;
	parameter xSHL = 8'hE;
	parameter xSHR = 8'hF;
	parameter xXOR = 8'h10;
	parameter xTEST = 8'h11;
  
	always @(posedge clk) begin
		case (op)
			xADD: {c_flag, acc} <= {a[15], a} + {b[15], b};
			xADC: {c_flag, acc} <= {a[15], a} + {b[15], b} + cf;
			xSUB: {c_flag, acc} <= {a[15], a} + {!b[15], ~b};
			xSUC: {c_flag, acc} <= {a[15], a} + {!b[15], ~b} + !cf;
			xMUL8: acc <= a[7:0] * b[7:0];
			xMUL6: {c, acc} <= a * b;//to kiedys jebnie
			xDIV8: acc <= a[7:0] / b[7:0];
			xDIV6: {c, acc} <= a / b;//to tez kiedys jebnie :/
			xCMP: begin
				if (a==b) acc <= 0;//trzeba pilnowac w cpu
				if (a<b) c_flag <= 1;//pilnowac
				if (a>b) begin//a to juz w ogole jebnie
					acc <= 16'hFF;
					c_flag <= 0;
				end
			end
			
			xAND: acc <= a & b;
			xNEG: acc <= ~a;
			xNOT: acc <= !a;
			xOR: acc <= a | b;
			xSHL: acc <= a << 1;
			xSHR: acc <= a >> 1;
			xXOR: acc <= a ^ b;
			xTEST: acc <= !(a && b);//moze
		endcase
	end
endmodule