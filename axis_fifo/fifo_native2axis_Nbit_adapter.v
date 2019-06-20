
module fifo_native2axis_Nbit_adapter #(
	parameter DOUT_PIPE_NUMBER = 1,
	parameter BUF_DEPTH = 32
	)(
	input 			m_clk,
	input 			m_rst,

	input 			m_valid,
	input 			m_ready,

	input 			buf_s_valid,
	input 			buf_s_ready,

	output 			s_ready,

	output reg 		fifo_rden,
	input 			fifo_full
	);
	`include "H_STD_WIDTH_CACU.v"

	localparam COUNTER_WIDTH 			= STD_WIDTH_CACU(BUF_DEPTH+1);

	reg [COUNTER_WIDTH-1:0] 	counter = 0;

	assign s_ready = ~fifo_full;

	always @(posedge m_clk) begin
		if(m_rst) 		counter <= 0;
		else begin
			casex({buf_s_valid,buf_s_ready,m_valid,m_ready})
			4'b1111:	counter <= counter;
			4'b11xx:	counter <= counter + 1'b1;
			4'bxx11:	counter <= counter - 1'b1;
			default:	counter <= counter;
			endcase
		end
	end

	assign buf_overflow 	= buf_s_valid && (~buf_s_ready);
	assign s_ready			= ~fifo_full;


	always @(posedge m_clk) begin
		if(m_rst)												fifo_rden <= 0;
		else if(counter >= BUF_DEPTH-DOUT_PIPE_NUMBER-1) 		fifo_rden <= 0;
		else if(counter <= (BUF_DEPTH-2*DOUT_PIPE_NUMBER-1)) 	fifo_rden <= 1;
	end

endmodule
