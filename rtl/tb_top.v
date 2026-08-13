module tb_top;
  reg clk = 0;
  reg reset = 0;
  top uut(
    .clk(clk),
    .reset(reset)
  );

  always #5 clk = ~clk;

  initial begin
    $display("Starting simulation");
    reset = 1;
    #6;
    reset = 0;
    #1000;
  end

endmodule
