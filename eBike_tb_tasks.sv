package eBike_tester;

	// assesrts and deasserts the RST_n signal after initializing clk
    task automatic Initialize(ref clk, ref RST_n);
        begin
            clk = 1'b0;
	        RST_n = 1'b0;
	        @(posedge clk);
	        @(negedge clk);
	        RST_n = 1'b1;
        end
    endtask

	// oscillates cadence every 2*i clock edges and runs i of such oscillations
    task automatic cadence_cycle(ref clk, input int i, ref set_cadence);
    begin
	    repeat(i) begin 
		    set_cadence = 0;
		    repeat(i) @(posedge clk);
		    set_cadence = 1;
		    repeat(i) @(posedge clk);
	    end
    end
    endtask

	// gets the avg current from the UART_rcv
    task automatic get_current(ref rdy, ref [7:0] rx_data, output [11:0] avg_curr);
    begin
    while(1) begin
	    @(posedge rdy);
	    if( rx_data === 'hAA) begin
		    @(posedge rdy);
		    if( rx_data === 'h55) begin
			    break;
		    end
	    end
    end
    @(posedge rdy);
    @(posedge rdy);
    @(posedge rdy);
    avg_curr[11:8] = rx_data[3:0];
    @(posedge rdy);
    avg_curr[7:0] = rx_data[7:0];
    @(posedge rdy);
    @(posedge rdy);
    end
    endtask



	class Tester
	#(
		parameter ERROR_THRESH = 1,  // Number of errors before stopping simulation
		parameter PRECISION = 32, // Bit precision of checkers
		parameter VERBOSE = 0 // Verbose: print expected, got even if passed
	);

		// Statistics
		int errors = 0;
		int tests = 0;

		// Simple equality tester
		// max precision is 32-bits
		function void testEq(
			logic [PRECISION-1:0] got,
			logic [PRECISION-1:0] expected
		);
			tests++;
			if(expected === got) begin
				$display("Test %d PASSED.", tests);
				if(VERBOSE) begin
					$display("Expected Value: %h, Got %h", expected, got);
				end
			end
			else begin
				$display("Test %d FAILED.", tests);
				$display("Expected Value: %h, Got %h", expected, got);
				errors++;

				if(errors >= ERROR_THRESH) begin
					$display("Too many errors detected...");
					$display("Suspending simulation.");
					$stop;
				end
			end
		endfunction

		// Simple greater than tester. Fails and stops if got <= expected
		// max precision is 32-bits
		function void testGt(
			logic [PRECISION-1:0] got,
			logic [PRECISION-1:0] expected
		);
			tests++;
			if(expected < got) begin
				$display("Test %d PASSED.", tests);
				if(VERBOSE) begin
					$display("Expected Value: %h, Got %h", expected, got);
				end
			end
			else begin
				$display("Test %d FAILED.", tests);
				$display("Expected Value: %h, Got %h", expected, got);
				errors++;

				if(errors >= ERROR_THRESH) begin
					$display("Too many errors detected...");
					$display("Suspending simulation.");
					$stop;
				end
			end
		endfunction

		// Simple lesser than tester. Fails and stops if got >= expected
		// max precision is 32-bits
		function void testLt(
			logic [PRECISION-1:0] got,
			logic [PRECISION-1:0] expected
		);
			tests++;
			if(expected > got) begin
				$display("Test %d PASSED.", tests);
				if(VERBOSE) begin
					$display("Expected Value: %h, Got %h", expected, got);
				end
			end
			else begin
				$display("Test %d FAILED.", tests);
				$display("Expected Value: %h, Got %h", expected, got);
				errors++;

				if(errors >= ERROR_THRESH) begin
					$display("Too many errors detected...");
					$display("Suspending simulation.");
					$stop;
				end
			end
		endfunction

		// prints the number of tests passed so far.
		function void print_stats();
			$display("Errors: %d", errors);
			$display("Total Tests: %d", tests);
			if(errors !== 0) begin
				$display("Not all tests were successful.");
			end
			else begin
				$display("YAHOO!! All tests passed");
			end
		endfunction

	endclass





endpackage
