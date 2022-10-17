module mtr_drv(
	input clk,
	input rst_n,
	input [10:0] duty,
	input [1:0] selGrn,
	input [1:0] selYlw,
	input [1:0] selBlu,
	output highYlw,
	output lowYlw,
	output highGrn,
	output lowGrn,
	output highBlu,
	output lowBlu,
	output PWM_synch
);

logic PWM_sig;

logic highGrnIn, lowGrnIn, highYlwIn, lowYlwIn, highBluIn, lowBluIn;

// create non overlap safety blocks for each of the coils
nonoverlap iGrn(clk, rst_n, highGrnIn, lowGrnIn, highGrn, lowGrn);
nonoverlap iYlw(clk, rst_n, highYlwIn, lowYlwIn, highYlw, lowYlw);
nonoverlap iBlu(clk, rst_n, highBluIn, lowBluIn, highBlu, lowBlu);

// used to convert duty into a PWM signal
PWM11 iPWM(clk, rst_n, duty, PWM_sig, PWM_synch);

// create muxes for high Grn for various input signals
always_comb begin
	if(selGrn == 2'b00)
		highGrnIn = 1'b0;
	else if (selGrn == 2'b01)
		highGrnIn = ~PWM_sig;
	else if (selGrn == 2'b10)
		highGrnIn = PWM_sig;
	else
		highGrnIn = 1'b0;
end

// create muxes for low Grn for various input signals
always_comb begin
	if(selGrn == 2'b00)
		lowGrnIn = 1'b0;
	else if (selGrn == 2'b01)
		lowGrnIn = PWM_sig;
	else if (selGrn == 2'b10)
		lowGrnIn = ~PWM_sig;
	else
		lowGrnIn = 1'b0;
end


// create muxes for high Ylw for various input signals
always_comb begin
	if(selYlw == 2'b00)
		highYlwIn = 1'b0;
	else if (selYlw == 2'b01)
		highYlwIn = ~PWM_sig;
	else if (selYlw == 2'b10)
		highYlwIn = PWM_sig;
	else
		highYlwIn = 1'b0;
end

// create muxes for low Ylw for various input signals
always_comb begin
	if(selYlw == 2'b00)
		lowYlwIn = 1'b0;
	else if (selYlw == 2'b01)
		lowYlwIn = PWM_sig;
	else if (selYlw == 2'b10)
		lowYlwIn = ~PWM_sig;
	else
		lowYlwIn = 1'b0;
end

// create muxes for high Blu for various input signals
always_comb begin
	if(selBlu == 2'b00)
		highBluIn = 1'b0;
	else if (selBlu == 2'b01)
		highBluIn = ~PWM_sig;
	else if (selBlu == 2'b10)
		highBluIn = PWM_sig;
	else
		highBluIn = 1'b0;
end

// create muxes for low Blu for various input signals
always_comb begin
	if(selBlu == 2'b00)
		lowBluIn = 1'b0;
	else if (selBlu == 2'b01)
		lowBluIn = PWM_sig;
	else if (selBlu == 2'b10)
		lowBluIn = ~PWM_sig;
	else
		lowBluIn = 1'b0;
end


endmodule
