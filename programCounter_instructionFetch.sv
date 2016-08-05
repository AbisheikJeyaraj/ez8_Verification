
	/*module instructionMem(
		input  [11:0] memAddress,
		output [11:0] returnInstruction
	);*/
	
	// instructionMem connected through interface
	module programCounter_instructionFetch (programCounter_interface pcInterfaceForInstructionFetch);
	
		// 128 bit memory block
		reg [11:0] RAM[127:0];
		reg [11:0] returnValue = 12'd0;
		assign pcInterfaceForInstructionFetch.dut_fetchInstruction_output = returnValue;

		initial begin
			$display("Initiate Memory file with instructions");
			$readmemh("memfile.dat",RAM); // Read memory from dat file and store in the reg
		end

		always @* begin
			returnValue <= RAM[pcInterfaceForInstructionFetch.pc_out]; // Based on the memAddress i/p instruction should be fetched from the RAM
		end

	endmodule
