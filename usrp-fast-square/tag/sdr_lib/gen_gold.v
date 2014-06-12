module gen_gold(
	input clk,
	input reset,

	output reg gold_out
);

parameter CLK_DIV=8;
parameter GOLD=63'b000001000011000101001111010001110010010110111011001101010111111;

reg [7:0] clk_div_idx;
reg [5:0] gold_idx;

always @(posedge clk) begin
	if(reset) begin
		gold_idx <= #1 6'd0;
		clk_div_idx <= #1 8'd0;
		gold_out <= #1 1'b0;
	end else begin
		gold_out <= #1 GOLD[gold_idx];
		clk_div_idx <= #1 clk_div_idx + 8'd1;
		if(clk_div_idx == CLK_DIV-1) begin
			clk_div_idx <= #1 8'd0;
			gold_idx <= #1 gold_idx + 6'd1;
			if(gold_idx == 6'd62)
				gold_idx <= #1 6'd0;
		end
	end
end

endmodule

