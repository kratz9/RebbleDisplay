`timescale 1 ns / 1 ps

module rebble_screen
  (
   parameter CLOCK_PERIOD=500;
   /* Master clock */
   input wire 	    clock;
   
   /* MCU Side */
   input wire 	    reset,
   input wire 	    cs,
   output wire 	    miso
   input wire 	    mosi,
   input wire 	    sck,
	 
   output wire 	    reset_done,
   output wire 	    intn,

   /* LDC Side */
   output reg [1:0] red; //Set data .47uS before HCK edge
   output reg [1:0] green; //Data read on both HCK edges
   output reg [1:0] blue; //Data MSB and LSB are separate lines

   output reg 	    hck; //Horizontal Clock period 1.9uS
   output reg 	    vck; //Vertical Clock period 223.4uS
   output reg 	    vst; //Assert once per fram 4uS before VCK to 4uS after VCK
   output reg 	    xrst; //Assert for full frame 33.32ms
   output reg 	    enb; //Assert 30uS after VCK, low for 30uS till VCK end
   output reg 	    hst; //2.4uS pulse at line start
   
   output reg 	    vcom; //60hz continuous
   output reg 	    rfp; //same as VCOM
   output reg 	    xrfp;    //inverse of VCOM

   /*
    
   LDC INTERFACE TIMING DIAGRAM
    
   XRST  ___|````````````````````````````````````````````````|_____
   VST   _____|`````````|__________________________________________
   VCK   _______|`````|_____|`````|_____|`````|_____|`````|________
   ENB   _____________________|`|___|`|___|`|___|`|___|`|___|`|____ 
   DATA  _____________|XXXXX|XXXXX|XXXXX|XXXXX|XXXXX|XXXXX|XXXXX|__
    
    
   VCK   ____|``````````````````````````````````````````````````|_____
   ENB   ______________________|`````````````````|____________________
   HST   _______|```````````|_________________________________________
   HCK   __________|`````|_____|`````|_____|`````|_____|`````|________ 
   DATA  ___________________|XXXXX|XXXXX|XXXXX|XXXXX|XXXXX|___________ 
    */
   
   );


   reg [5:0] 	    pixel_in;
   reg [14:0] 	    pixel_waddr;
   reg 		    pixel_write_en;
   reg 		    pixel_wclk;
   reg [5:0] 	    pixel_out;
   reg [14:0] 	    pixel_raddr;
   reg 		    pixel_read_en;
   reg 		    pixel_rclk;
     
   
   
   ram frame_buffer (
		     .din(pixel_in),
		     .wadd(pixel_waddr),
		     .write_en(pixel_write_en),
		     .wclk(pixel_wclk),
		     .dout(pixel_out),
		     .raddr(pixel_raddr),
		     .read_en(pixel_read_en),
		     .rclk(pixel_rclk)
		     );
   


   // LCD CONSTANTS
   parameter IDLE=2'h0;

   parameter VCK_PERIOD = 223;
   
   wire 	    lcd_clk;

   reg 		    vck_en;
   reg 		    hck_en;

   reg [15:0] 	    clkdiv;
   
   always @(posedge ldc_clk)
     begin
	clkdiv <= clkdiv + 1;
	if(clkdiv > 
   

   always @(posedge ldc_clk)
     begin
	
		     
		     

endmodule; // rebble_screen


module ram #(dataw = 6, addrw = 15)
(	    
    input wire [dataw-1:0] din;
    input wire [addrw-1:0] waddr;
    input wire write_en;
    input wire wclk;

    input wire [dataw-1:0] dout;
    input wire [addrw-1:0] raddr;
    input wire read_en;
    input wire rclk;
)

  reg [dataw-1:] memory [(1<<addrw)-1:0];
   
		     
always @(posedge rclk)
  begin
     if(write_en)
       dout <= memory[raddr];
  end

   always@(posedge wclk)
     begin
	if(read_en)
	  memory[waddr] = din;
     end
   


endmodule; // ram
	    
