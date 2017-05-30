
// Module VGA_SYNC
//
// Generates output sync signals to drive VGA display in 640x480 pixel mode:
//
// Refresh rate:    60 Hz
// Vert. refresh:   31.46 kHz
// Pixel frequency: 25.175 MHz
//
//    Horizontal timing (pixels)  Vertical timing (pixels)
// Visible area:          640          480
// Front porch:            16           10
// Sync pulse:             96            2
// Back porch:             48           33
// Whole line:            800          525

module VGA (

input clk,                    // Input 25.175 MHz clock, this is a pixel clock for this VGA mode

output reg hsync,            // Output horizontal sync signal
output reg vsync,            // Output vertical sync signal

//output reg disp_enable,          // Set when a writable portion of display is enabled:
output reg[9:0] pixh,           //  x-coordinate of an active pixel
output reg[9:0] pixv            //  y-coordinate of an active pixel
);


localparam SYNC_ON  = 1'b0;      // Define the polarity of sync pulses
localparam SYNC_OFF = 1'b1;

reg[9:0] line_count = 0;             // Line counter, current line
reg[9:0] pix_count = 0;              // Pixel counter, current pixel

always @( posedge clk)
begin

   
      pix_count <= pix_count + 1;// Increment a pixel counter every clock time!

      // This is a state machine based on a pixel count. Since VGA modes timings are
      // based on a multiple of pixel counts, we add them up and generate syncs at
      // proper times
      case (pix_count)
         0:    hsync <= SYNC_OFF;
         16:   hsync <= SYNC_ON;
         112:  hsync <= SYNC_OFF;
         800: begin
               line_count <= line_count + 1;
               pix_count <= 0;
            end
      endcase
      
      // Properly toggle vertical sync based on the current line count
      case (line_count)
         0:    vsync <= SYNC_OFF;
         10:   vsync <= SYNC_ON;
         12:   vsync <= SYNC_OFF;
         525: begin
               line_count <= 0;
            end
      endcase

      // The following code defines a drawable display region and outputs
      // disp_enable to 1 when within that region. Also, set the pixel coordinates
      // (normalized to the top-left edge of a drawable region)
      //disp_enable <= 0;
      pixh <= 0;
      pixv <= 0;
      if (line_count>=35 && line_count<515)
      begin
         if (pix_count>=160 && pix_count<800)
         begin
        //    disp_enable <= 1;
            pixh <= pix_count - 10'd160;
            pixv <= line_count - 10'd35;
         end
      end
end

endmodule