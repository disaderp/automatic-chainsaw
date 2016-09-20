module testbench();

	reg [15:0] a;
	reg [15:0] b;
	reg [7:0] op;
	reg cf;
	reg clk; 
	wire c_flag;
	wire z_flag;
	wire o_flag;
	wire [15:0] acc;
	wire [15:0] c;
	
	alu d0 (
		.clk (clk),
		.a(a),
		.b(b),
		.op(op),
		.cf(cf),
		.c_flag(c_flag),
		.z_flag(z_flag),
		.o_flag(o_flag),
		.acc(acc),
		.c(c)
	);
	
	
	initial begin
		$monitor ("%g\t a=%b b=%b op=%h cf=%b coz=%b%b%b acc=%b c=%b",
		$time, a, b, op, cf, c_flag, o_flag, z_flag, acc, c);
		clk = 1;
		a = 16'd10;
		b = 16'd11;
		op = 8'h2;
		cf = 1;
		#15 $finish;
	end
	  
	always begin
		#5 clk =~clk;
	end
	
endmodule