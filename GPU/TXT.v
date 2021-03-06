// Module SEQUENCER
//
// Author: Goran Devic 
// https://baltazarstudios.com/poem-fpga/
//
// Sequences the ASCII character data from display ROM, through the font ROM, and out
// as a monochrome wire data

module TXT (
 
input clk,                    // Input 25.175 MHz clock, this is a pixel clock for this VGA mode
input reset,                     // Input async. active low reset signal
 
output [9:0] pix_x,               // The exact X coordinate of a pixel that is currently being drawn
output [9:0] pix_y,               // The exact Y coordinate of a pixel that is currently being drawn
 
output reg[11:0] ascii_address,  // Address into memory containing a current character code
input [7:0] char_line_data,      // Currect character single line data (8 bit at a time)
 
output reg vga_out,              // Final VGA out signal (monochrome)
 
output reg disp_mem_en,          // Enable display memory to read
output reg font_mem_en,           // Enable font memory to read

output hsync, output vsync
);

VGA vga0 (
		.clk (clk),
		.pixv (pix_x),
		.pixh (pix_y),
		.hsync(hsync),
		.vsync(vsync)
		);
 

 
reg [7:0] line_data;             // Current character line data shifter
reg [11:0] xp = 0;                   // Temp
reg [11:0] yp = 0;                   // Temp
 
always @( posedge clk or negedge reset )
begin
   if (!reset) begin
      line_data <= 0;            // Do a mandatory reset of all registers
      ascii_address <= 0;
      disp_mem_en <= 0;
      font_mem_en <= 0;
   end else begin
      ascii_address <= 0;
      // The sequence of getting a pixel to display is clocked by pix_x[2:0]
      // Font it 16x16 pixels, that is two 8-bit words for each line
      case (pix_x[2:0])
         // State 1: send the address of a character to pick up onto the
         //          address bus of the display ROM. Enable both memories
         //          so the output of the first one propagates to the second one
         //          and make it output a line of character definition
         3'b110:  begin
               // Calculate the address within the display memory of a current
               // character based on the current pixel X and Y coordinates
               // There are 40 chars/line, hence multiply Y by 40
               xp[11:0] <= { 6'd0, pix_x[9:4] };
               yp[11:0] <= { 6'd0, pix_y[9:4] };
               ascii_address[11:0] <= (yp << 5) + (yp << 3) + xp;
               //ascii_address[11:0] <= xp + yp * 40;
               
               disp_mem_en <= 1;
               font_mem_en <= 1;         
            end
         // State 2: At this time clock the outputs of both memories should have
         //          stabilized and we can read a line of character definition
         3'b111:  begin
               line_data <= char_line_data;
            end
         // State 3: This is timed to coencide with pix'000 when a new character
         //          line is going to be displayed (@always loop below).
         //          Disable outputs of display and font memories for now
         3'b000:  begin
               font_mem_en <= 0;
               disp_mem_en <= 0;
            end
      endcase
   end
end
 
always @( posedge clk )
begin
   // Depending on the position of a current character pixel, display individual pixels
   // using a buffer that was loaded in a state machine (@always loop above)
   case (pix_x[2:0])
      3'b000:  vga_out <= line_data[7];
      3'b001:  vga_out <= line_data[6];
      3'b010:  vga_out <= line_data[5];
      3'b011:  vga_out <= line_data[4];
      3'b100:  vga_out <= line_data[3];
      3'b101:  vga_out <= line_data[2];
      3'b110:  vga_out <= line_data[1];
      3'b111:  vga_out <= line_data[0];
      endcase
end
 
endmodule