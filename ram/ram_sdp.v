//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: YuunqiLiu
// Create Date: 2019/6/20
// Design Name: ram_sdp
// Target Devices:   7/U/U+ series FPGA/ZYNQ
// Tool Versions: vivado 2018+
// Description:
//		A simple dual port ram by verilog.
// Dependencies: None
// Revision: 
// 		Revision 1.00 - File Created
// Additional Comments:
//		DATA_WIDTH: (x:x >= 1)

//		ADDR_WIDTH: (x:2^x > RAM_DEPTH)

//		RAM_DEPTH:  (x:x >= 1)

//		DOUT_PIPE_NUMBER: (x:x >= 0)
//			Define the stage number of output registers for timing adjustment.
//			Output registers may be retiming into block ram.

//		RAM_TYPE: block/ultra/distributed/registers

//		CASCADE_HEIGHT: (x:x>=1 or x=-1)
//			x = -1 --- unlimited cascade height
//			x >= 1 --- cascade height limit
//////////////////////////////////////////////////////////////////////////////////

module ram_sdp #(
	parameter DATA_WIDTH          = 36,
  parameter ADDR_WIDTH          = 14,
  parameter RAM_DEPTH           = 1024,
  parameter DOUT_PIPE_NUMBER    = 1,
  parameter RAM_TYPE            = "block",
	//block,ultra,distributed,registers
	parameter CASCADE_HEIGHT      = -1
	)(
	input 					        clka,
	input 					        ena,
	input 					        wea,
	input [ADDR_WIDTH-1:0] 	addra,
	input [DATA_WIDTH-1:0] 	dina,

	input                   clkb,
	input 					        enb,
	input [ADDR_WIDTH-1:0] 	addrb,
	output [DATA_WIDTH-1:0] doutb,
	output 					        doutb_valid
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
