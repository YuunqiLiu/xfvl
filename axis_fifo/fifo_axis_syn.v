
module fifo_axis_syn #(
	parameter DATA_WIDTH 				= 36,
	parameter DOUT_PIPE_NUMBER 			= 1,
	parameter FIFO_DEPTH 				= 8192,
    parameter RAM_TYPE 					= "block",
	//block,ultra,distributed,registers
	parameter RAM_CASCADE_HEIGHT 		= 100,
	parameter FIFO_THRESHOLD0			= 0,
	parameter FIFO_THRESHOLD1			= 0,
	parameter FIFO_THRESHOLD2			= 0,
	parameter FIFO_THRESHOLD3			= 0
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
	`include "H_STD_WIDTH_CACU.v"

	generate
	if(DOUT_PIPE_NUMBER==0) begin

			fifo_axis_syn_dly1 #(
				.DATA_WIDTH 			(DATA_WIDTH				),
				.FIFO_DEPTH 			(FIFO_DEPTH				),
			    .RAM_TYPE 				(RAM_TYPE				),
				.RAM_CASCADE_HEIGHT 	(RAM_CASCADE_HEIGHT		),
				.FIFO_THRESHOLD0		(FIFO_THRESHOLD0		),
				.FIFO_THRESHOLD1		(FIFO_THRESHOLD1		),
				.FIFO_THRESHOLD2		(FIFO_THRESHOLD2		),
				.FIFO_THRESHOLD3		(FIFO_THRESHOLD3		)
				//block,ultra,distributed,registers
				)
			inst_AXIS_syn_dly1
				(
				.clk(clk),
				.rst(rst),
				.s_payload(s_payload),
				.s_valid(s_valid),
				.s_ready(s_ready),
				.m_payload(m_payload),
				.m_valid(m_valid),
				.m_ready(m_ready),
				.threshold0(threshold0),
				.threshold1(threshold1),
				.threshold2(threshold2),
				.threshold(threshold)
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
				.m_clk(clk),
				.m_rst(rst),
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
				.clk(clk),
				.rst(rst),
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

				.din(s_payload),
				.wren(s_valid),
				.full(fifo_full),

				.dout(buf_s_payload),
				.dout_valid(buf_s_valid),
				.rden(fifo_rden),
				.empty(),

				.threshold0(threshold0),
				.threshold1(threshold1),
				.threshold2(threshold2),
				.threshold3(threshold3)
				);

	end
	endgenerate



endmodule
