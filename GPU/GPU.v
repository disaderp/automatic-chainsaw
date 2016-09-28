module GPU(
input clk,
input reset,
input [15:0] cpuline
input clr,
input dat,
input pixh,
input pixv,
input adress,
output out_vga,
output dis_mem_en,
output font_mem_en,
output asciiadress,
output hsync,
output vsync,
output dis_en,
output out
//@todo: wypisac wszystkie inputy i outputy z nizszych modulow)
);

//zainicjowac TXT podpiac sygnaly, zainscjonac FOnt rom
TXT d0 (
		.clk (clk),
		.clr (clr),
		.pixh (pixh),
		.pixv (pixv),
		.dat (dat),
		.out_vga (out_vga),
		.asciiadress (asciiadress),
		.font_mem_en (font_mem_en),
		.dis_mem_en (dis_mem_en)
		);
VGA z0 (
		.clk (clk),
		.clr (clr),
		.dat (dat),
		.vsync (vsync),
		.hsync (hsync),
		.pixv (pixv),
		.pixh (pixh),
		.dis_en (dis_en)
		);
font_rom x0 (
		.adress (adress),
		.out (out)
		);
		
reg [15:0] cmd;
reg [15:0] param;

reg [11:0] ram [7:0];
reg [11:0] pointer;//=0

reg [11:0] tmpx;//char //=0
reg [11:0] tmpy;//line //=0
reg nopsate;//inicjalizacja 0
reg [15:0] nextcmd;
//@todo: blok reset always//patrz cpu.v//zainicjum cmd=0;
always @ (posedge clk) begin: clr
	if (clr) disable clr
	cpuline <= 0;
	dat <= 0;
	pixh <= 0;
	pixv <= 0;
	out_vga <= 0;
	dis_mem_en <= 0;
	font_mem_en <= 0;
	hsync <= 0;
	vsync <=0;
	asciiadress <=0;
	dis_en <= 0;
	adress <=0;
	out <=0;
	end
	
always @(posedge clk) begin : main
//@todo: disaable
	case (cmd) begin
		16'h0: begin
			if (!nopstate) begin
				nextcmd <= cpuline;
				nopstate <= 1;
			else begin
				cmd <= nextcmd;
				param <= cpuline;
				nopstate <= 0;
			end
		end
		16'hC0: begin
			//@TODO: zerowanie wszyzstkiego znowu oprzuz niektorych rezcyz wiadomo jakis
		end
		16'hC1: begin
			ram[pointer] <= param;
			pointer <= pointer + 1;
			if(tmpx > 12'd38) begin//0..39
				if(tmpy > 12'd23) //0..24
					tmpy <= 0;
				else tmpy <= tmpy + 1;
				tmpx <= 0;
			else tmpx <= tmpx + 1;
			cmd <= 16'h0;
		end
		16'hC2: begin
			ram[pointer - 1] <= 8'h0;
			pointer <= poiner - 1;
			if(tmpx == 12'h0) begin
				tmpx <= 12'd39;
				tmpy <= tmpy - 1;
			else tmpx <= tmpx - 1;
			cmd <= 16'h0;
		end
		16'hC3: begin
			tmpy <= param;
			pointer = (param << 5) + (param << 3) + tmpx;//Y*40 +x
			cmd <= 16'h0;
		end
		16'hC4 begin
			tmpx <= param;
			pointer = (tmpy << 5) + (tmpy << 3) + param;//X*40 +y
			cmd <= 16'h0;
		end
		16'hC5 begin
			//if SYSTEMVERILOG
			ram <= '{default:2'b00};
			//else
				//for (i=0; i<8; i=i+1) ram[i] <= 2'b00;
			//endif
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
			else begin
				tmpx <= 0;
				tmpy = tmpy + 1;
				pointer = (tmpy << 5) + (tmpy << 3);//*40
				end
			cmd <= 16'h0;
		end
	
	end
	
endmodule