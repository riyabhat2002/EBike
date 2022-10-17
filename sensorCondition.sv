module sensorCondition
	#(parameter FAST_SIM = 1)
(
	input clk,
	input rst_n,
	input [11:0] torque,
	input cadence_raw,
	input [11:0] curr,
	input signed [12:0] incline,
	input [2:0] scale,
	input [11:0] batt,
	output [12:0] error,
	output not_pedaling,
	output TX
);

	// declaring internal signals
	localparam LOW_BATT_THRES = 12'hA98; // lower threshold for battery

	logic [11:0] target_curr;	// output of desired drive
	logic [11:0] avg_curr;		// output of expo accum
	logic [11:0] avg_torque;	// output of expo accum
	logic cadence_filt, cadence_rise; // ouptut of cadence_filt
	logic [7:0] cadence_per;	// output of cadence_meas
	logic [4:0] cadence;		// output of LU table
	
	// timer for including sample in accumalator
	logic [21:0] timer22;
	logic include_smpl;
	
	// torque accumlator
	logic [16:0] meas_val_curr_torque;
	logic [21:0] product_curr_torque;
	logic pedaling_resumes;
	logic pedaling_resumes_1;
	logic [16:0] accum_torque;
	
	// current accumalator	
	logic [13:0] meas_val_curr;
	logic [15:0] product_curr;
	logic [13:0] accum_curr;


	// instantiate modules needed in sensorCondition
	telemetry iTEL(batt, avg_curr, avg_torque, clk, rst_n, TX);
	
	desiredDrive iDUT(avg_torque,cadence,not_pedaling, incline,scale,target_curr,clk);
	
	cadence_filt #(.FAST_SIM(FAST_SIM)) iCAD(clk, rst_n, cadence_raw, cadence_filt, cadence_rise);
	cadence_meas  #(.FAST_SIM(FAST_SIM))iCADm(cadence_rise, clk, rst_n, not_pedaling, cadence_per);
	cadence_LU iLU(cadence_per, cadence);

	
	// clock to trigger include_smpl
	generate if (FAST_SIM)
		assign include_smpl = &timer22[15:0];
	else 
		assign include_smpl = &timer22;
	endgenerate
	// clock to trigger include_smpl
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			timer22 <= 22'h000000;
		else
			timer22 <= timer22 + 1;

	// assign error to 0 if batt is lesser than threshold or pedaling
	assign error = ((batt < LOW_BATT_THRES) || not_pedaling) ? 0 : (target_curr - avg_curr);
	
	// rising edge detecter for not_pedaling
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			pedaling_resumes_1 <= 1'b0;
		else
			pedaling_resumes_1 <= not_pedaling;
	end
	assign pedaling_resumes = (~not_pedaling) & pedaling_resumes_1;

	// torque accumalator
	assign product_curr_torque = ((accum_torque << 5) - accum_torque);

	assign meas_val_curr_torque= product_curr_torque[21:5] + torque;

	always_ff@(posedge clk, negedge rst_n)begin
		if(!rst_n)
			accum_torque <= 17'h00000;
		else if(pedaling_resumes) 
			accum_torque <= {1'b0, torque, 4'h0};
		else if (cadence_rise)
			accum_torque <= meas_val_curr_torque;
	
	end
	assign avg_torque = accum_torque[16:5];
	
		
	// current accumalator

	assign product_curr = ((accum_curr << 2) - accum_curr);

	assign meas_val_curr= product_curr[15:2] + curr;


	always_ff@(posedge clk, negedge rst_n)begin
		if(!rst_n)
			accum_curr <= 14'h0000;
		else if (include_smpl)	
			accum_curr <= meas_val_curr;
	end

	assign avg_curr = accum_curr[13:2];
	

endmodule
