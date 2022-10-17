module cadence_meas
#(parameter FAST_SIM = 1)
(input cadence_rise,clk,rst_n, 
output logic not_pedaling, 
output logic [7:0] cadence_per);

//declaring the parameters

localparam THIRD_SEC_REAL = 24'hE4E1C0;
localparam THIRD_SEC_FAST = 24'h007271;
localparam THIRD_SEC_UPPER = 8'hE4;


logic [23:0] mux1,mux2,mux3,flop1,flop2,THIRD_SEC;
logic capture_per;

// On a rising edge of cadence_filt a 24-bit timer is cleared
assign mux1 = (cadence_rise) ? 0 : 
		(flop1 == THIRD_SEC) ? flop1 : flop1 + 1;
// selects the middle 8 bits of the clock if FAST_SIM is enabled
assign mux2 = (FAST_SIM) ? flop1[14:7] : flop1[23:16];

// 
assign capture_per = (flop1 == THIRD_SEC) | cadence_rise;

//
assign mux3 = (!rst_n) ? THIRD_SEC_UPPER : 
		(capture_per) ? mux2 : cadence_per;
// sets not pedaling if cadence_per is equal to THIRD_SEC_UPPER
assign not_pedaling = (THIRD_SEC_UPPER == cadence_per);

// Resetting the flop
always @(posedge clk,negedge rst_n) begin 
	if(!rst_n) 
		flop1 <= 0;
	else
		flop1 <= mux1;
end
always @(posedge clk) begin 

	cadence_per <= mux3;

end

// Generate block to change the threshold based on FAST_SIM
generate if (FAST_SIM)
	assign THIRD_SEC = THIRD_SEC_FAST;
else 
	assign THIRD_SEC = THIRD_SEC_REAL;

endgenerate

endmodule 
