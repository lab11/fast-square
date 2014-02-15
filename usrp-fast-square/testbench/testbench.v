`timescale 1ns/1ps

`define SD #1
`define SIM

module tb_ice();

integer j;

reg clk;
reg reset;

reg [15:0] i_in, q_in;
wire [15:0] i_out, q_out;

//Modules
fast_square_bb u0(
	.clock(clk),
	.reset(reset),
	.freq_step(1'b0),
	.record(1'b0),
	.data_out_strobe(),
	.i_in(i_in),
	.q_in(q_in),
	.i_out(i_out),
	.q_out(q_out)
);

initial
begin
	//Initialize the clock...
	clk = 0;
	reset = 0;

	i_in = 16'h1000;
	q_in = 16'h0100;

	//Wait for the reset circuitry to kick in...
	@ (posedge clk);
	@ (posedge clk);
	@ (posedge clk);
	`SD reset = 1;
	@ (posedge clk);
	@ (posedge clk);
	`SD reset = 0;
	@ (posedge clk);
	@ (posedge clk);
	@ (posedge clk);

	for(j = 0; j < 2000; j=j+1) begin
		q_in = 16'h0000;
		@ (posedge clk);
		q_in = 16'h0100;
		@ (posedge clk);
	end

	$stop;
end

always #1250 clk = ~clk;

endmodule // testbench
