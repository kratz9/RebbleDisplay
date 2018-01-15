`timescale 1 ns / 1 ps

module rebble_display_tb();

   wire reset, cs, miso, mosi, sck, reset_done, intn;
 

   rebble_display DUT (
		       .reset(reset),
		       .cs(cs),
		       .miso(miso),
		       .mosi(mosi),
		       .sck(sck),
		       .reset_done(reset_done),
		       .intn(intn)
		       );
   
		       
   initial begin
      reset = 1'b0;
      cs    = 1'b1;
      miso  = 1'b0;
      mosi  = 1'b0;
      sck   = 1'b0;
      reset_done = 1'b0;
      intn  = 1'b0;

      #10;
      cs    = 1'b0; //Enable CS
      #80;
      
      reg [7:0] cmd_frame = 8'h05; //Draw frame command

      for(i = 0; i < 8; i=i+1) begin
	 mosi = cmd_frame[i];
	 #10;
	 sck = 1'b1;
	 #10;
	 sck = 1'b0;
	 #10;	 	 
      end

      cs = 1'b1;

      //Ready to send image data
      reg [7:0] display_rows =  8'd168;
      reg [7:0] display_cols =  8'd144;

      reg [7:0] pixel_value = 8'h00;

      
      for(i=0; i<display_rows; i=i+1) begin
	 for(j=0; j<display_cols; j=j+1) begin
	    if(j[0] == 1)
	      pixel_value = 8'hFF;
	    
	   
	
       
	
   end
      
      
      
