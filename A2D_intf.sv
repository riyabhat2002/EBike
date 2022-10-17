module A2D_intf(clk,rst_n, batt, curr, brake, torque, SS_n, SCLK, MOSI, MISO);

input clk,rst_n;
input MISO;
output logic [11:0] batt;
output logic [11:0] curr;
output logic [11:0] brake;
output logic [11:0] torque;
output logic SS_n, SCLK, MOSI;

// Declaring the signals needed for the interface
logic snd;
logic [15:0] cmd;
logic done;
logic cnv_cmplt;
logic [15:0] resp;
logic [1:0] rr_counter;
logic [13:0] wait_cnt;

// Instantiating the SPI_mnrch DUT
SPI_mnrch iDUT(.clk(clk), .rst_n(rst_n), .snd(snd), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .cmd(cmd), .done(done), .resp(resp));

// creating the enumerated types for the different states of the state machine
typedef enum logic [1:0] {IDLE, REQ, WAIT, RESP} state_t;
state_t curr_state, next_state;

// Assigning the value for cmd
assign cmd = (rr_counter == 2'b00)? {2'b00,3'b000,11'h000} :
	       (rr_counter == 2'b01)? {2'b00, 3'b001, 11'h000} :
	       (rr_counter == 2'b10)? {2'b00, 3'b011, 11'h000} :
		 {2'b00, 3'b100, 11'h000};

// Round robin counter
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		rr_counter <= 2'b00;
	else if(cnv_cmplt)
		rr_counter <= rr_counter + 1;
end

// set the values of batt, brake, curr, and torque based on the round robin counter
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		batt  <= 12'h000;		
		curr  <= 12'h000;
		brake <= 12'h000;
		torque  <= 12'h000;
	end
	else if(cnv_cmplt) begin
		if(rr_counter == 2'b00)
			batt <= resp[11:0];
		else if(rr_counter == 2'b01)
			curr <= resp[11:0];
		else if(rr_counter == 2'b10)
			brake <= resp[11:0];
		else 
			torque <= resp[11:0];
	end
end	

// waiting for 16,384 clock cycles
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		wait_cnt <= 14'h0000;
	else
		wait_cnt <= wait_cnt + 1;
end	

always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		curr_state <= IDLE;
	else
		curr_state <= next_state;
end

// STATE MACHINE
always_comb begin

	// Setting the default values
	cnv_cmplt = 1'b0;
	snd = 1'b0;
	case(curr_state)
		IDLE: begin 
			next_state = (&wait_cnt) ? REQ : IDLE;
			snd = (&wait_cnt);
		end
		REQ: begin
			next_state = (done) ? WAIT : REQ;
		end
		WAIT:	begin
			next_state = RESP;
			snd = 1'b1;
		end
		RESP: begin
			next_state = (done) ? IDLE : RESP;
			cnv_cmplt = done;
		end
	endcase

end

endmodule

