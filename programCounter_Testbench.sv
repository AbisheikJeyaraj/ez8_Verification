/*
	Proof of Concept for the Verification of Program Counter and instruction fetch module in 8 bit CPU.
	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	a) The modules in this Test bench are interconnected by interface (programCounter_interface.sv).
	b) Below process has been verified in this test bench
		* Reset 
		* Interrupt
		* Skip
		* Skip with interrupt
		* goto
		* retrieve
		* Counter
	
*/
module programCounter_Testbench;

	//Instantiate interface
	programCounter_interface pcInterface();

	//Instantiate program counter control through interface
	programCounter_ctrl pcc(.pcInterfaceForPcCtrl(pcInterface));

	//Instantiate instruction memory through interface
	programCounter_instructionFetch insmem(.pcInterfaceForInstructionFetch(pcInterface));

	// For counter
	event reset_enable;
	event terminate_sim;
	event resume_counter_event;

	// For instruction fetch	
	event instruction_fetch_event;

	// For interrupt
	event interrupt_enable_event;

	// For goto
	event goto_enable_event;
	
	// For Skip
	event skip_enable_event;
	event skip_with_interrupt_enable_event;

	// For retrieve
	event retrieve_enable_event;

	// Initial block for initialization
	initial begin
 		$display ("###################################################");
 		pcInterface.clk = 0;
 		pcInterface.reset = 0;
 		pcInterface.pause = 0;
 		pcInterface.counter_error = 0;
		pcInterface.instFetch_error = 0;

		$readmemh("memfile.dat",pcInterface.RAM); // Read memory from dat file and store in the reg

		#3000 pcInterface.pcCheckerFunction; //  trigger checker event after 3000ns
	end

	// Always block to generate clock
	always
  		#50 pcInterface.clk = !pcInterface.clk;


	/* DUT Process Tested
	   ~~~~~~~~~~~~~~~~~~
		a) Reset --> While reset counter value turns to 0
		b) Interrupt --> skip two cycles and push pc_out value to stack and INTERRUPT_VECTOR value assigned to pc_out
		c) Skip --> Skip will do counter + 1 with no interrupt
		d) Skip with interrupt --> skip one cycle and push pc_out value to stack and INTERRUPT_VECTOR value assigned to pc_out
		e) goto --> will go to the random address
		f) retrieve --> retrieve will pop the values from stack
		g) Counter --> counter will add + 1 on each cycle
	*/

	// Reset
	initial forever begin
		@ (reset_enable);
			@ (negedge pcInterface.clk)
				$display ("Reset enabled at time %d",$time);
				pcInterface.reset = 1;
			@ (negedge pcInterface.clk)
				pcInterface.reset = 0;
			-> resume_counter_event; // Resume counter event
		end

	// Interrupt
	initial forever begin
		@ (interrupt_enable_event);
			@ (negedge pcInterface.clk)
				$display ("Interrupt enabled at time %d",$time);
				pcInterface.interrupt = 1;
			@ (negedge pcInterface.clk)
				pcInterface.interrupt = 0;
			-> resume_counter_event; // Resume counter event
		end

	// Skip
	initial forever begin
		@ (skip_enable_event);
			@ (negedge pcInterface.clk)
				$display ("Skip enabled at time %d",$time);
				pcInterface.skip = 1;
			@ (negedge pcInterface.clk)
				pcInterface.skip = 0;
			-> resume_counter_event; // Resume counter event
		end

	// Skip with interrupt
	initial forever begin
		@ (skip_with_interrupt_enable_event);
			@ (negedge pcInterface.clk)
				$display ("Skip with interrupt enabled at time %d",$time);
				pcInterface.skip = 1;
				pcInterface.interrupt = 1;
			@ (negedge pcInterface.clk)
				pcInterface.skip = 0;
				pcInterface.interrupt = 0;
			-> resume_counter_event; // Resume counter event
		end

	// goto
	initial forever begin
		@ (goto_enable_event);
			@ (negedge pcInterface.clk)
				$display ("goto enabled at time%t",$time);
				pcInterface.goto = 1;
				pcInterface.random_goto_addr = $random;  // random address for goto
				pcInterface.goto_addr = pcInterface.random_goto_addr;
			@ (negedge pcInterface.clk)
				pcInterface.goto = 0;
			-> resume_counter_event; // Resume counter event
		end

	// retrieve
	initial forever begin
		@ (retrieve_enable_event);
			@ (negedge pcInterface.clk)
				pcInterface.ret = 1;
			@ (negedge pcInterface.clk)
				pcInterface.ret = 0;
			-> resume_counter_event;  // Resume counter event
		end

	

	// Counter
	initial begin
		#10 -> reset_enable;  // enabling reset event
		#200 -> interrupt_enable_event;  // enabling interrupt event
		#400 -> goto_enable_event;  // enabling goto event
		#500 -> skip_enable_event;  // enabling skip event
		#300 -> reset_enable;   // enabling reset event
		#500 -> goto_enable_event;  // enabling goto event
		#500 -> skip_with_interrupt_enable_event;  // enabling skip with interrupt event
		#500 -> retrieve_enable_event;  // enabling retrieve event

		@ (resume_counter_event);
			@ (negedge pcInterface.clk);
				pcInterface.reset = 0; // Resume counter event when reset is 0
	end

	// Behavioral model for counter
	always @ (posedge pcInterface.clk) begin
		if (pcInterface.reset == 1'b1) begin
			pcInterface.behavioral_count_output <= 0; // 0 when reset
			pcInterface.stack = {}; // on reset empty the stack
		end
		else if (pcInterface.interrupt_save == 1'b1) begin
			pcInterface.stack.push_back( pcInterface.behavioral_count_output ); // save to stack
			pcInterface.behavioral_count_output <= 12'd4;  // when interrupt occurs o/p set to 4
			pcInterface.interrupt_save <= 1'b0;  // make interrupt_save to 0
		end
		else if (pcInterface.interrupt_wait == 1'b1) begin
			pcInterface.interrupt_wait <= 1'b0;  // interrupt_wait to 0
			pcInterface.interrupt_save <= 1'b1;  // make interrupt_save to 1
		end
		else if (pcInterface.skip == 1'b1) begin
			if (pcInterface.interrupt == 1'b1)
				pcInterface.interrupt_save <= 1; // make interrupt_wait to 1
			else
				pcInterface.behavioral_count_output <= pcInterface.behavioral_count_output + 1; // add + 1 for counter
		end
		else if (pcInterface.goto == 1'b1) begin
			pcInterface.behavioral_count_output <= pcInterface.random_goto_addr; // Set random address
		end
		else if (pcInterface.ret == 1'b1) begin
			pcInterface.behavioral_count_output <= pcInterface.stack.pop_front(); // value fetches from stack
		end
		else if ( pcInterface.reset == 1'b0) begin
			if (pcInterface.interrupt == 1'b1)
				pcInterface.interrupt_wait <= 1; // make interrupt_wait to 1
			else
				pcInterface.behavioral_count_output <= pcInterface.behavioral_count_output + 1; // add + 1 for counter
		end
		#5 -> instruction_fetch_event;  // Trigger this event to fetch the instruction
	end

	// Behavioral model for instruction fetch
	initial forever begin 
		@ (instruction_fetch_event); 
			pcInterface.behavioral_fetchInstruction_output <= pcInterface.RAM[pcInterface.behavioral_count_output]; // Based on the memAddress i/p instruction should be fetched from the RAM
	end

	// value to push in queue
	always @ (negedge pcInterface.clk) begin
		// Push behavioral_count_output
		pcInterface.behavioralCounterOutput.push_back( pcInterface.behavioral_count_output );
		// Push pc_out from DUT
		pcInterface.dutCounterOutput.push_back( pcInterface.pc_out );
		// Push behavioral_fetchInstruction_output
		pcInterface.behavioralInstructionFetchOutput.push_back( pcInterface.behavioral_fetchInstruction_output );
		// Push behavioral_fetchInstruction_output
		pcInterface.dutInstructionFetchOutput.push_back( pcInterface.behavioral_fetchInstruction_output );
	end

	

endmodule