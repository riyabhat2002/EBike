module PID(clk, rst_n, error, not_pedaling, drv_mag);
input clk, rst_n, not_pedaling;
input [12:0] error;
output logic [11:0]drv_mag;

// declearing the internal signals
logic signed [13:0] p_term, PID, PID_pf, PID_of;
logic [11:0] i_term;
logic signed [9:0] d_term;
logic [17:0] error_extend, integrator, adder, adder2, adder3, integrator_in, integrator_input;
logic [19:0] decimator;
logic signed [12:0] d1read, d2read, d3read,d1,d2, prev_error, d_diff, d_diff_pf;
logic decimator_full;
parameter FAST_SIM = 1;

// assigning the p term
assign p_term = {error[12], error};

// assigning the i terms
//sign extend error to 4 addition
assign error_extend = {{5{error[12]}}, error};
assign adder = error_extend + integrator;
//checking for negative term
assign adder2 = (adder[17]) ? 18'h00000 : adder;
// checking overflow
assign adder3 = (adder[17] && integrator[16]) ? 18'h1ffff : adder2;
// waiting for hthe counter
assign integrator_in = (decimator_full) ? adder3 : integrator;
// checking non pedaling
assign integrator_input = (not_pedaling) ? 18'h00000: integrator_in;

// flopped for area
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		integrator <= 0;
	else
		integrator <= integrator_input;

assign i_term = integrator[16:5];


/////////////////////// D_term /////////////////////////

// waiting for 3/48 seconds for D term
assign d1read = (decimator_full) ? error : d1;

// flopping to wait for the counter
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		d1 <= 0;
	else 
		d1 <= d1read;

assign d2read = (decimator_full) ? d1 : d2;
always_ff @(posedge clk, negedge rst_n) 
	if(!rst_n)
		d2 <= 0;
	else 
		d2<= d2read;
assign d3read = (decimator_full) ? d2 : prev_error;
always_ff @(posedge clk, negedge rst_n) 
	if(!rst_n)
		prev_error <= 0;
	else 
		prev_error <= d3read;


assign d_diff_pf = error - prev_error;
//flop for area
always @(posedge clk)
	d_diff <= d_diff_pf;
// saturation and multiplied by 2
assign d_term = (!d_diff[12]) ? (|d_diff[11:9] ? 9'h0FF : d_diff[9:0]<<1) : (|(~d_diff[11:9]) ? d_diff[9:0]<<1 : 9'h100);
// puttign everything together
assign PID_pf = p_term + {{2{1'b0}},i_term} + {{4{d_term[9]}},d_term};

// flop for area
always @(posedge clk)
	PID <= PID_pf;
	
// checking for overflow 
assign PID_of = (PID[12]) ? 12'hFFF : PID[11:0];
assign drv_mag = (PID[13]) ? 12'h000 : PID_of;
		
//counter	
always_ff @(posedge clk,negedge rst_n) begin
	if(!rst_n)
		decimator <= '0;
	else 
		decimator <= decimator + 1;
end

// generating FAST_SIM
generate if(FAST_SIM)
	assign decimator_full = &decimator[13:0];
	else
	assign decimator_full = &decimator;
endgenerate

endmodule 
