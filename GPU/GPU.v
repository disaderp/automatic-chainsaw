module GPU(
input clk,
input reset,
input [15:0] cpuline
//@todo: wypisac wszystkie inputy i outputy z nizszych modulow)
);

//zainicjowac TXT podpiac sygnaly, zainscjonac FOnt rom

reg [15:0] cmd;
reg [15:0] param;

reg [11:0] ram [7:0];
reg [11:0] pointer;//=0

reg nopsate;//inicjalizacja 0
reg [15:0] nextcmd;
//@todo: blok reset always//patrz cpu.v//zainicjum cmd=0;
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
			cmd <= 16'h0;
		end
		16'hC2: begin
			//@TODO: ksaowanie i pointer wycofac
			cmd <= 16'h0;
		end
		16'hC3: begin
			//@TODO: Disa
			cmd <= 16'h0;
		end
		16'hC4 begin
			//@TODO: Disa
			cmd <= 16'h0;
		end
		16'hC5 begin
			//kasuj wsyzskto
			cmd <= 16'h0;
		end
		16'hC6: begin
			//@TODO: Disa
			cmd <= 16'h0;
		end
	
	end
	
endmodule