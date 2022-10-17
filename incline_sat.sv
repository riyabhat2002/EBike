module incline_sat(
	input signed [12:0] incline,
	output signed [9:0] incline_sat
);
	assign incline_sat = (&incline[12:9] || ~|incline[12:9]) ? incline[9:0] : // checking if incline can be expressed in 10 bits
			     (incline[12] == 1'b1) ? 10'b1000000000 : 10'b0111111111;	// set to max or min possible value if cannot be expressed

endmodule
