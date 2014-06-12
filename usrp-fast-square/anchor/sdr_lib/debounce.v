module debounce(
  input wire clk,
  input wire in,

  output reg out
);

reg [15:0] db_shift;

always @(posedge clk) begin
  db_shift <= {db_shift[14:0],in};
  out <= db_shift[15] & db_shift[14] & db_shift[13] & db_shift[12] & db_shift[11]; 
end

endmodule
