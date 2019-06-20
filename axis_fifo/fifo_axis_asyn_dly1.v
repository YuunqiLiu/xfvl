
module fifo_axis_asyn_dly1 #(
	parameter DATA_WIDTH 				= 36,
	parameter ADDR_WIDTH 				= 10,
    parameter RAM_TYPE 					= "block",
	//block,ultra,distributed,registers
	parameter RAM_CASCADE_HEIGHT 		= 100,
	parameter ASYN_SRC_STAGE			= 0,
	parameter ASYN_DES_STAGE			= 2
	)(
	input 					s_clk,
	input 					s_rst,
	input [DATA_WIDTH-1:0]	s_payload,
	input 					s_valid,
	output 					s_ready,

	input 					m_clk,
	input 					m_rst,
	output [DATA_WIDTH-1:0]	m_payload,
	output 					m_valid,
	input 					m_ready
	);

	wire 					fifo_full;
	wire [DATA_WIDTH-1:0] 	fifo_rd_data;
	wire 					fifo_rd_en;
	wire 					fifo_rd_valid;


	localparam DOUT_PIPE_NUMBER			= 0;


	fifo_native2axis_1bit_adapter #(
		.DATA_WIDTH(DATA_WIDTH)
		)
	inst_fifo_native2axis_1bit_adapter
		(
		.m_clk(m_clk),
		.m_rst(m_rst),
		.s_ready(s_ready),
		.fifo_full(fifo_full),
		.fifo_data(fifo_rd_data),
		.fifo_valid(fifo_rd_valid),
		.fifo_rden(fifo_rd_en),
		.m_payload(m_payload),
		.m_valid(m_valid),
		.m_ready(m_ready)
		);

	fifo_asyn #(
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH),
		.DOUT_PIPE_NUMBER(DOUT_PIPE_NUMBER),
		.RAM_TYPE(RAM_TYPE),
		.CASCADE_HEIGHT(RAM_CASCADE_HEIGHT),
		.ASYN_SRC_STAGE(ASYN_SRC_STAGE),
		.ASYN_DES_STAGE(ASYN_DES_STAGE)
		)
	inst_fifo_asyn
		(
		.wr_clk(s_clk),
		.wr_rst(s_rst),
		.wr_data(s_payload),
		.wr_en(s_valid),
		.full(fifo_full),

		.rd_clk(m_clk),
		.rd_rst(m_rst),
		.rd_en(fifo_rd_en),
		.rd_data(fifo_rd_data),
		.rd_valid(fifo_rd_valid),
		.empty()
		);







endmodule
