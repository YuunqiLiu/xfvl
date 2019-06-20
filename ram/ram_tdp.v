//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: YuunqiLiu
// Create Date: 2019/6/20
// Design Name: ram_tdp
// Target Devices:   7/U/U+ series FPGA/ZYNQ
// Tool Versions: vivado 2018+
// Description:
//		A true dual port ram by verilog.
// Dependencies: None
// Revision: 
// 		Revision 1.00 - File Created
// Additional Comments:
//		DATA_WIDTH: (x:x >= 1)

//  	ADDR_WIDTH: (x:2^x > RAM_DEPTH)

//  	RAM_DEPTH:  (x:x >= 1)

//		DOUT_PIPE_NUMBER: (x:x >= 0)
//			Define the stage number of output registers for timing adjustment.
//			Output registers may be retiming into block ram.

//		RAM_TYPE: block/ultra/distributed/registers

//		RAM_BEHAVIOR: read_first/write_first/no_change

//		CASCADE_HEIGHT: (x:x>=1 or x=-1)
//			x = -1 --- unlimited cascade height
//			x >= 1 --- cascade height limit
//////////////////////////////////////////////////////////////////////////////////


module ram_tdp #(
	parameter DATA_WIDTH 				= 36,
    parameter ADDR_WIDTH 				= 14,
    parameter RAM_DEPTH 				= 1024,
    parameter DOUT_PIPE_NUMBER 			= 1,
    parameter RAM_TYPE 					= "block",
	//block,ultra,distributed,registers
	parameter RAM_BEHAVIOR 				= "read_first",
	//read_first,write_first,no_change
	parameter CASCADE_HEIGHT 			= -1
	)(
	input 					clka,
	input 					ena,
	input 					wea,
	input [ADDR_WIDTH-1:0] 	addra,
	input [DATA_WIDTH-1:0] 	dina,
	output [DATA_WIDTH-1:0]	douta,
	output 					douta_valid,

	input 					clkb,
	input 					enb,
	input 					web,
	input [ADDR_WIDTH-1:0] 	addrb,
	input [DATA_WIDTH-1:0] 	dinb,
	output [DATA_WIDTH-1:0] doutb,
	output 					doutb_valid
	);

	integer i,j;
	reg [DATA_WIDTH-1:0] rama_dout;
	reg [DATA_WIDTH-1:0] ramb_dout;
	(* ram_style = RAM_TYPE , cascade_height = CASCADE_HEIGHT *) reg [DATA_WIDTH-1:0] ram [RAM_DEPTH-1:0];

	//RAM DEFINE ----------------------------------------------------------------
	generate
	case(RAM_BEHAVIOR)
	"read_first":
	begin
		always @(posedge clka) begin
			if (ena) begin
				if (wea) ram[addra] <= dina;
				rama_dout <= ram[addra];
			end
		end

		always @(posedge clkb) begin
			if (enb) begin
				if (web) ram[addrb] <= dinb;
				ramb_dout <= ram[addrb];
			end
		end
	end
	"write_first":
	begin
		always @(posedge clka) begin
			if (ena) begin
				if (wea) begin
					ram[addra] <= dina;
					rama_dout <= dina;
				end
				else
					rama_dout <= ram[addra];
			end
		end

		always @(posedge clkb) begin
			if (enb) begin
				if (web) begin
					ram[addrb] <= dinb;
					ramb_dout <= dinb;
				end
				else
					ramb_dout <= ram[addrb];
			end
		end
	end
	"no_change":
	begin
		always @(posedge clka) begin
			if (ena) begin
				if (wea) ram[addra] <= dina;
				else rama_dout <= ram[addra];
			end
		end

		always @(posedge clkb) begin
			if (enb) begin
				if (web) ram[addrb] <= dinb;
				else ramb_dout <= ram[addrb];
			end
		end
	end
	endcase
	endgenerate


	//RAM OUTPUT PIPE LINE--------------------------------------------------------
	reg rama_en_pipe_reg[DOUT_PIPE_NUMBER:0];
	reg ramb_en_pipe_reg[DOUT_PIPE_NUMBER:0];
	initial begin
		for(i=0;i<DOUT_PIPE_NUMBER+1;i=i+1) begin
			rama_en_pipe_reg[i] = 0;
			ramb_en_pipe_reg[i] = 0;
		end
	end

	always @(posedge clka) begin
		rama_en_pipe_reg[0] <= ena&&(~wea);
		for (i=0; i<DOUT_PIPE_NUMBER; i=i+1)
			rama_en_pipe_reg[i+1] <= rama_en_pipe_reg[i];
	end

	always @(posedge clkb) begin
		ramb_en_pipe_reg[0] <= enb&&(~web);
		for (i=0; i<DOUT_PIPE_NUMBER; i=i+1)
			ramb_en_pipe_reg[i+1] <= ramb_en_pipe_reg[i];
	end

	assign douta_valid = rama_en_pipe_reg[DOUT_PIPE_NUMBER];
	assign doutb_valid = ramb_en_pipe_reg[DOUT_PIPE_NUMBER];


	generate
	if(DOUT_PIPE_NUMBER==0) begin
		assign douta = rama_dout;
		assign doutb = ramb_dout;
	end
	else begin
		reg [DATA_WIDTH-1:0] rama_pipe_reg[DOUT_PIPE_NUMBER-1:0];
		reg [DATA_WIDTH-1:0] ramb_pipe_reg[DOUT_PIPE_NUMBER-1:0];

		always @(posedge clka) begin
			if(rama_en_pipe_reg[0])
				rama_pipe_reg[0] <= rama_dout;

			for(i=0;i<DOUT_PIPE_NUMBER-1;i=i+1)
				if(rama_en_pipe_reg[i+1])
					rama_pipe_reg[i+1] <= rama_pipe_reg[i];
		end

		always @(posedge clkb) begin
			if(ramb_en_pipe_reg[0])
				ramb_pipe_reg[0] <= ramb_dout;

			for(i=0;i<DOUT_PIPE_NUMBER-1;i=i+1)
				if(ramb_en_pipe_reg[i+1])
					ramb_pipe_reg[i+1] <= ramb_pipe_reg[i];
		end

		assign douta = rama_pipe_reg[DOUT_PIPE_NUMBER-1];
		assign doutb = ramb_pipe_reg[DOUT_PIPE_NUMBER-1];
	end
	endgenerate

endmodule
