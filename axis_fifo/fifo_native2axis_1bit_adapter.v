
module fifo_native2axis_1bit_adapter #(
	parameter DATA_WIDTH = 36
	)(
	input 					m_clk,
	input 					m_rst,

	output 					s_ready,
	input 					fifo_full,

	input [DATA_WIDTH-1:0] 	fifo_data,
	input 					fifo_valid,
	output 					fifo_rden,

	output [DATA_WIDTH-1:0] m_payload,
	output 					m_valid,
	input 					m_ready
	);


	assign s_ready = ~fifo_full;

	reg 					buf_valid = 0;
	reg [DATA_WIDTH-1:0] 	buf_data  = 0;

	always @(posedge m_clk) begin
		if(m_rst) begin
			buf_valid 	<= 0;
		end
		if((~m_ready) && fifo_valid && (~buf_valid)) begin
			buf_valid 	<= fifo_valid;
			buf_data  	<= fifo_data;
		end
		else if(m_ready && buf_valid) begin
			buf_valid 	<= 0;
		end
	end

	assign m_payload 	= buf_valid ? buf_data : fifo_data;
	assign m_valid 		= buf_valid || fifo_valid;
	assign fifo_rden 	= ((~buf_valid)&&(~fifo_valid))|| m_ready;
	assign s_ready		= ~fifo_full;

endmodule
