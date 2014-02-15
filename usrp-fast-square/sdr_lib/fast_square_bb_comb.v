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

reg [3:0] data_out_counter;
assign data_out_strobe = (data_out_counter == 4'hF);
integer i;

always @(posedge clock) begin
	if(reset) begin
		i_sr_out <= #1 16'd0;
		q_sr_out <= #1 16'd0;

		`ifdef SIM
		for(i=0; i<16; i=i+1) begin
			i_hist[i] <= #1 0;
			q_hist[i] <= #1 0;
		end
		`endif

		i_sum_reg <= 19'd0;
		q_sum_reg <= 19'd0;

		restart_data <= #1 1'b1;
		reset_counter <= #1 0;
		data_out_counter <= #1 0;
		hist_counter <= #1 0;
	end else begin
		i_sum_reg <= i_sum;
		q_sum_reg <= q_sum;

		data_out_counter <= #1 data_out_counter + 1;
		hist_counter <= #1 hist_counter + 1;

		i_dc_ave <= #1 i_dc_ave + {{8{i_dc_incr[15]}},i_dc_incr,8'd0};
		q_dc_ave <= #1 q_dc_ave + {{8{q_dc_incr[15]}},q_dc_incr,8'd0};
	
		i_sr_out <= #1 {i_sr_out[14:0], (i_sum > 0)};
		q_sr_out <= #1 {q_sr_out[14:0], (q_sum > 0)};

		i_hist[hist_counter] <= #1 i_sum;
		q_hist[hist_counter] <= #1 q_sum;

		i_hist2[hist_counter] <= #1 i_sum2;
		q_hist2[hist_counter] <= #1 q_sum2;
		
		if(data_out_strobe) begin
			if(reset_counter <= 200) begin
				reset_counter <= #1 reset_counter + 1;
			end else begin
				restart_data <= #1 1'b0;
			end
		end
		
	end
end

assign i_out = (restart_data) ? 16'h8000 : i_comb2_out;
assign q_out = (restart_data) ? 16'h8000 : q_comb2_out;

endmodule
