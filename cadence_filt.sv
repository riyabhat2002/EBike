module cadence_filt
	#(parameter FAST_SIM = 1)
(
	input clk,
	input rst_n,
	input cadence,
	output logic cadence_filt,
	output logic cadence_rise
);

	// Initialize the internal flip flops
	reg f1, f2, f3, f4;
	// Initialize the 16 bit counter needed
	reg [15:0] counter;
	
	logic f4_val;
	
	generate if (FAST_SIM) begin
		assign f4_val = (&counter[8:0]) ? f3 : cadence_filt;
	end
	else begin
		assign f4_val = (&counter) ? f3: cadence_filt;
	end
	endgenerate
	logic chng;
	always @(posedge clk, negedge rst_n) begin
	// asynch reset clears all flip flops and register
		if(!rst_n) begin
			f1 <= 1'b0;
			f2 <= 1'b0;
			f3 <= 1'b0;
			f4 <= 1'b0;
		end
		else begin
		// for metastability reasons
			f1 <= cadence;
			f2 <= f1;
			f3 <= f2;
		// if counter not reached max value then signal has not been stable for a long while 
			f4 <= f4_val;
		end
	end
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			counter <= 16'h0000;
		else if (chng)
			counter <= counter+1;
		else
			counter <= 16'h0000;
	end
	
	always_comb begin
		cadence_rise = f2 & ~f3;	
		cadence_filt = f4;
		chng = ~(f2^f3);
	end
endmodule


	