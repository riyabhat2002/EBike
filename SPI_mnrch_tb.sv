module SPI_mnrch_tb();
	// declaring the internal signals
	logic clk, rst_n, SS_n, SCLK, MISO, MOSI, snd, done;
	logic [15:0] cmd;
	logic [15:0] resp;
	// instantiating the modules needed for SPI
	SPI_mnrch iDUT(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .snd(snd), .done(done), .cmd(cmd), .resp(resp));
	ADC128S iADC(clk,rst_n,SS_n,SCLK,MISO,MOSI);
	
	int hasFailed = 0;

	initial begin
	//initial values
		clk = 1'b0;
		#10;
		rst_n = 1'b0;
		#5;
		rst_n = 1'b1;
		cmd = {2'b00,3'b001,11'h000};
		snd = 1'b1;
		#10;
		snd = 1'b0;
		@(posedge done);
		if( resp != 16'h0c00) begin
			$display("Test 1 failed!");
			hasFailed = 1;
		end
			
		#200;
		cmd = {2'b00,3'b001,11'h000};
		snd = 1'b1;
		#10;
		snd = 1'b0;
		@(posedge done);
		if( resp != 16'h0c01) begin
			$display("Test 2 failed!");
			hasFailed = 1;
		end
		#200;
		cmd = {2'b00,3'b100,11'h000};
		snd = 1'b1;
		#10;
		snd = 1'b0;
		@(posedge done);
		if( resp != 16'h0bf1) begin
			$display("Test 3 failed!");
			hasFailed = 1;
		end
		#200;
		cmd = {2'b00,3'b100,11'h000};
		snd = 1'b1;
		#10;
		snd = 1'b0;
		@(posedge done);
		if( resp != 16'h0bf4) begin
			$display("Test 4 failed!");
			hasFailed = 1;
		end
		if(!hasFailed)
			$display("yahooooo! tests passed");
		$stop();
		
	end
  	always
    		#5 clk = ~clk;
endmodule
