

module fifo_axis_syn_dly1 #(
	parameter DATA_WIDTH 				= 36,
	parameter FIFO_DEPTH 				= 8192,
    parameter RAM_TYPE 					= "block",
	//block,ultra,distributed,registers
	parameter RAM_CASCADE_HEIGHT 		= 100,
	parameter FIFO_THRESHOLD0			= 1,
	parameter FIFO_THRESHOLD1			= 2,
	parameter FIFO_THRESHOLD2			= 3,
	parameter FIFO_THRESHOLD3			= 4
	)(
	input 					clk,
	input 					rst,

	input [DATA_WIDTH-1:0]	s_payload,
	input 					s_valid,
	output 					s_ready,

	output [DATA_WIDTH-1:0]	m_payload,
	output 					m_valid,
	input 					m_ready,

	output 					threshold0,
	output 					threshold1,
	output 					threshold2,
	output 					threshold3
	);

	`include "H_STD_WIDTH_CACU.vh"
	localparam DOUT_PIPE_NUMBER 		= 0;

	wire 					fifo_valid;
	wire 					fifo_rden;
	wire 					fifo_full;
	wire [DATA_WIDTH-1:0] 	fifo_data;

	fifo_native2axis_1bit_adapter #(
		.DATA_WIDTH(DATA_WIDTH)
		)
	inst_fifo_native2axis_1bit_adapter
		(
		.m_clk(clk),
		.m_rst(rst),
		.s_ready(s_ready),
		.fifo_full(fifo_full),
		.fifo_data(fifo_data),
		.fifo_valid(fifo_valid),
		.fifo_rden(fifo_rden),
		.m_payload(m_payload),
		.m_valid(m_valid),
		.m_ready(m_ready)
		);

	fifo_syn #(
		.DATA_WIDTH 			(DATA_WIDTH 			),
		.DOUT_PIPE_NUMBER 		(DOUT_PIPE_NUMBER 		),
		.FIFO_DEPTH 			(FIFO_DEPTH 			),
	    .RAM_TYPE 				(RAM_TYPE 				),
		.RAM_CASCADE_HEIGHT 	(RAM_CASCADE_HEIGHT 	),
		.FIFO_THRESHOLD0		(FIFO_THRESHOLD0		),
		.FIFO_THRESHOLD1		(FIFO_THRESHOLD1		),
		.FIFO_THRESHOLD2		(FIFO_THRESHOLD2		),
		.FIFO_THRESHOLD3		(FIFO_THRESHOLD3		)
		//block,ultra,distributed,registers
		)
	inst_fifo_syn
		(
		.clk(clk),
		.rst(rst),
		.wr_data(s_payload),
		.wr_en(s_valid),
		.full(fifo_full),
		.rd_data(fifo_data),
		.rd_valid(fifo_valid),
		.rd_en(fifo_rden),
		.empty(),
		.threshold0(threshold0),
		.threshold1(threshold1),
		.threshold2(threshold2),
		.threshold3(threshold3)
		);

endmodule
