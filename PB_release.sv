module PB_rise(clk, rst_n, PB, released);

input clk, rst_n;
input PB;
output logic released;

logic q1,q2,q3;

// flopping for metastability
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n) begin
		q1 <= 1;
		q2 <= 1;
		q3 <= 1;
	end
	else begin 
		q1 <= PB;
		q2 <= q1;
		q3 <= q2;
	end
//checking for rising edge
and iAND(released, ~q3, q2);
endmodule