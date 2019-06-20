
module fifo_axis_asyn #(
	parameter DATA_WIDTH 				= 36,
	parameter ADDR_WIDTH 				= 10,
	parameter DOUT_PIPE_NUMBER 			= 1,
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
	`include "H_STD_WIDTH_CACU.v"

	generate
	if(DOUT_PIPE_NUMBER==0) begin

	 	fifo_axis_asyn_dly1 #(
			.DATA_WIDTH 			(DATA_WIDTH 			),
			.ADDR_WIDTH 			(ADDR_WIDTH 			),
		    .RAM_TYPE 				(RAM_TYPE 				),
			.RAM_CASCADE_HEIGHT 	(RAM_CASCADE_HEIGHT 	),
			.ASYN_SRC_STAGE			(ASYN_SRC_STAGE			),
			.ASYN_DES_STAGE			(ASYN_DES_STAGE			)
			//block,ultra,distributed,registers
			)
		inst_fifo_axis_asyn_dly1
			(
			.s_clk(s_clk),
			.s_rst(s_rst),
			.s_payload(s_payload),
			.s_valid(s_valid),
			.s_ready(s_ready),
			.m_clk(m_clk),
			.m_rst(m_rst),
			.m_payload(m_payload),
			.m_valid(m_valid),
			.m_ready(m_ready)
			);

	end
	else begin

			localparam BUF_DEPTH_NEEDED 		= 1<<(STD_WIDTH_CACU(3*DOUT_PIPE_NUMBER+3));
			localparam BUF_DEPTH 				= (BUF_DEPTH_NEEDED>32)?BUF_DEPTH_NEEDED:32;
			localparam BUF_RAM_TYPE 			= "distributed";
			localparam BUF_CASCADE_HEIGHT 		= 1000;

			localparam COUNTER_WIDTH 			= STD_WIDTH_CACU(BUF_DEPTH+1);

			wire 						fifo_rden;
			wire 						fifo_full;
			wire [DATA_WIDTH-1:0] 		buf_s_payload;
			wire 						buf_s_valid;
			wire 						buf_s_ready;

			fifo_native2axis_Nbit_adapter #(
				.DOUT_PIPE_NUMBER(DOUT_PIPE_NUMBER),
				.BUF_DEPTH(BUF_DEPTH)
				)
			inst_fifo_native2axis_Nbit_adapter
				(
				.m_clk(m_clk),
				.m_rst(m_rst),
				.m_valid(m_valid),
				.m_ready(m_ready),
				.s_ready(s_ready),
				.buf_s_valid(buf_s_valid),
				.buf_s_ready(buf_s_ready),
				.fifo_rden(fifo_rden),
				.fifo_full(fifo_full)
				);

			fifo_axis_syn_dly1 #(
				.DATA_WIDTH				(DATA_WIDTH			),
				.FIFO_DEPTH				(BUF_DEPTH			),
				.RAM_TYPE				(BUF_RAM_TYPE		),
				//block,ultra,distributed,registers
				.RAM_CASCADE_HEIGHT		(BUF_CASCADE_HEIGHT	),
				.FIFO_THRESHOLD0		(0					),
				.FIFO_THRESHOLD1		(0					),
				.FIFO_THRESHOLD2		(0					),
				.FIFO_THRESHOLD3		(0					)
				)
			inst_buf_fifo
				(
				.clk(m_clk),
				.rst(m_rst),
				.s_payload(buf_s_payload),
				.s_valid(buf_s_valid),
				.s_ready(buf_s_ready),
				.m_payload(m_payload),
				.m_valid(m_valid),
				.m_ready(m_ready),
				.threshold0(),
				.threshold1(),
				.threshold2(),
				.threshold3()
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
				.rd_en(fifo_rden),
				.rd_data(buf_s_payload),
				.rd_valid(buf_s_valid),
				.empty()
				);

	end
	endgenerate



endmodule
