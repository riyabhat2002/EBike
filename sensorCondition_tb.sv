module sensorCondition_tb();

// Declaring the signals needed for the sensorCondition DUT
logic [11:0] torque,curr,batt;
logic cadence_raw,not_pedaling,clk,rst_n,TX;
logic [12:0] incline,error;
logic [2:0] scale;

// instantiating the sensorCondition DUT
sensorCondition iDUT(.*);

initial begin 
	//initial values
	clk = 0;
	rst_n = 0;
	torque = 12'h123;
	cadence_raw = 0;
	curr = 12'h321;
	incline = 13'h123;
	scale = 3'h9;
	batt = 12'h123;


	@(posedge clk)
	@(negedge clk)
	rst_n = 1;

	repeat(500000) @(posedge clk);
	$display("finish");	
	$stop();
	

end 

always #5 clk <= ~clk;
always #20480 cadence_raw <= ~cadence_raw;


endmodule 
