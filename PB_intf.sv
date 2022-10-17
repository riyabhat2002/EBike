module PB_intf(tgglMd, clk, rst_n, scale, setting);
input tgglMd, clk, rst_n;
output [2:0] scale;
output logic [1:0] setting;

logic tmdetect, f1, f2, f3;

//flopping for meta stability
always_ff @(posedge clk) begin
	f1 <= tgglMd;
	f2 <= f1;
	f3 <= f2;
end
// checking for a rising edge
assign tmdetect = (~f3 & f2);

// when rising edge is dectected we increment the setting
// 00=>off, 01=>low assist, 10=>medium assist, 11=> max assist
always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
		setting <= 2'b10;
	else if(tmdetect)
		setting <= setting + 1;

// assign scale based on setting
assign scale = (setting[1]) ? (setting[0] ? 3'b111 : 3'b101) : (setting[0] ? 3'b011 : 3'b000);

endmodule
