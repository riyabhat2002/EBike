module PWM11(
	input clk,
	input rst_n,
	input [10:0] duty,
	output logic PWM_sig,
	output logic PWM_synch
);
	logic q;	// used to flop PWM_sig
	logic [10:0] cnt;	// timer used to keep track of clock cycles passed
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			cnt <= 11'h000;
			q <= 1'b0;		
		end	
		else begin
			q <= (cnt  <= duty);	// drops PWM_sig when timer crosses duty time units value
			cnt <= (cnt + 1'b1);	// increments timer every clock cycle
		end
	end
	always_comb
		PWM_sig = q;
	
	always_comb	
		PWM_synch = (cnt == 11'h001);	// sets PWM_synch to one clock cycle after whenever timer starts			

endmodule
