
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
	input freq_step_reset_in,
	output reg freq_step_out,
	output [3:0] debug
);

parameter NUM_FREQ_STEPS = 32;
parameter RECORD_TICKS = 15000;

reg [3:0] state, next_state;
reg [7:0] freq_step_count;
reg [15:0] record_count;
reg next_freq_step;
reg freq_step_count_incr;
reg freq_step_count_reset;
reg [19:0] state_wait_ctr;
reg state_wait_incr;

assign debug = 4'h0; //Not currently used...

always @(posedge clock) begin
	if(reset) begin
		state <= `STATE_RESET;
		freq_step_out <= 1'b0;
		freq_step_count <= 0;
		record_count <= 0;
		state_wait_ctr <= 0;
	end else begin
		freq_step_out <= next_freq_step;

		if(freq_step_reset_in)
			state <= `STATE_RESET;
		else
			state <= next_state;
		
		if(next_state != state)
			state_wait_ctr <= 0;
		else if(state_wait_incr)
			state_wait_ctr <= state_wait_ctr + 20'd1;
			
		if(rx_record)
			record_count <= record_count + 16'd1;
		else
			record_count <= 16'd0;
			
		if(freq_step_count_incr)
			freq_step_count <= freq_step_count + 8'd1;
		if(freq_step_count_reset)
			freq_step_count <= 0;
	end
end

always @* begin
next_state = state;
next_freq_step = 1'b0;
rx_record = 1'b0;
rx_next = 1'b0;
rx_reset = 1'b0;
freq_step_count_incr = 1'b0;
freq_step_count_reset = 1'b0;
state_wait_incr = 1'b0;
case(state)
	`STATE_RESET: begin
		freq_step_count_reset = 1'b1;
		rx_reset = 1'b1;
		state_wait_incr = 1'b1;
		if(state_wait_ctr == 20'hfffff)
			next_state = `STATE_WAIT;
	end

	`STATE_WAIT: begin
		state_wait_incr = 1'b1;
		if(state_wait_ctr > 20'd640) begin
			freq_step_count_incr = 1'b1;
			next_state = `STATE_RECORD;
		end
	end

	`STATE_RECORD: begin
		rx_record = 1'b1;
		if(record_count == RECORD_TICKS) begin
			if(freq_step_count == NUM_FREQ_STEPS)
				next_state = `STATE_RESET;
			else begin
				rx_next = 1'b1;
				next_state = `STATE_NEXT;
			end
		end
	end

	`STATE_NEXT: begin
		state_wait_incr = 1'b1;
		if(state_wait_ctr < 2'd10 || state_wait_ctr > 20'd20)
			next_freq_step = 1'b1;
		if(state_wait_ctr == 20'd30)
			next_state = `STATE_WAIT;
	end
	
endcase
end

endmodule
