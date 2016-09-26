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

reg [11:0] tmpx;//char //=0
reg [11:0] tmpy;//line //=0
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
			tmpx <= tmpx + 1;
			cmd <= 16'h0;
		end
		16'hC2: begin
			ram[pointer - 1] <= 8'h0;
			pointer <= poiner - 1;
			tmpx <= tmpx - 1;
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
			if(tmpy > 24) begin
				pointer <= 0;
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