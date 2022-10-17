module brushless(
	input clk,
	input rst_n,
	input [11:0] drv_mag,
	input hallGrn,
	input hallYlw,
	input hallBlu,
	input brake_n,
	input PWM_synch,
	output [10:0] duty,
	output [1:0] selGrn,	
	output [1:0] selYlw,
	output [1:0] selBlu
);
	typedef enum logic [1:0] {HIGH_Z, rev_curr, for_curr, regen_braking} coil_state;
	
	coil_state coilGrn, coilYlw, coilBlu;

	logic [2:0] rotation_state;
	logic synchGrn, g1, g2;
	logic synchBlu, b1, b2;
	logic synchYlw, y1, y2;

// for metastability reasons
	always_ff @(posedge clk) begin
		g1 <= hallGrn;
		g2 <= g1;
		b1 <= hallBlu;
		b2 <= b1;
		y1 <= hallYlw;
		y2 <= y1;
	end

// Synchronizing Hall sensors to our clock domain
	always @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			synchGrn <= 0;
			synchYlw <= 0;
			synchBlu <= 0;
		end
		else if (PWM_synch) begin
			synchGrn <= g2;
			synchBlu <= b2;
			synchYlw <= y2;
		end
	end
	// in accordance with specifications
	assign rotation_state = {synchGrn, synchYlw, synchBlu};

	always_comb begin
		if (!brake_n) begin
// brake case
			coilGrn = regen_braking;
			coilBlu = regen_braking;
			coilYlw = regen_braking;
		end
		else begin
		case (rotation_state)
			// case 1 
			3'b101: begin
				coilGrn = for_curr;
				coilYlw = rev_curr;
				coilBlu = HIGH_Z;
			end
			// case 2
			3'b100: begin
				coilGrn = for_curr;
				coilYlw = HIGH_Z;
				coilBlu = rev_curr;
			end
			// case 3
			3'b110: begin
				coilGrn = HIGH_Z;
				coilYlw = for_curr;
				coilBlu = rev_curr;
			end
			// case 4
			3'b010: begin
				coilGrn = rev_curr;
				coilYlw = for_curr;
				coilBlu = HIGH_Z;
			end
			// case 4
			3'b011: begin
				coilGrn = rev_curr;
				coilYlw = HIGH_Z;
				coilBlu = for_curr;
			end
			// case 5
			3'b001: begin
				coilGrn = HIGH_Z;
				coilYlw = rev_curr;
				coilBlu = for_curr;
			end
			// def case
			default: begin
				coilGrn = HIGH_Z;
				coilYlw = HIGH_Z;
				coilBlu = HIGH_Z;
			end

		endcase
		end
	end
	assign selGrn = coilGrn;
	assign selYlw = coilYlw;
	assign selBlu = coilBlu;
	
	assign duty = (brake_n)? drv_mag[11:2] + 11'h400 : 11'h600;
	

endmodule
