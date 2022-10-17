module telemetry(
	input [11:0] batt_v,
	input [11:0] avg_curr,
	input [11:0] avg_torque,
	input clk,
	input rst_n,
	output TX
);

	// define all the states
	typedef enum logic [3:0] {IDLE, DELIM1, DELIM2, BATT_h, BATT_l, CURR_h, CURR_l, TOR_h, TOR_l} state_t;

	// 20 bit timer
	logic [19:0] timer;
	logic tx_done, trmt; // trmt is asserted whenever a new byte is to be transmitted by iUART
	logic [7:0] tx_data;
	logic trmt_wire;
	state_t nxt_state, curr_state;

	// initialise UART transmitting module
	UART_tx iUART(clk,rst_n,TX,trmt_wire,tx_data,tx_done);


	
	always_ff @(posedge clk, negedge rst_n) 
		if(!rst_n) begin	// reset the timer, current state and trmt
			timer <= 20'h00000;
			curr_state <= IDLE;
			trmt <= 1'b0;
		end
		else begin
			timer <= timer + 1;
			curr_state <= nxt_state;
			trmt <= trmt_wire;
		end
	assign trmt_wire = (nxt_state != curr_state); // combinational logic for trmt stored in trmt_wire

	// define state transitions 
	always_comb begin
		case(curr_state)
			IDLE: begin 
				nxt_state = (~|timer) ? DELIM1 : IDLE;
				tx_data = (~|timer) ? 8'hAA : 8'hFF;
			end
			DELIM1: begin
				nxt_state = (tx_done) ? DELIM2 : DELIM1;
				tx_data = (tx_done) ? 8'h55 : 8'hAA;
			end
			DELIM2: begin
				nxt_state = (tx_done) ? BATT_h : DELIM2;
				tx_data = (tx_done) ? {4'h0, batt_v[11:8]} : 8'h55;
			end
			BATT_h: begin
				nxt_state = (tx_done) ? BATT_l : BATT_h;
				tx_data = (tx_done) ? batt_v[7:0] : {4'h0, batt_v[11:8]};
			end
			BATT_l: begin
				nxt_state = (tx_done) ? CURR_h : BATT_l;
				tx_data = (tx_done) ? {4'h0, avg_curr[11:8]} : {batt_v[7:0]};
			end
			CURR_h: begin
				nxt_state = (tx_done) ? CURR_l : CURR_h;
				tx_data = (tx_done) ? avg_curr[7:0] : {4'h0, avg_curr[11:8]};
			end
			CURR_l: begin
				nxt_state = (tx_done) ? TOR_h : CURR_l;
				tx_data = (tx_done) ? {4'h0, avg_torque[11:8]} : avg_curr[7:0];
			end
			TOR_h: begin
				nxt_state = (tx_done) ? TOR_l : TOR_h;
				tx_data = (tx_done) ? avg_torque[7:0] : {4'h0, avg_torque[11:8]};
			end
			TOR_l: begin
				nxt_state = (tx_done) ? IDLE : TOR_l;
				tx_data = (tx_done) ? 8'hFF : {avg_torque[7:0]};
			end
			default: begin
				nxt_state = IDLE;
				tx_data = 8'hFF;
			end
		endcase
	end
	

	
	
endmodule
