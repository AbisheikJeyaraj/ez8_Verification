// Interface definition
interface programCounter_interface;
 
	// For DUT
	reg reset;
    	reg pause;

    	reg goto;
    	reg [11:0] goto_addr = 12'h0;
    	reg call;
    	reg skip;
    	reg ret; 
    	reg interrupt;
    	reg save_accum;

    	reg error;
    	reg stopped;
    	wire [11:0] pc_out;
    	wire kill;
	
	// Clock
	reg clk = 1'b0;

	// For counter
	reg counter_error;
	reg [11:0] behavioral_count_output;
	event reset_enable;
	event terminate_sim;
	event resume_counter_event;

	// For instruction fetch
	reg [11:0] dut_fetchInstruction_output;
	reg [11:0] RAM[127:0]; // 128 bit memory block
	reg [11:0] behavioral_fetchInstruction_output = 12'd0;
	reg instFetch_error;
	event instruction_fetch_event;

	// For interrupt
	event interrupt_enable_event;
	reg interrupt_wait = 1'b0;
	reg interrupt_save = 1'b0;

	// For checker
	event checker_event;
	reg [11:0] dut_counterValue_toCompare;
	reg [11:0] behavioral_counterValue_toCompare;
	reg [11:0] dut_instructionFetchValue_toCompare;
	reg [11:0] behavioral_instructionFetchValue_toCompare;

	// For goto
	reg [11:0] random_goto_addr;
	
	// Data Structure
	int behavioralCounterOutput[$];
	int dutCounterOutput[$];

	int behavioralInstructionFetchOutput[$];
	int dutInstructionFetchOutput[$];

	int stack[$]; // for stack
	
	//  Function for checker
	function pcCheckerFunction; 
		integer i;
		begin
			for (i = 1; i < dutCounterOutput.size(); i ++) begin
				// get value from the queue to compare in the checker
				dut_counterValue_toCompare = dutCounterOutput[i];
				behavioral_counterValue_toCompare = behavioralCounterOutput[i];
				dut_instructionFetchValue_toCompare = dutInstructionFetchOutput[i];
				behavioral_instructionFetchValue_toCompare = behavioralInstructionFetchOutput[i];
				// Counter checker
				if (behavioral_counterValue_toCompare != dut_counterValue_toCompare) begin
					$display ("DUT ERROR :: COUNTER AT TIME%d",$time);
					$display ("Expected value %d, Got Value %d", behavioral_counterValue_toCompare, dut_counterValue_toCompare);
					counter_error = 1;
				end
				// Fetch instruction checker
				if (behavioral_instructionFetchValue_toCompare != dut_instructionFetchValue_toCompare) begin
					$display ("DUT ERROR :: INSTRUCTION FETCH AT TIME%d",$time);
					$display ("Expected value %d, Got Value %d", behavioral_instructionFetchValue_toCompare, dut_instructionFetchValue_toCompare);
					instFetch_error = 1;
				end
			end	
		end	
		pcFinalResultFunction;
	endfunction 

	// Function to diaplay final results
	function pcFinalResultFunction; 
		$display ("Terminating simulation");
 		if ( counter_error == 0 && instFetch_error == 0 ) begin 
   			$display ("Simulation Result : PASSED at %d", $time);
 		end
 		else begin
   			$display ("Simulation Result : FAILED");
 		end
 		$display ("###################################################");
	endfunction
	
endinterface