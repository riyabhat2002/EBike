module desiredDrive(avg_torque, cadence, not_pedaling, incline, scale, target_curr, clk);

input clk;
input [11:0] avg_torque;
input [4:0] cadence;
input not_pedaling;
input signed[12:0] incline;
input [2:0] scale;
output [11:0] target_curr;

// Declaring all the signals needed for the Drive
 
localparam TORQUE_MIN = 12'h380;
logic [12:0]torque_off;
logic [11:0] torque_pos;
logic [29:0] assist_prod;
logic [5:0] cadence_factor;
logic [9:0] incline_sat;
logic [10:0] incline_factor;
logic [8:0] incline_lim;
logic [14:0] assist_prod_temp1;
logic [14:0] assist_prod_temp2;
logic [14:0] assist_prod_temp1_flop;
logic [14:0] assist_prod_temp2_flop;
incline_sat iSaturate(.incline(incline), .incline_sat(incline_sat));

assign incline_factor = {incline_sat[9],incline_sat} + 256;

assign incline_lim =    (incline_factor[10]) ? 9'b000000000 :
			(incline_factor[9]) ? 9'b111111111 :
                         incline_factor[8:0];

// We are finding the offset of the average torque from the minimum torque

assign torque_off = avg_torque - TORQUE_MIN;

// We don't want the offset to be negative so if the offset is negative we saturate it zero

assign torque_pos = (torque_off[12] == 1'b1) ? 12'h000 : torque_off[11:0];

assign cadence_factor = (|cadence[4:1] == 1'b1) ? cadence + 32 : 6'b000000;

assign assist_prod_temp1 =  torque_pos * scale;

assign assist_prod_temp2 =  incline_lim * cadence_factor;


// Target current is the current required for the drive to run
always @(posedge clk) begin
	assist_prod <= (not_pedaling) ? 30'h00000000 : (assist_prod_temp1_flop * assist_prod_temp2_flop );
	assist_prod_temp1_flop <= assist_prod_temp1;
	assist_prod_temp2_flop <= assist_prod_temp2;
end
assign target_curr = (|assist_prod[29:27]) ? 12'hFFF : assist_prod[26:15];

endmodule

