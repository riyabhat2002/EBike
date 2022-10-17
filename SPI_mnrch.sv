///////////////////////////////////////////////////////////////////////
// SPI monarch module that transmits and receives 16-bit packets    //
// cmd[15:0] is 16-bit packet that goes out on MOSI,               //
// resp[15:0] is the 16-bit word that came back on MISO.          //
// snd is control signal to initiate a transaction. done is      //
// asserted when transaction is complete. SCLK is currently set //
// for 1:32 of clk (3.2MHz).                                   //
////////////////////////////////////////////////////////////////

module SPI_mnrch(clk,rst_n,SS_n,SCLK,MISO,MOSI,snd,done,resp,cmd);

  input clk,rst_n;						// clk and active low asynch reset
  input snd,MISO;						// initiate transaction with snd
  input [15:0] cmd;						// command/data to serf
  output reg SS_n, done;				// both done and SS_n implemented as set/reset flops
  output SCLK,MOSI;
  
  output [15:0] resp;					// parallel data of MISO from serf

  typedef enum reg[1:0] {IDLE,BITS,TRAIL} state_t;
  
  state_t state,nstate;			// declare enumerated states
  reg [4:0] SCLK_div;
  reg [4:0] bit_cntr;
  reg [15:0] shft_reg;			// stores the output to be serialized on MOSI
  
  ///////////////////////////////////
  // SM outputs are of type logic //
  /////////////////////////////////
  logic init;
  logic set_done, ld_SCLK_div;
  
  //////////////////////////
  // Internal signals //
  /////////////////////
  logic shft, SCLK_fall_imminent;

  ///////////////////////////////
  // Implement state register //
  /////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      state <= IDLE;
    else
      state <= nstate;

 //////////////////////////////////////////
  // Implement parallel to serial shift //
  // register who's MSB forms MOSI     //
  //////////////////////////////////////
  always_ff @(posedge clk)
	if (init)
      shft_reg <= cmd;
    else if (shft)
      shft_reg <= {shft_reg[14:0],MISO};

  ////////////////////////////
  // Implement bit counter //
  //////////////////////////
  always_ff @(posedge clk)
    if (init)
      bit_cntr <= 5'b00000;
    else if (shft)
      bit_cntr <= bit_cntr + 1'b1;

  //////////////////////////////
  // Implement pause counter //
  ////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  SCLK_div <= 5'b10111;
	else if (ld_SCLK_div)
      SCLK_div <= 5'b10111;
    else
      SCLK_div <= SCLK_div + 1'b1;

  assign SCLK = SCLK_div[4];		// div 32, SCLK normally high
  assign shft = (SCLK_div==5'b10001) ? 1'b1 : 1'b0;	// 2 clks after SCLK rise
  assign SCLK_fall_imminent = &SCLK_div;	// SPI transaction over if last bit
  
  ///////////////////////////////////////////
  // done implemented as a set/reset flop //
  /////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  done <= 1'b0;
	else if (set_done)
	  done <= 1'b1;
	else if (init)
	  done <= 1'b0;
	  
  ////////////////////////////////////////////////////////
  // SS_n very similar to done except it is reset high //
  //////////////////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  SS_n <= 1'b1;
	else if (set_done)
	  SS_n <= 1'b1;
	else if (init)
	  SS_n <= 1'b0;
	  
  ////////////////////////////////////////
  // Implement SM that controls output //
  //////////////////////////////////////
  always_comb
    begin
      //////////////////////
      // Default outputs //
      ////////////////////
      init = 0; 
      set_done = 0;
	  ld_SCLK_div = 0;
	  
	  nstate = IDLE;

      case (state)
        IDLE : begin
		  ld_SCLK_div = 1;
          if (snd) begin
		    init = 1;
            nstate = BITS;
		  end
        end
        BITS : begin
          ////////////////////////////////////
          // For the 16 bits of the packet //
          //////////////////////////////////
		  if (bit_cntr[4])
		    nstate = TRAIL;
          else
            nstate = BITS;         
        end
        default : begin 	// this is TRAIL state
          /////////////////////////////////////////////////////////
          // This state keeps SS_n low for a while (back porch) //
          ///////////////////////////////////////////////////////
          if (SCLK_fall_imminent)
		    begin
			  nstate = IDLE;
			  ld_SCLK_div = 1;	// inhibit fall of SCLK
			  set_done = 1;
			end
		  else
		    nstate = TRAIL;
        end
      endcase
    end
  
  assign resp = shft_reg;		// when finished shft_reg will contain data read from serf
  assign MOSI = shft_reg[15];

endmodule 
