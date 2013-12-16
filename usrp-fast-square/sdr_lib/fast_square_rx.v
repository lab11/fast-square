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

module fast_square_rx
  (input clock,
   input reset,
   input freq_step,
   input record,
   input data_out_strobe,
   input [6:0] serial_addr, 
   input [31:0] serial_data, 
   input serial_strobe,
   input wire [15:0] i_in,
   input wire [15:0] q_in,
   output wire [15:0] i_out,
   output wire [15:0] q_out
   );

   parameter CARRIERFREQADDR = 0;
   parameter SUBCARRIERFREQADDR = 1;
	parameter FREQSHIFTADDR = 2;
   parameter RECORD_TICKS_LOG2 = 14;
   parameter NUM_SUBCARRIERS = 4;

   parameter SUM_HI = 31-(16-RECORD_TICKS_LOG2);
   parameter SUM_LO = SUM_HI-15;

   //Phase accumulator for carrier offset
   wire signed [31:0] carrier_freq_set, subcarrier_freq_set, freqshift_set;
   reg signed [31:0] carrier_freq_latched;
   setting_reg #(CARRIERFREQADDR) sr_rxfreq0(.clock(clock),.reset(1'b0),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(carrier_freq_set));
   setting_reg #(SUBCARRIERFREQADDR) sr_rxfreq1(.clock(clock),.reset(1'b0),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(subcarrier_freq_set));
	setting_reg #(FREQSHIFTADDR) sr_rxfreq2(.clock(clock),.reset(1'b0),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(freqshift_set));

	reg [31:0] carrier_phase;
   reg [31:0] subcarrier_phase [NUM_SUBCARRIERS-1:0];
   reg signed [31:0] subcarrier_freq [NUM_SUBCARRIERS-1:0];
	reg [15:0] time_since_last_record, time_since_last_record_latched;

   //Subcarrier mixers
   wire [15:0] bb_i[NUM_SUBCARRIERS-1:0];
   wire [15:0] bb_q[NUM_SUBCARRIERS-1:0];
   genvar i;
   generate
     for(i=0; i < NUM_SUBCARRIERS; i=i+1) begin:COR
       cordic rx_cordic
         ( .clock(clock),.reset(reset),.enable(1'b1), 
           .xi(i_in),.yi(q_in),.zi(carrier_phase[31:16] + subcarrier_phase[i][31:16]),
           .xo(bb_i[i]),.yo(bb_q[i]),.zo() );
     end
   endgenerate

   reg [31:0] subcarrier_sum_i[NUM_SUBCARRIERS-1:0];
   reg [31:0] subcarrier_sum_q[NUM_SUBCARRIERS-1:0];
	reg [31:0] freq_step_small, freq_step_large;

   reg [31:0] subcarrier_sum_i_latched[NUM_SUBCARRIERS-1:0];
   reg [31:0] subcarrier_sum_q_latched[NUM_SUBCARRIERS-1:0];

   reg restart_data, new_data;
   reg [3:0] new_data_ctr;

   integer ii;
   always @(posedge clock) begin
     if(reset) begin
       carrier_phase <= #1 32'b0;
       for(ii=0; ii < NUM_SUBCARRIERS; ii=ii+1) begin
         subcarrier_phase[ii] <= #1 32'b0;
			subcarrier_sum_i[ii] <= #1 32'b0;
			subcarrier_sum_q[ii] <= #1 32'b0;
       end
       carrier_freq_latched <= #1 carrier_freq_set;

       //TODO: Figure out how to get this into the for..loop
       subcarrier_freq[0] <= #1 -((subcarrier_freq_set << 1) + subcarrier_freq_set);
       subcarrier_freq[1] <= #1 -subcarrier_freq_set;
       subcarrier_freq[2] <= #1 subcarrier_freq_set;
       subcarrier_freq[3] <= #1 (subcarrier_freq_set << 1) + subcarrier_freq_set;
		 
		 freq_step_small <= #1 32'd1789569706 - (subcarrier_freq_set << 2) - (subcarrier_freq_set << 1);//freqshift_set - 
		 freq_step_large <= #1 32'd1789569706 - (subcarrier_freq_set << 3);

       restart_data <= #1 1'b1;
       new_data <= #1 1'b0;
       new_data_ctr <= #1 0;
		 time_since_last_record <= #1 16'd0;
		 time_since_last_record_latched <= #1 16'd0;
     end else begin
       
       if(freq_step) begin
         for(ii=0; ii < NUM_SUBCARRIERS; ii=ii+1) begin //TODO: Needs more...
				if(subcarrier_freq[1] > -freq_step_small)
					subcarrier_freq[ii] <= #1 subcarrier_freq[ii] + freq_step_large;
				else
					subcarrier_freq[ii] <= #1 subcarrier_freq[ii] + freq_step_small;
			end
       end
		 if(record) begin
			carrier_phase <= #1 carrier_phase + carrier_freq_latched;
			for(ii=0; ii < NUM_SUBCARRIERS; ii=ii+1) begin
				subcarrier_phase[ii] <= #1 subcarrier_phase[ii] - subcarrier_freq[ii];
			end
		 end else begin
			carrier_phase <= #1 0;
			for(ii=0; ii < NUM_SUBCARRIERS; ii=ii+1) begin
				subcarrier_phase[ii] <= #1 0;
			end
			time_since_last_record <= #1 time_since_last_record + 16'd1;
		 end

       //Averaging logic
       if(freq_step) begin
         restart_data <= #1 1'b0;
         new_data <= #1 1'b1;
			new_data_ctr <= #1 0;
			time_since_last_record_latched <= #1 time_since_last_record;
         for(ii=0; ii < NUM_SUBCARRIERS; ii=ii+1) begin
				subcarrier_sum_i_latched[ii] <= #1 subcarrier_sum_i[ii];
				subcarrier_sum_q_latched[ii] <= #1 subcarrier_sum_q[ii];
				subcarrier_sum_i[ii] <= #1 0;
				subcarrier_sum_q[ii] <= #1 0;
			end
       end else if(record) begin
         for(ii=0; ii < NUM_SUBCARRIERS; ii=ii+1) begin
				subcarrier_sum_i[ii] <= #1 subcarrier_sum_i[ii] + {{16{bb_i[ii][15]}},bb_i[ii]};
				subcarrier_sum_q[ii] <= #1 subcarrier_sum_q[ii] + {{16{bb_q[ii][15]}},bb_q[ii]};
			end
       end
       
       //Final code used for dispatching the received subcarrier sums
       if(data_out_strobe && new_data) begin
         new_data_ctr <= #1 new_data_ctr + 4'd1;
			if(new_data_ctr == NUM_SUBCARRIERS*2) begin
				new_data <= #1 1'b0;
				new_data_ctr <= #1 0;
			end
       end
     end
   end

   assign i_out = (restart_data) ? 16'h8000 : 
						(new_data && new_data_ctr < NUM_SUBCARRIERS) ? subcarrier_sum_i_latched[new_data_ctr[1:0]][31:16] : 
						(new_data && new_data_ctr < NUM_SUBCARRIERS*2) ? subcarrier_sum_q_latched[new_data_ctr[1:0]][31:16] :
						(new_data) ? time_since_last_record_latched : 16'h8000;
   assign q_out = (restart_data) ? 16'h8000 : 
						(new_data && new_data_ctr < NUM_SUBCARRIERS) ? subcarrier_sum_i_latched[new_data_ctr][15:0] : 
						(new_data && new_data_ctr < NUM_SUBCARRIERS*2) ? subcarrier_sum_q_latched[new_data_ctr[1:0]][15:0] : 16'h0000;
   
endmodule
