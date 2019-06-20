
module fifo_asyn_half_controller #(
	parameter CONTROLLER_MODE 		= "read",
	parameter PTR_GRAY_BUFFER_STAGE = 0,
	//"write","read"
	parameter ADDR_WIDTH 			= 10,
	parameter ASYN_SIG_SYN_STAGE 	= 2

	)(
	input 					clk,
	input 					rst,

	input 					inc,
	output [ADDR_WIDTH-1:0] ptr_bin,
	output [ADDR_WIDTH:0]	ptr_gray,

	input  [ADDR_WIDTH:0]	pty_gray_asyn,

	output reg 				state = 1,
	output 					ram_en
	);



	integer i=0;
	integer j=0;
	(* ASYNC_REG = "true" *) reg [ADDR_WIDTH:0] pty_gray_asyn_reg [ASYN_SIG_SYN_STAGE-1:0];
	wire [ADDR_WIDTH:0] ptr_syned;
	initial begin
		for (i=0;i<ASYN_SIG_SYN_STAGE;i=i+1) pty_gray_asyn_reg[i] = 0;
	end



	wire [ADDR_WIDTH:0] ptr_bin_c;
	reg  [ADDR_WIDTH:0] ptr_bin_reg = 0;

	wire [ADDR_WIDTH:0] ptr_gray_c;
	reg  [ADDR_WIDTH:0] ptr_gray_reg = 0;

	assign ptr_bin = ptr_bin_reg[ADDR_WIDTH-1:0];
	assign ram_en		= inc && (~state);
	assign ptr_bin_c 	= ram_en ? (ptr_bin_reg+1'b1) : ptr_bin_reg;
	assign ptr_gray_c 	= (ptr_bin_c >> 1) ^ ptr_bin_c;

	always @(posedge clk) begin
		if(rst) ptr_bin_reg <= 0;
		else 	ptr_bin_reg <= ptr_bin_c;
	end

	always @(posedge clk) begin
		if(rst)	ptr_gray_reg <= 0;
		else 	ptr_gray_reg <= ptr_gray_c;
	end


	always @(posedge clk) begin
		pty_gray_asyn_reg[0] <= pty_gray_asyn;
		for(i=0;i<ASYN_SIG_SYN_STAGE-1;i=i+1)
			pty_gray_asyn_reg[i+1] <= pty_gray_asyn_reg[i];
	end

	generate
	if(PTR_GRAY_BUFFER_STAGE == 0) begin
		assign ptr_gray = ptr_gray_reg;
	end
	else begin
		(* shreg_extract = "no" *) reg [PTR_GRAY_BUFFER_STAGE-1:0] ptr_gray_reg_buffer;
		initial begin
			for (j=0;j<PTR_GRAY_BUFFER_STAGE;j=j+1) ptr_gray_reg_buffer[j] = 0;
		end

		always @(posedge clk) begin
			ptr_gray_reg_buffer <= ptr_gray_reg;
			for(j=0;j<PTR_GRAY_BUFFER_STAGE-1;j=j+1)
				ptr_gray_reg_buffer[j+1] <= ptr_gray_reg_buffer[j];
		end
	end
	endgenerate

	assign ptr_syned = pty_gray_asyn_reg[ASYN_SIG_SYN_STAGE-1];

	generate
	if (CONTROLLER_MODE == "read") begin
		always @(posedge clk) state <= (ptr_gray_c == ptr_syned	)?1:0;

	end
	else if (CONTROLLER_MODE == "write") begin
		always @(posedge clk) state <= (ptr_gray_c == {~ptr_syned[ADDR_WIDTH:ADDR_WIDTH-1],ptr_syned[ADDR_WIDTH-2:0]} )?1:0;
	end
	endgenerate




endmodule
