

module fifo_asyn #(
	parameter DATA_WIDTH 				= 36,
	parameter ADDR_WIDTH 				= 14,
	parameter DOUT_PIPE_NUMBER 			= 10,
	parameter RAM_TYPE 					= "block",
	parameter CASCADE_HEIGHT 			= 100,
	parameter ASYN_SRC_STAGE			= 0,
	parameter ASYN_DES_STAGE			= 2
	)(
	input 							wr_clk,
	input 							wr_rst,
	input [DATA_WIDTH-1:0]			wr_data,
	input 							wr_en,
	output 							full,

	input 							rd_clk,
	input 							rd_rst,
	input 							rd_en,
	output [DATA_WIDTH-1:0]			rd_data,
	output 							rd_valid,
	output 							empty
	);

	wire [ADDR_WIDTH-1:0] read_bin_ptr;
	wire [ADDR_WIDTH-1:0] write_bin_ptr;

	//bus skew attation !!!
	wire [ADDR_WIDTH:0]	ptr_gray_r2w;
	wire [ADDR_WIDTH:0] ptr_gray_w2r;

	wire ram_wren;
	wire ram_rden;

	fifo_asyn_half_controller #(
		.CONTROLLER_MODE("write"),
		.PTR_GRAY_BUFFER_STAGE(ASYN_SRC_STAGE),
		.ADDR_WIDTH(ADDR_WIDTH),
		.ASYN_SIG_SYN_STAGE(ASYN_DES_STAGE)
	)
	fifo_asyn_write_controller
	(
		.clk(wr_clk),
		.rst(wr_rst),
		.inc(wr_en),
		.ptr_bin(write_bin_ptr),
		.ptr_gray(ptr_gray_w2r),
		.pty_gray_asyn(ptr_gray_r2w),
		.state(full),
		.ram_en(ram_wren)
	);

	fifo_asyn_half_controller #(
		.CONTROLLER_MODE("read"),
		.PTR_GRAY_BUFFER_STAGE(ASYN_SRC_STAGE),
		.ADDR_WIDTH(ADDR_WIDTH),
		.ASYN_SIG_SYN_STAGE(ASYN_DES_STAGE)
		)
	fifo_asyn_read_controller
		(
		.clk(rd_clk),
		.rst(rd_rst),
		.inc(rd_en),
		.ptr_bin(read_bin_ptr),
		.ptr_gray(ptr_gray_r2w),
		.pty_gray_asyn(ptr_gray_w2r),
		.state(empty),
		.ram_en(ram_rden)
		);


	ram_sdp #(
		.DATA_WIDTH 		(DATA_WIDTH 		),
	    .ADDR_WIDTH 		(ADDR_WIDTH 		),
	    .RAM_DEPTH 			(1<<ADDR_WIDTH 		),
	    .DOUT_PIPE_NUMBER 	(DOUT_PIPE_NUMBER 	),
	    .RAM_TYPE 			(RAM_TYPE 			),
		.CASCADE_HEIGHT 	(CASCADE_HEIGHT 	)
		//block,ultra,distributed,registers
		)
	inst_ram_sdp
		(
		.clka(wr_clk),
		.ena(ram_wren),
		.wea(ram_wren),
		.addra(write_bin_ptr),
		.dina(wr_data),

		.clkb(rd_clk),
		.enb(ram_rden),
		.addrb(read_bin_ptr),
		.doutb(rd_data),
		.doutb_valid(rd_valid)
		);



endmodule
