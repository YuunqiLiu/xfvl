`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2018/04/20 23:32:32
// Design Name:
// Module Name: ram_sp_rst
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module ram_sp #(
    parameter DATA_WIDTH 				= 36,
    parameter ADDR_WIDTH 				= 14,
    parameter RAM_DEPTH 				= 4096,
    parameter DOUT_PIPE_NUMBER 			= 4,
    parameter RAM_TYPE 					= "ultra",
	//block,ultra,distributed,registers
	parameter RAM_BEHAVIOR 				= "read_first",
	//read_first,write_first,no_change
	parameter CASCADE_HEIGHT 			= 100
    )(
    input 					clk,
    input 					en,
    input 					we,
    input [ADDR_WIDTH-1:0] 	addr,
    input [DATA_WIDTH-1:0] 	din,
    output [DATA_WIDTH-1:0] dout,
    output                  dout_valid
    );

    integer i;
    reg [DATA_WIDTH-1:0] ram_dout;
    (* ram_style = RAM_TYPE , cascade_height = CASCADE_HEIGHT *) reg [DATA_WIDTH-1:0] ram [RAM_DEPTH-1:0];


	//RAM DEFINE-------------------------------------------------------------------
	generate
	case(RAM_BEHAVIOR)
	"read_first":
	begin
		always @(posedge clk) begin
			if(en) begin
				if (we) ram[addr] <= din;
				ram_dout <= ram[addr];
			end
		end
	end
	"write_first":
	begin
		always @(posedge clk) begin
			if(en) begin
				if (we) begin
					ram[addr] <= din;
					ram_dout <= din;
				end
				else ram_dout <= ram[addr];
			end
		end
	end
	"no_change":
	begin
		always @(posedge clk) begin
			if(en) begin
				if (we) ram[addr] <= din;
				else ram_dout <= ram[addr];
			end
		end
	end
	endcase
	endgenerate


	//RAM OUTPUT PIPE LINE--------------------------------------------------------
	reg ram_en_pipe_reg[DOUT_PIPE_NUMBER:0];
	initial begin
		for(i=0;i<DOUT_PIPE_NUMBER+1;i=i+1) ram_en_pipe_reg[i] = 0;
	end

	always @(posedge clk) begin
		ram_en_pipe_reg[0] <= en&&(~we);
		for (i=0; i<DOUT_PIPE_NUMBER; i=i+1)
			ram_en_pipe_reg[i+1] <= ram_en_pipe_reg[i];
	end

	assign dout_valid = ram_en_pipe_reg[DOUT_PIPE_NUMBER];


	generate
	if(DOUT_PIPE_NUMBER==0) begin
		assign dout = ram_dout;
	end
	else begin
		reg [DATA_WIDTH-1:0] ram_pipe_reg[DOUT_PIPE_NUMBER-1:0];

		always @(posedge clk) begin
			if(ram_en_pipe_reg[0])
				ram_pipe_reg[0] <= ram_dout;

			for(i=0;i<DOUT_PIPE_NUMBER-1;i=i+1)
				if(ram_en_pipe_reg[i+1])
					ram_pipe_reg[i+1] <= ram_pipe_reg[i];
		end

		assign dout = ram_pipe_reg[DOUT_PIPE_NUMBER-1];
	end
	endgenerate


endmodule
