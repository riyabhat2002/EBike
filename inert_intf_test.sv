//Testbench for inert_intf used with the board
module inert_intf_test (
    RST_n,
    clk,
    LED,
    SS_n,
    SCLK,
    MISO,
    MOSI,
    INT
);
  // input for reset_synch and inert_intf
  input RST_n, clk, INT, MISO;
  output logic SS_n, SCLK, MOSI;
  output logic [7:0] LED;

  logic rst_n, vld;
  logic [12:0] incline;
  // initialize all DUT
  reset_synch iRST (.*);
  inert_intf iDUT (.*);
  // LED taking the incline values with the vld signal as the enable signal
  always_ff @(posedge clk)
    if (vld) LED <= incline[8:1];
    else LED <= LED;

endmodule
