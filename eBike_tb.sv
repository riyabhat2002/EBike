
module eBike_tb();
 
  // include or import tasks?
  import eBike_tester::*;

  localparam FAST_SIM = 1;		// accelerate simulation by default

  ///////////////////////////
  // Stimulus of type reg //
  /////////////////////////
  reg clk,RST_n;
  reg [11:0] BATT;				// analog values
  reg [11:0] BRAKE,TORQUE;		// analog values
  reg tgglMd;					// push button for assist mode
  reg [15:0] YAW_RT;			// models angular rate of incline (+ => uphill)


  //////////////////////////////////////////////////
  // Declare any internal signal to interconnect //
  ////////////////////////////////////////////////
  wire A2D_SS_n,A2D_MOSI,A2D_SCLK,A2D_MISO;
  wire highGrn,lowGrn,highYlw,lowYlw,highBlu,lowBlu;
  wire hallGrn,hallBlu,hallYlw;
  wire inertSS_n,inertSCLK,inertMISO,inertMOSI,inertINT;
  wire cadence;
  wire [1:0] LED;			// hook to setting from PB_intf
  
  wire signed [11:0] coilGY,coilYB,coilBG;
  logic [11:0] curr;		// comes from hub_wheel_model
  wire [11:0] BATT_TX, TORQUE_TX, CURR_TX;
  logic vld_TX;
  
  //////////////////////////////////////////////////
  // Instantiate model of analog input circuitry //
  ////////////////////////////////////////////////
  AnalogModel iANLG(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
                    .MISO(A2D_MISO),.MOSI(A2D_MOSI),.BATT(BATT),
		    .CURR(curr),.BRAKE(BRAKE),.TORQUE(TORQUE));

  ////////////////////////////////////////////////////////////////
  // Instantiate model inertial sensor used to measure incline //
  //////////////////////////////////////////////////////////////
  eBikePhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(inertSS_n),.SCLK(inertSCLK),
	             .MISO(inertMISO),.MOSI(inertMOSI),.INT(inertINT),
		     .yaw_rt(YAW_RT),.highGrn(highGrn),.lowGrn(lowGrn),
		     .highYlw(highYlw),.lowYlw(lowYlw),.highBlu(highBlu),
		     .lowBlu(lowBlu),.hallGrn(hallGrn),.hallYlw(hallYlw),
		     .hallBlu(hallBlu),.avg_curr(curr));

  //////////////////////
  // Instantiate DUT //
  ////////////////////
  eBike #(FAST_SIM) iDUT(.clk(clk),.RST_n(RST_n),.A2D_SS_n(A2D_SS_n),.A2D_MOSI(A2D_MOSI),
                         .A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),.hallGrn(hallGrn),
			 .hallYlw(hallYlw),.hallBlu(hallBlu),.highGrn(highGrn),
			 .lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
			 .highBlu(highBlu),.lowBlu(lowBlu),.inertSS_n(inertSS_n),
			 .inertSCLK(inertSCLK),.inertMOSI(inertMOSI),
			 .inertMISO(inertMISO),.inertINT(inertINT),
			 .cadence(cadence),.tgglMd(tgglMd),.TX(TX_RX),
			 .LED(LED));
			 
			 
  ////////////////////////////////////////////////////////////
  // Instantiate UART_rcv or some other telemetry monitor? //
  //////////////////////////////////////////////////////////
  
	
  logic set_cadence;
  logic [19:0] omega_1, omega_2;
  logic [11:0] current_1,current_2;
  logic [12:0] error;

  Tester tester;
			 
  initial begin

	tester = new();

	Initialize(clk, RST_n);
	
	//TEST 1 CHECKS IF WHEN THE BRAKES ARE APPLIED THE OMEGA AND CURRENT DROP
	BATT = 12'hB11; // sets battery above low battery threshold
	BRAKE = 12'hFFF; // desasserts brake
	TORQUE = 'h700;  // sets initial torque
	YAW_RT = 0;      // sets initial incline

	// oscillations cadence cycle at a period of 1250 clk cycles for 1250 cycles
	cadence_cycle(clk, 1250, set_cadence);

	// store initial values
	omega_1 = iPHYS.omega;
	current_1 = iDUT.iSENSORCONDITION.avg_curr;

	// asserts brake forcefully
	force iDUT.brake_n = 0;
	
	// oscillations cadence cycle at a period of 1250 clk cycles for 1250 cycles
	cadence_cycle(clk, 1250, set_cadence);

	// stores final values
	omega_2 = iPHYS.omega;
	current_2 = iDUT.iSENSORCONDITION.avg_curr;

	// compares values and runs test
	tester.testLt(omega_2, omega_1);
	tester.testLt(current_2, current_1);

	
	//TEST 2 CHECKS THAT WHEN TORQUE DECREASES SO SHOULD OMEGA AND CURR

	BATT = 12'hB11;	// sets battery above low battery threshold
	force iDUT.brake_n = 1; /// deasserts brake
	TORQUE = 'h700; // sets initial torque to non zero value
	YAW_RT = 0;	// sets intial incline to zero
	
	// oscillations cadence cycle at a period of 1250 clk cycles for 1250 cycles
	cadence_cycle(clk, 1250, set_cadence);

	// store initial values
	omega_1 = iPHYS.omega;
	current_1 = iDUT.iSENSORCONDITION.avg_curr;

	// set torque to a lower value
	TORQUE = 'h150;
	
	// oscillations cadence cycle at a period of 1250 clk cycles for 1250 cycles
	cadence_cycle(clk, 1250, set_cadence);
	// stores final values
	omega_2 = iPHYS.omega;
	current_2 = iDUT.iSENSORCONDITION.avg_curr;
	// compares values and runs test
	tester.testLt(omega_2, omega_1);
	tester.testLt(current_2, current_1);


	// TEST 3 CHECKS WHEN GOING FROM DOWNHILL TO UPHILL IF OMEGA INCREASES
	BATT = 12'hB11;
	BRAKE = 12'hFFF;
	TORQUE = 'h700;
	YAW_RT = 'hF000;	// incline set to a negative value to simulate going downhill

	// oscillations cadence cycle at a period of 1250 clk cycles for 1250 cycles
	cadence_cycle(clk, 1250, set_cadence);

	// store initial values
	omega_1 = iPHYS.omega;
	current_1 = iDUT.iSENSORCONDITION.avg_curr;

	// increase intial incline to a positive number to simulate going uphill
	YAW_RT = 'h3300;

	// oscillations cadence cycle at a period of 1250 clk cycles for 1250 cycles
	cadence_cycle(clk, 1250, set_cadence);
	// stores final values
	omega_2 = iPHYS.omega;
	current_2 = iDUT.iSENSORCONDITION.avg_curr;
	
	tester.testGt(omega_2, omega_1);
	tester.testGt(current_2, current_1);

	//TEST 4 CHECKS IF WHEN THE INCLINE INCREASES SO DOES THE OMEGA AND CURR

	BATT = 12'hB11; // battery above low battery threshold
	BRAKE = 12'hFFF; // brake deasserted
	TORQUE = 'h700; // non zero torque
	YAW_RT = '0; // flat land

	// oscillations cadence cycle at a period of 1250 clk cycles for 1250 cycles
	cadence_cycle(clk, 4096, set_cadence);

	// store initial values
	omega_1 = iPHYS.omega;
	current_1 = iDUT.iSENSORCONDITION.avg_curr;

	// set incline to uphill
	YAW_RT = 'h3300;

	// oscillations cadence cycle at a period of 1250 clk cycles for 1250 cycles
	cadence_cycle(clk, 1250, set_cadence);
	// stores final values
	omega_2 = iPHYS.omega;
	current_2 = iDUT.iSENSORCONDITION.avg_curr;
	
	tester.testGt(omega_2, omega_1);
	tester.testGt(current_2, current_1);



	//TEST 5 CHECKS WHEN BATTERY GOES BELOW THROESHOLD ERROR SHOULD GO TO ZERO AND OMEGA SHOULD DECREASE

	BATT = 12'hB11; // set battery to above low battery threshold
	BRAKE = 12'hFFF;
	TORQUE = 'h700;
	YAW_RT = 0;

	// oscillations cadence cycle at a period of 1250 clk cycles for 1250 cycles
	cadence_cycle(clk, 1250, set_cadence);
	
	// store initial values
	omega_1 = iPHYS.omega;
	current_1 = iDUT.iSENSORCONDITION.avg_curr;
	//set battery to below low battery threshold
	BATT = 'h470;

	// oscillations cadence cycle at a period of 1250 clk cycles for 1250 cycles
	cadence_cycle(clk, 1250, set_cadence);
	// stores final values
	omega_2 = iPHYS.omega;
	error = iDUT.iSENSORCONDITION.error;

	// error should go to zero if battery is low
	tester.testEq(error, 0);

	tester.print_stats();
	
	$stop();
  end
  
  ///////////////////
  // Generate clk //
  /////////////////
  always
    #10 clk = ~clk;

  ///////////////////////////////////////////
  // Block for cadence signal generation? //
  /////////////////////////////////////////
  assign cadence = set_cadence;
	
endmodule
