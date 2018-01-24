`timescale 1 ns / 1 ps

module rebble_screen
  (
   parameter CLOCK_PERIOD= 500; //nS
   parameter LINES       = 148;
   parameter COLUMNS     = 205;
   
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
   // States
   parameter 
     IDLE   =4'h0,
     START  =4'h1,
     VSTART =4'h2,
     VSTART2=4'h3,
     VCLK1  =4'h4,
     HSTART =4'h5,
     HSTART2=4'h6,
     HSTART3=4'h7,
     HSTART4=4'h8,
     HRUN   =4'h9,
     HWAIT  =4'hA,
     HEND   =4'hB,
     VEND   =4'hC

   //Timings - nS  
   parameter 
     XRST_DELAY = 10000  /CLOCK_PERIOD,
     VST_DELAY  = 10000  /CLOCK_PERIOD,
     VST_LENGTH = 119700 /CLOCK_PERIOD,
     VCK_DELAY  = 4000   /CLOCK_PERIOD,
     VCK_PERIOD = 111700 /CLOCK_PERIOD,
     HST_DELAY  = 5000   /CLOCK_PERIOD,
     HCK_DELAY  = 1000   /CLOCK_PERIOD,
     HCK_PERIOD = 950    /CLOCK_PERIOD,
     ENB_DELAY  = 30000  /CLOCK_PERIOD,
     ENB_PERIOD = 51700  /CLOCK_PERIOD,
     DATA_DELAY = 480    /CLOCK_PERIOD,
     VCOM_PERIOD= 8330000/CLOCK_PERIOD,
     ;
   
   
   wire 	    lcd_clk;
   assign lcd_clk = clock;
   
   reg 		    draw;   
   
   reg 		    vck_en;
   reg 		    hck_en;
   reg [7:0] 	    row;
   reg [7:0] 	    col;   

   reg [15:0] 	    clkdiv;
   reg [15:0] 	    vcomclk_div;
   reg [15:0] 	    enbclk_div;
    	    
   reg [3:0] 	    state;

   reg [15:0] vckdiv;
   reg [15:0] hckdiv;

   reg 	      vckreset;
   reg 	      hckreset;
   reg 	      linereset;
   reg 	      colreset;
   reg 	      enbflg;
   
   
   wire	      nvck;   //Inverted signal needed to clock on both edges
   wire       nhck;
   
   assign nvck = ~vck;
   assign nhck = ~hck;
   
   
   always @(posedge lcd_clk)
     begin
	if(vckreset)
	  begin
	     vck <= 1'b1;
	     vckdiv <= 0;
	     vckreset <= 1'b0;
	     linereset <= 1'b1;	  
	     enb <= 1'b0;	 
             enbflg <= 1'b0;    
	  end	
	if(vck_en)
	  begin
	    vckdiv <= vckdiv + 1;	
	    if(vckdiv >= VCK_PERIOD)
	      begin
	         vckdiv <= 0;
	         vck <= ~vck;
		 enbclk_div <= 1'b0;
                 enbflg <= 1'b1	 
	      end
            else if(enbflg = 1'b1 and enbclk_div >= ENB_DELAY)
	      begin
		 enb <= 1'b1;
		 enbclk_div <= 0;
		 enbflg <= 1'b0;		 
	      end
	    else if(enb = 1'b1 and enbclk_div >= ENB_PERIOD)
	      begin
		 enb <= 1'b0;
		 enbclk_div <= 0;
	      end	     
	    else
	      begin
		 vckdiv <= vckdiv + 1;
		 enbclk_div <= enbclk_div +1;		 
	      end	     
	  end
	if(hckreset)
	  begin
	     hck <= 1'b1;
	     hckdiv <= 0;
	     hckreset <= 1'b0;
	  end	     
	if(hck_en)
	  begin
	     hckdiv <= hckdiv + 1;
	     if(hckdiv >= HCK_PERIOD)
	       begin
		  hckdiv <= 0;
		  hck <= ~hck;
	       end   
     end // always @ (posedge lcd_clk)

	
   always @(posedge vck or posedge nvck)
     begin
	if(linereset)
	  begin
             line <= 0;
	     linereset <= 1'b0;
	  end	     
	if(nvck = 1'b1)
	  begin	    
             line <= line + 1;
	  end
     end // always @ (posedge vck or posedge nvck)

   always @(posedge hck or posedge nhck)
     begin
	if(colreset)
	  begin
	     col <= 0;
	     colreset <= 1'b0;
	  end
	else
	  begin
	     col <= col + 1;
	  end
     end // always @ (posedge hck or posedge nhck)
   
 
   
   //State
   always @(posedge lcd_clk)
     begin	
	case(state)
	  IDLE:
	    if(draw = 1'b1)
	      begin
		 //TODO: Reset all regs
		 state <= START;
	      end	  
	  START:
	    if(clkdiv >= XRST_DELAY)	      
	      begin
		 xrst <= 1'b1;	      
		 clkdiv <= 0;
		 state <= VSTART;
	      end
	    else
	      clkdiv <= clkdiv + 1;
	  VSTART:
	    if(clkdiv >= VST_DELAY)
	      begin
		 vst <= 1'b1;
		 clkdiv <=0;
		 state <= VSTART2;
	      end
	    else
	      clkdiv <= clkdiv + 1;
	  VSTART2:
	    if(clkdiv >= VCK_DELAY)
	      begin
		 clkdiv <= 0;		 
		 vck_en <= 1'b1;
		 vckreset <= 1'b1;
		 state <= VCLK1;
	      end
	    else
	      clkdiv <= clkdiv + 1;
	  VCLK1:
	    if(line=1)
	      begin
		 clkdiv <= 0;		 
                 vst <= 1'b0;
		 state <= HSTART;		 
	      end
	  HSTART:
	    if(clkdiv >= HST_DELAY)
	      begin
		 clkdiv <= 0;
		 hst <= 1'b1;
		 vst <= 1'b0;
		 state <= HSTART2;
	      end
	    else
	      clkdiv <= clkdiv +1;
	  HSTART2:
	    if(clkdiv >= HCK_DELAY)
	      begin
		 hckreset <= 1'b1;		 
		 hck_en <= 1'b1;
		 clkdiv <= 0;
		 state <= HSTART3;
	      end
	    else
	      clkdiv <= clkdiv +1;
	  HSTART3:
	    if(col=1)
	      begin
		 state <= HSTART4;
	      end
	  HSTART4:
	    if(clkdiv >= HST_DELAY)
	      begin
		 hst <= 0;
		 clkdiv <= 0;
		 state <= HRUN;
	      end
	    else
	      clkdiv <= clkdiv + 1;
	  HRUN:
	    if(hckdiv > DATA_DELAY)
	      begin
		 //TODO: APPLY DATA
		 state <= HWAIT;
	      end     	  
	  HWAIT:
	    if(hckdiv < DATA_DELAY)
	      begin
		 if(row >=(ROWS/2)+1 and hck = 0)
		   begin
		      hck_en <= 1'b0;
		      state <= HEND;		      
		   end
		 else
		   state <= HRUN;
	      end
	  HEND:
	    if(vckdiv = 0 and line <= LINES)
	      begin
		 state = HSTART;
	      end
	    else if(vckdiv = 0 and line > LINES)
	      begin
		 vck_en <= 1'b0;
		 state <= VEND;
		 clkdiv <= 0;		 
	      end
	  VEND:
	    if(clkdiv >= XRST_DELAY)
	      begin
		 //TODO: Make sure all signals are reset
		 xrst <= 1'b0;		 
		 clkdiv <= 0;
		 state <= IDLE;		 
	      end
	end // always @ (posedge lcd_clk)
   

   //TODO: Handle ENB signal		 
		 
		
	     
	       
   //TODO: VCOM, RFP, XRFP
   always @(posedge ldc_clk)
     begin
	if(vcomclk_div = 0)
	  begin
	     vcom <= ~vcom;
             frp <= ~frp;
             xfrp <= frp;	     
	     vcomclk_div <= VCOM_PERIOD;
	  end
	else
	  vcomclk_div <= vcomclk_div - 1
     end
   	     
		     

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
	    
