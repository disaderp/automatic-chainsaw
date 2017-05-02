module RAM(
    input [11:0] ADDR1,
    input [11:0] ADDR2,
    input [11:0] ADDR3,
    input [11:0] ADDR4,
    input [11:0] ADDW1,
    input [15:0] DATA,
    input WREN,
    output [15:0] DATA1,
    output [15:0] DATA2,
    output [15:0] DATA3,
    output [15:0] DATA4,
    input clk);
    
    blockram r1(.addrb(ADDR1), .clka(clk), .clkb(clk), .addra(ADDW1), .wea(WREN), .dina(DATA), .doutb(DATA1));
    blockram r2(.addrb(ADDR2), .clka(clk), .clkb(clk), .addra(ADDW1), .wea(WREN), .dina(DATA), .doutb(DATA2));
    blockram r3(.addrb(ADDR3), .clka(clk), .clkb(clk), .addra(ADDW1), .wea(WREN), .dina(DATA), .doutb(DATA3));
    blockram r4(.addrb(ADDR4), .clka(clk), .clkb(clk), .addra(ADDW1), .wea(WREN), .dina(DATA), .doutb(DATA4));
endmodule