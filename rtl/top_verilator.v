module top_verilator(
  input clk,
  input reset,

  output [31:0] pc_out
);

top top_mod(
  .clk(clk),
  .reset(reset)
);

assign pc_out = top_mod.pc_out_wire;




endmodule
