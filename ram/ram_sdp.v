

module ram_sdp #(
	parameter DATA_WIDTH 				= 36,
    parameter ADDR_WIDTH 				= 14,
    parameter RAM_DEPTH 				= 1024,
    parameter DOUT_PIPE_NUMBER 			= 10,
    parameter RAM_TYPE 					= "block",
	//block,ultra,distributed,registers
	parameter CASCADE_HEIGHT 			= 100
	)(
	input 					clka,
	input 					ena,
	input 					wea,
	input [ADDR_WIDTH-1:0] 	addra,
	input [DATA_WIDTH-1:0] 	dina,

	input                   clkb,
	input 					enb,
	input [ADDR_WIDTH-1:0] 	addrb,
	output [DATA_WIDTH-1:0] doutb,
	output 					doutb_valid
	);

	integer i;
	reg [DATA_WIDTH-1:0] ram_dout;
	(* ram_style = RAM_TYPE , cascade_height = CASCADE_HEIGHT *) reg [DATA_WIDTH-1:0] ram [RAM_DEPTH-1:0];

	//RAM DEFINE ----------------------------------------------------------------
	always @(posedge clka) begin
		if (ena) begin
			if (wea) ram[addra] <= dina;
		end
	end

	always @(posedge clkb) begin
		if (enb) begin
			ram_dout <= ram[addrb];
		end
	end


	//RAM OUTPUT PIPE LINE--------------------------------------------------------
	reg ram_en_pipe_reg[DOUT_PIPE_NUMBER:0];
	initial begin
		for(i=0;i<DOUT_PIPE_NUMBER;i=i+1) ram_en_pipe_reg[i] = 0;
	end

	always @(posedge clkb) begin
		ram_en_pipe_reg[0] <= enb;
		for (i=0; i<DOUT_PIPE_NUMBER; i=i+1)
			ram_en_pipe_reg[i+1] <= ram_en_pipe_reg[i];
	end

	assign doutb_valid = ram_en_pipe_reg[DOUT_PIPE_NUMBER];

	generate
	if(DOUT_PIPE_NUMBER==0) begin
		assign doutb = ram_dout;
	end
	else begin
		reg [DATA_WIDTH-1:0] ram_pipe_reg[DOUT_PIPE_NUMBER-1:0];

		always @(posedge clkb) begin
			if(ram_en_pipe_reg[0])
				ram_pipe_reg[0] <= ram_dout;

			for(i=0;i<DOUT_PIPE_NUMBER-1;i=i+1)
				if(ram_en_pipe_reg[i+1])
					ram_pipe_reg[i+1] <= ram_pipe_reg[i];
		end

		assign doutb = ram_pipe_reg[DOUT_PIPE_NUMBER-1];
	end
	endgenerate



endmodule
