module inert_intf (
    clk,
    rst_n,
    INT,
    MISO,
    SS_n,
    SCLK,
    MOSI,
    incline,
    vld
);
  ///////////////////////////////////
  // inertial sensor is a DUT that
  // determine the incline for the
  // eBike using the data provided
  // by the inertial sensor
  ///////////////////////////////////

  input clk, rst_n;
  input INT;  // active high interrupt that represent when the data is ready
  output [12:0] incline;
  output logic vld;  // valid reading is ready or not

  // SPI interface inputs and output
  input MISO;
  output SS_n, SCLK, MOSI;

  //state machine signals
  logic snd, done, INT_ff1, INT_ff2;
  logic [7:0] rollL, rollH, yawL, yawH, AYL, AYH, AZL, AZH;
  logic [15:0] cmd, timer, resp;
  //ready signals from the state machine that represent readings are done
  logic C_R_H, C_R_L, C_Y_H, C_Y_L, C_AY_H, C_AY_L, C_AZ_H, C_AZ_L;

  //state machine states
  typedef enum reg [3:0] {
    INIT1,
    INIT2,
    INIT3,
    INIT4,
    WAIT,
    READ1,
    READ2,
    READ3,
    READ4,
    READ5,
    READ6,
    READ7,
    READ8
  } state_t;
  state_t state, nxt_state;

  //initailize SPI and inertial_integrator
  SPI_mnrch iSPI (
      .clk  (clk),
      .rst_n(rst_n),
      .SS_n (SS_n),
      .SCLK (SCLK),
      .MISO (MISO),
      .MOSI (MOSI),
      .snd  (snd),
      .done (done),
      .resp (resp),
      .cmd  (cmd)
  );

  inertial_integrator iINT (
      .clk(clk),
      .rst_n(rst_n),
      .vld(vld),
      .roll_rt({rollH, rollL}),
      .yaw_rt({yawH, yawL}),
      .AY({AYH, AYL}),
      .AZ({AZH, AZL}),
      .incline(incline),
      .LED()
  );

  //eight 8 bits flops for temp value holder from inertial sensor
  always_ff @(posedge clk) if (C_R_L) rollL <= resp[7:0];

  always_ff @(posedge clk) if (C_R_H) rollH <= resp[7:0];

  always_ff @(posedge clk) if (C_Y_L) yawL <= resp[7:0];

  always_ff @(posedge clk) if (C_Y_H) yawH <= resp[7:0];

  always_ff @(posedge clk) if (C_AY_L) AYL <= resp[7:0];

  always_ff @(posedge clk) if (C_AY_H) AYH <= resp[7:0];

  always_ff @(posedge clk) if (C_AZ_L) AZL <= resp[7:0];

  always_ff @(posedge clk) if (C_AZ_H) AZH <= resp[7:0];

  //16 bits time counter for intialize the inertial sensor
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) timer <= 0;
    else timer <= timer + 1;

  //double flops the INT for meta-stability reasons
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      INT_ff1 <= 0;
      INT_ff2 <= 0;
    end else begin
      INT_ff1 <= INT;
      INT_ff2 <= INT_ff1;
    end
  end

  //state machine starts here
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) state <= INIT1;
    else state <= nxt_state;

  always_comb begin
    //initialize needed values
    snd = 0;
    cmd = 0;
    C_R_H = 0;
    C_R_L = 0;
    C_Y_H = 0;
    C_Y_L = 0;
    C_AY_H = 0;
    C_AY_L = 0;
    C_AZ_H = 0;
    C_AZ_L = 0;
    vld = 0;
    nxt_state = state;

    case (state)
      //enable interrupt upon data ready
      INIT1: begin
        cmd = 16'h0D02;
        if (&timer) begin
          snd = 1;
          nxt_state = INIT2;
        end
      end
      //setup accel for 208Hz data rate, +/- 2g accel range, 50Hz LPF
      INIT2: begin
        cmd = 16'h1053;
        if (done) begin
          snd = 1;
          nxt_state = INIT3;
        end
      end
      //setup gyro for 208 Hz data rate, +/- 2455°/sec range
      INIT3: begin
        cmd = 16'h1150;
        if (done) begin
          snd = 1;
          nxt_state = INIT4;
        end
      end
      //Turn rounding on for both accel and gyro
      INIT4: begin
        cmd = 16'h1460;
        if (done) begin
          snd = 1;
          nxt_state = WAIT;
        end
      end
      //waiting for intialization to be done and set up cmd for reading
      WAIT: begin
        cmd = 16'hA4xx;
        if (INT_ff2) begin
          nxt_state = READ1;
          snd = 1;
        end
      end
      //roll rate low
      READ1: begin
        cmd = 16'hA5xx;
        if (done) begin
          nxt_state = READ2;
          snd = 1;
          C_R_L = 1;
        end
      end
      //roll rate high
      READ2: begin
        cmd = 16'hA6xx;
        if (done) begin
          nxt_state = READ3;
          snd = 1;
          C_R_H = 1;
        end
      end
      //yaw rate low
      READ3: begin
        cmd = 16'hA7xx;
        if (done) begin
          nxt_state = READ4;
          snd = 1;
          C_Y_L = 1;
        end
      end
      //yaw rate high
      READ4: begin
        cmd = 16'hAAxx;
        if (done) begin
          nxt_state = READ5;
          snd = 1;
          C_Y_H = 1;
        end
      end
      //Acceleration in Y low
      READ5: begin
        cmd = 16'hABxx;
        if (done) begin
          nxt_state = READ6;
          snd = 1;
          C_AY_L = 1;
        end
      end
      //Acceleration in Y high
      READ6: begin
        cmd = 16'hACxx;
        if (done) begin
          nxt_state = READ7;
          snd = 1;
          C_AY_H = 1;
        end
      end
      //Acceleration in Z low
      READ7: begin
        cmd = 16'hADxx;
        if (done) begin
          nxt_state = READ8;
          snd = 1;
          C_AZ_L = 1;
        end
      end
      //Acceleration in Z high
      READ8: begin
        if (done) begin
          nxt_state = WAIT;
          snd = 1;
          vld = 1;
          C_AZ_H = 1;
        end
      end
      //default to initialization
      default: begin
        nxt_state = INIT1;
      end

    endcase
  end

endmodule
