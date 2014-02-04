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

`include "config.vh"	// resolved relative to project root

module fast_square_bb(
	input clock,
	input reset,
	input freq_step,
	input record,
	input data_out_strobe,
	input signed wire [15:0] i_in,
	input signed wire [15:0] q_in,
	output wire [15:0] i_out,
	output wire [15:0] q_out
);

reg signed [31:0] i_dc_ave;
reg signed [31:0] q_dc_ave;

reg [15:0] i_sr_out;
reg [15:0] q_sr_out;

wire [15:0] i_dc_incr = i_in - i_dc_ave[31:16];
wire [15:0] q_dc_incr = q_in - q_dc_ave[31:16];

always @(posedge clock) begin
	if(reset) begin
		i_sr_out <= #1 16'd0;
		q_sr_out <= #1 16'd0;

		i_dc_ave <= #1 32'd0;
		q_dc_ave <= #1 32'd0;
	end else begin
		i_sr_out <= #1 {i_sr_out[14:0], (i_in > i_dc_ave)};
		q_sr_out <= #1 {q_sr_out[14:0], (q_in > q_dc_ave)};

		i_dc_ave <= #1 i_dc_ave + {{16}{i_dc_incr[15]},i_dc_incr};
		q_dc_ave <= #1 q_dc_ave + {{16}{q_dc_incr[15]},q_dc_incr};
	end
end

assign i_out = (restart_data) ? 16'h8000 : i_sr_out;
assign q_out = (restart_data) ? 16'h8000 : q_sr_out;

endmodule
