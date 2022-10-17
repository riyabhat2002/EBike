module rst_synch(clk, RST_n, rst_n);

input clk, RST_n;
output logic rst_n;

logic q1;
// synchronize reset
always_ff@(negedge clk, negedge RST_n)
	if(!RST_n) begin
		q1 <= 0;
	end
	else begin 
		q1 <= 1'b1;
		rst_n <= q1;
	end
endmodule
		
