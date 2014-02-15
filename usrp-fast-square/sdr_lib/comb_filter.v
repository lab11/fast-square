
module comb_filter(clock, reset, i_in, q_in, i_out, q_out);

parameter BIT_WIDTH = 16;
parameter DELAY_LOG2 = 3;
//TODO: Delay and feedback magnitude are NOT the same thing...

input clock;
input reset;
input [BIT_WIDTH-1:0] i_in;
input [BIT_WIDTH-1:0] q_in;
input [BIT_WIDTH-1:0] i_out;
output [BIT_WIDTH-1:0] q_out;

reg [DELAY_LOG2-1:0] hist_counter;
reg [BIT_WIDTH+DELAY_LOG2-1:0] i_hist[BIT_WIDTH-1:0];
reg [BIT_WIDTH+DELAY_LOG2-1:0] q_hist[BIT_WIDTH-1:0];

wire signed [BIT_WIDTH+DELAY_LOG2-1:0] i_sum = {{DELAY_LOG2{i_comb_in[BIT_WIDTH-1]}},i_comb_in} - i_hist[hist_counter] + {{DELAY_LOG2{i_hist[hist_counter][BIT_WIDTH+DELAY_LOG2-1]}},i_hist[hist_counter][BIT_WIDTH+DELAY_LOG2-1:DELAY_LOG2]};;
wire signed [BIT_WIDTH+DELAY_LOG2-1:0] q_sum = {{DELAY_LOG2{q_comb_in[BIT_WIDTH-1]}},q_comb_in} - q_hist[hist_counter] + {{DELAY_LOG2{q_hist[hist_counter][BIT_WIDTH+DELAY_LOG2-1]}},q_hist[hist_counter][BIT_WIDTH+DELAY_LOG2-1:DELAY_LOG2]};;

reg [BIT_WIDTH+DELAY_LOG2-1:0] i_sum_reg;
reg [BIT_WIDTH+DELAY_LOG2-1:0] q_sum_reg;

always @(posedge clock) begin
	if(reset) begin
		i_sum_reg <= #1 0;
		q_sum_reg <= #1 0;

		hist_counter <= #1 0;
	end else begin
		i_sum_reg <= #1 i_sum;
		q_sum_reg <= #1 q_sum;

		hist_counter <= #1 hist_counter + 1;

		i_hist[hist_counter] <= #1 i_sum;
		q_hist[hist_counter] <= #1 q_sum;
	end
end


endmodule

