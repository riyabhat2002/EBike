module PID_tb ();
  //testbench for PID(checking waveform)
  logic clk, rst_n, not_pedaling;
  logic [12:0] error;
  logic [11:0] drv_mag;
  logic test_over;
  //initializing DUT
  PID iPID (
      clk,
      rst_n,
      error,
      not_pedaling,
      drv_mag
  );
  plant_PID iplant (
      clk,
      rst_n,
      drv_mag,
      error,
      not_pedaling,
      test_over
  );

  //checking waveform after test_over is active high
  initial begin
    clk   = 0;
    rst_n = 0;
    @(negedge clk);
    rst_n = 1;

    @(posedge test_over);
    $display("lol");

    $stop();
  end

  always #5 clk <= ~clk;
endmodule
