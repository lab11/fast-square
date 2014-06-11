// -*- verilog -*-
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Boston, MA  02110-1301  USA
//

//`include "config.vh"	// resolved relative to project root

module fast_square_bb_comb(
	input clock,
	input ext_reset,
	input reset,
	input freq_step,
	input record,
	output data_out_strobe,
	input wire signed [15:0] i_in,
	input wire signed [15:0] q_in,
	output wire [15:0] i_out,
	output wire [15:0] q_out
);

//This signal processing chain consists of two serial COMB filters followed by a decimate-by-17 block
wire [15:0] i_comb_out, q_comb_out;
comb_filter(
	.clock(clock),
	.reset(reset),
	.i_in(i_in),
	.q_in(q_in),
	.i_out(i_comb_out),
	.q_out(q_comb_out)
);

wire [15:0] i_comb2_out, q_comb2_out;
comb_filter(
	.clock(clock),
	.reset(reset),
	.i_in(i_comb_out),
	.q_in(q_comb_out),
	.i_out(i_comb2_out),
	.q_out(q_comb2_out)
);

reg [15:0] reset_counter;
reg restart_data;

reg [5:0] data_out_counter;
assign data_out_strobe = (data_out_counter == 5'd32);
integer i;

reg [31:0] num_resets;
reg just_reset;

always @(posedge clock) begin
	if(reset | ext_reset) begin
		restart_data <= #1 1'b1;
		reset_counter <= #1 0;
		data_out_counter <= #1 0;
		just_reset <= #1 1'b1;
		if(ext_reset)
			num_resets <= #1 0;
	end else begin
		if(data_out_strobe) begin
			if(just_reset) begin
				num_resets <= #1 num_resets + 1;
				just_reset <= #1 1'b0;
			end
			data_out_counter <= #1 0;
			if(reset_counter <= 200) begin
				reset_counter <= #1 reset_counter + 1;
			end else begin
				restart_data <= #1 1'b0;
			end
		end else begin
			data_out_counter <= #1 data_out_counter + 1;
		end
		
	end
end

assign i_out = (just_reset) ? num_resets[15:0] : (restart_data) ? 16'h8000 : i_comb2_out;
assign q_out = (just_reset) ? num_resets[31:16] : (restart_data) ? 16'h8000 : q_comb2_out;

endmodule
