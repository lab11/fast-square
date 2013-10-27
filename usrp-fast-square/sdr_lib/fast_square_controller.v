
`define STATE_RESET 0
`define STATE_WAIT 1
`define STATE_RECORD 2
`define STATE_NEXT 3

module fast_square_controller(
	input clock,
	input reset,
	input pll_locked,
	output reg rx_record,
	output reg rx_reset,
	output reg rx_next,
	output reg freq_step_reset_out,
	output reg freq_step_out
);

parameter RECORD_TICKS = 15000;

reg [3:0] state, next_state;
reg [7:0] freq_step_count;
reg [15:0] record_count;
reg next_freq_step_reset;
reg freq_step_count_incr;
reg freq_step_count_reset;
wire pll_locked_db;

debouce db0(.clock(clock), .in(pll_locked), .out(pll_locked_db));

always @(posedge clock) begin
	if(reset) begin
		state <= `STATE_RESET;
		freq_step_reset_out <= 1'b1;
		freq_step_out <= 1'b0;
		freq_step_count <= 0;
		record_count <= 0;
	end else begin
		state <= next_state;
		freq_step_reset_out <= next_freq_step_reset;
		freq_step_out <= next_freq_step;
		if(rx_record)
			record_count <= record_count + 1;
		if(freq_step_count_incr)
			freq_step_count <= freq_step_count + 1;
		if(freq_step_count_reset)
			freq_step_count <= 0;
	end
end

always @* begin
next_state = state;
next_freq_step_reset = 1'b0;
next_freq_step = 1'b0;
rx_record = 1'b0;
rx_next = 1'b0;
rx_reset = 1'b1;
freq_step_count_incr = 1'b0;
freq_step_count_reset = 1'b0;
case(state)
	`STATE_RESET: begin
		next_freq_step_reset = 1'b1;
		freq_step_count_reset = 1'b1;
		rx_reset = 1'b1;
		if(pll_locked_db == 1'b0)
			next_state = `STATE_WAIT;
	end

	`STATE_WAIT: begin
		if(pll_locked_db == 1'b1)
			freq_step_count_incr = 1'b1;
			next_state = `STATE_RECORD;
	end

	`STATE_RECORD: begin
		rx_record = 1'b1;
		if(record_count == RECORD_TICKS)
			if(freq_step_count == NUM_FREQ_STEPS)
				next_state = `STATE_RESET;
			else
				rx_next = 1'b1;
				next_state = `STATE_NEXT;
	end

	`STATE_NEXT: begin
		next_freq_step = 1'b1;
		if(pll_locked_db == 1'b0)
			next_state = `STATE_WAIT;
	end
endcase
end

endmodule
