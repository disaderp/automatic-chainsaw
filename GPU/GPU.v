module GPU(
input clk,
input [15:0] cpuline,
input clr,
output outvga, output hsync, output vsync
);

		
wire [7:0] out;
wire [9:0] pix_x;	//pixel vertical location
wire [9:0] pix_y;
reg [15:0] cmd = 0;
reg [15:0] param = 0;
reg [7:0] ram [11:0];
reg [11:0] pointer = 0;
reg [11:0] tmpx = 0;
reg [11:0] tmpy = 0;
reg nopstate = 0;
reg [15:0] nextcmd = 0;
reg [6:0] i;

wire [7:0] ascii;
wire [11:0] asciiaddress;
wire font_mem_en;
wire dis_mem_en;

wire vgaclock;
//VGAclk clk2(.CLK_IN1(clk), .CLK_OUT1(vgaclock));

TXT d0 (
		//.clk (vgaclock),
		.clk(clk),
		.reset (clr),
		.vga_out (outvga),
		.char_line_data (out),
		.ascii_address (asciiaddress),
		.font_mem_en (font_mem_en),
		.disp_mem_en (dis_mem_en),
		.pix_x(pix_x),
		.pix_y(pix_y),
		.hsync(hsync),
		.vsync(vsync)
		);

font_rom f_rom0 (
		.clk (font_mem_en),
		.address ({ascii[6:0], pix_y[3:0], !pix_x[3]}),
		.out (out)
		);

dispram d_ram0(
	.clk(dis_mem_en),
	.address(asciiaddress),
	.out(ascii));

always @(posedge clk) begin : main

		case (cmd)
			16'h0: begin
				if (!nopstate) begin
					nextcmd <= cpuline;
					nopstate <= 1;
				end
				else begin
					cmd <= nextcmd;
					param <= cpuline;
					nopstate <= 0;
				end
			end
			16'hC0: begin
				if (param == 0) begin
					for (i=0; i<8; i=i+1) ram[i] <= 2'b00;
					pointer <=0;
					tmpy <=0;
					tmpx <=0;
				end
				else begin
					//graphical mode
				end
				cmd <= 0;
			end
			16'hC1: begin
				ram[pointer] <= param;
				pointer <= pointer + 1;
				if(tmpx > 12'd38) begin//0..39
					if(tmpy > 12'd23) //0..24
						tmpy <= 0;
					else tmpy <= tmpy + 1;
					tmpx <= 0;
				end
				else tmpx <= tmpx + 1;
				cmd <= 16'h0;
			end
			16'hC2: begin
				ram[pointer - 1] <= 8'h0;
				pointer <= pointer - 1;
				if(tmpx == 12'h0) begin
					tmpx <= 12'd39;
					tmpy <= tmpy - 1;
				end
				else tmpx <= tmpx - 1;
				cmd <= 16'h0;
			end
			16'hC3: begin
				tmpy <= param;
				pointer <= (param << 5) + (param << 3) + tmpx;//Y*40 +x
				cmd <= 16'h0;
			end
			16'hC4: begin
				tmpx <= param;
				pointer <= (tmpy << 5) + (tmpy << 3) + param;//X*40 +y
				cmd <= 16'h0;
			end
			16'hC5: begin
				for (i=0; i<8; i=i+1) ram[i] <= 2'b00;
				pointer <= 0;
				tmpx <= 0;
				tmpy <= 0;
				cmd <= 16'h0;
			end
			16'hC6: begin
				if(tmpy > 12'd23) begin//0..24
					pointer <= 0;//not the best solution
					tmpx <= 0;
					tmpy <= 0;
				end
				else begin
					tmpx <= 0;
					tmpy <= tmpy + 1;
					pointer <= ((tmpy+1) << 5) + ((tmpy+1) << 3);//*40
					end
				cmd <= 16'h0;
			end
		endcase
end
	
endmodule