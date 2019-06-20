

module fifo_syn #(
	parameter DATA_WIDTH 				= 36,
	parameter DOUT_PIPE_NUMBER 			= 1,
	parameter FIFO_DEPTH 				= 8192,
    parameter RAM_TYPE 					= "block",
	//block,ultra,distributed,registers
	parameter RAM_CASCADE_HEIGHT 		= 100,
	parameter FIFO_THRESHOLD0			= 1,
	parameter FIFO_THRESHOLD1			= 2,
	parameter FIFO_THRESHOLD2			= 3,
	parameter FIFO_THRESHOLD3			= 4
	)(
	input clk,
	input rst,

	input [DATA_WIDTH-1:0] 	wr_data,
	input 					wr_en,
	output 					full,

	output [DATA_WIDTH-1:0] rd_data,
	output 					rd_valid,
	input 					rd_en,
	output 					empty,

	output 					threshold0,
	output 					threshold1,
	output 					threshold2,
	output 					threshold3
	);

	`include "H_STD_WIDTH_CACU.v"

    localparam RAM_ADDR_WIDTH 			= STD_WIDTH_CACU(FIFO_DEPTH);
	localparam COUNTER_WIDTH			= STD_WIDTH_CACU(FIFO_DEPTH+1);


	wire ram_wren;
	wire ram_rden;

	reg [RAM_ADDR_WIDTH-1:0] 	write_ptr	= 0;
	reg [RAM_ADDR_WIDTH-1:0] 	read_ptr	= 0;
	reg [COUNTER_WIDTH-1:0] 	counter		= 0;

	assign ram_wren 	= wr_en && (~full);
	assign ram_rden 	= rd_en && (~empty);
	assign full 		= (counter==FIFO_DEPTH) ? 1 : 0;
	assign empty 		= (counter==0) ? 1 : 0;
	assign threshold0	= (counter>FIFO_THRESHOLD0) ? 1:0;
	assign threshold1	= (counter>FIFO_THRESHOLD1) ? 1:0;
	assign threshold2	= (counter>FIFO_THRESHOLD2) ? 1:0;
	assign threshold3	= (counter>FIFO_THRESHOLD3) ? 1:0;

	always @(posedge clk) begin
		if(rst) begin
			write_ptr 	<= 0;
			read_ptr 	<= 0;
			counter		<= 0;
		end
		else begin
			case({ram_wren,ram_rden})
			2'b00://no operation
				begin
					write_ptr 	<= write_ptr;
					read_ptr	<= read_ptr;
					counter		<= counter;
				end

			2'b01://read
				begin
					write_ptr	<= write_ptr;
					read_ptr	<= (read_ptr==FIFO_DEPTH-1) ? 0 : (read_ptr + 1'b1);
					counter		<= counter - 1'b1;
				end

			2'b10://write
				begin
					write_ptr	<= (write_ptr==FIFO_DEPTH-1) ? 0 : (write_ptr + 1'b1);
					read_ptr	<= read_ptr;
					counter		<= counter + 1'b1;
				end

			2'b11://both read and write
				begin
					write_ptr 	<= (write_ptr==FIFO_DEPTH-1) ? 0 : (write_ptr + 1'b1);
					read_ptr 	<= (read_ptr==FIFO_DEPTH-1) ? 0 : (read_ptr + 1'b1);
					counter		<= counter;
				end
			endcase
		end
	end


	ram_sdp #(
		.DATA_WIDTH 		(DATA_WIDTH			),
	    .ADDR_WIDTH 		(RAM_ADDR_WIDTH		),
	    .RAM_DEPTH 			(FIFO_DEPTH			),
	    .DOUT_PIPE_NUMBER 	(DOUT_PIPE_NUMBER	),
	    .RAM_TYPE 			(RAM_TYPE			),
		.CASCADE_HEIGHT 	(RAM_CASCADE_HEIGHT	)
		)
	inst_ram_sdp_syn
		(
		.clka(clk),
		.ena(ram_wren),
		.wea(ram_wren),
		.addra(write_ptr),
		.dina(wr_data),
		.clkb(clk),
		.enb(ram_rden),
		.addrb(read_ptr),
		.doutb(rd_data),
		.doutb_valid(rd_valid)
		);


endmodule
