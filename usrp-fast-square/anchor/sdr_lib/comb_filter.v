
module comb_filter(clock, reset, i_in, q_in, i_out, q_out);

parameter BIT_WIDTH = 16;
parameter DELAY_LOG2 = 4;
parameter FB_SHIFT = 3;

input clock;
input reset;
input [BIT_WIDTH-1:0] i_in;
input [BIT_WIDTH-1:0] q_in;
output [BIT_WIDTH-1:0] i_out;
output [BIT_WIDTH-1:0] q_out;

reg [DELAY_LOG2-1:0] hist_counter;
reg [BIT_WIDTH+FB_SHIFT-1:0] i_hist[2**DELAY_LOG2-1:0];
reg [BIT_WIDTH+FB_SHIFT-1:0] q_hist[2**DELAY_LOG2-1:0];

wire signed [BIT_WIDTH+FB_SHIFT-1:0] i_sum = {{FB_SHIFT{i_in[BIT_WIDTH-1]}},i_in} - i_hist[hist_counter] + {{FB_SHIFT{i_hist[hist_counter][BIT_WIDTH+FB_SHIFT-1]}},i_hist[hist_counter][BIT_WIDTH+FB_SHIFT-1:FB_SHIFT]};
wire signed [BIT_WIDTH+FB_SHIFT-1:0] q_sum = {{FB_SHIFT{q_in[BIT_WIDTH-1]}},q_in} - q_hist[hist_counter] + {{FB_SHIFT{q_hist[hist_counter][BIT_WIDTH+FB_SHIFT-1]}},q_hist[hist_counter][BIT_WIDTH+FB_SHIFT-1:FB_SHIFT]};

reg [BIT_WIDTH+FB_SHIFT-1:0] i_sum_reg;
reg [BIT_WIDTH+FB_SHIFT-1:0] q_sum_reg;

assign i_out = i_sum_reg[BIT_WIDTH+FB_SHIFT-1:FB_SHIFT];
assign q_out = q_sum_reg[BIT_WIDTH+FB_SHIFT-1:FB_SHIFT];

integer i;
always @(posedge clock) begin
	if(reset) begin
		`ifdef SIM
		for(i=0; i<2**DELAY_LOG2; i=i+1) begin
			i_hist[i] <= #1 0;
			q_hist[i] <= #1 0;
		end
		`endif

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

