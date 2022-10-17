module nonoverlap (
	input clk,
	input rst_n,
	input highIn,
	input lowIn,
	output logic highOut,
	output logic lowOut
);

	logic [4:0] deadTime;	// timer to count 32 clock cycles
	logic qhigh, qlow, qhighT, qlowT; // used to double flop inputs
	logic diff; // is asserted when hiighIn or lowIn change

	// creates flops to double flop highIn and lowIn
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			qhigh <= 1'b0;
			qlow <= 1'b0;	
			qhighT <= 1'b0;
			qlowT <= 1'b0;	
			
		end
		else begin
			qhigh <= qhighT;
			qlow <= qlowT;
			qhighT <= highIn;
			qlowT <= lowIn;
		end
	end

	// resets timer if reset of if highIn or lowIn changes else increments it
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) 
			deadTime <= 5'h00;
		else if(diff) 
			deadTime <= 5'h00;
		else 
			deadTime <= deadTime +1;
	end
	// clears the output flops when reset asserted or when highIn or lowIn change and sets them to input when timer is full
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			highOut <= 1'b0;
			lowOut <= 1'b0;
		end		
		else if(diff) begin
			highOut <= 1'b0;
			lowOut <= 1'b0;

		end 
		else if(&deadTime) begin
			highOut <= highIn;
			lowOut<= lowIn;
		end
	end

	always_comb
		diff <= (qhigh != highIn || qlow != lowIn);	// is asserted when hiighIn or lowIn change

endmodule
