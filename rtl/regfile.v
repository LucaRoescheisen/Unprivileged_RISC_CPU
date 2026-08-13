module regfile(
  input clk,
  input[4:0] rs1,
  input[4:0] rs2,
  input[4:0] rd,
  input[31:0] result,
  input reg_write,
  input csr_write_enable,
  output  [31:0] rs1_val,
  output  [31:0] rs2_val,
  output reg     wrote_to_regfile
);
/*
x1 : Return Address Register never write to THIS!!!!!
x2 : Standard Stack Pointer
x5 : Alternative Link Register (some programs use this instead of x1)


*/

localparam XLEN = 32;

(* dont_touch = "true" *) reg [XLEN-1:0] int_regs [0:31];         //x0 to x32
integer i;
initial begin
    for (i = 0; i < 32; i = i + 1) begin
        int_regs[i] = 32'b0;
    end
end
// As the memory array is only updated at the end of the clock cycle we want to get result directly
assign rs1_val = (rs1 == rd && reg_write && rs1 != 0) ? result : int_regs[rs1];
assign rs2_val = (rs2 == rd && reg_write && rs2 != 0) ? result : int_regs[rs2];


always @(posedge clk) begin
  if ((reg_write || csr_write_enable) && rd != 0) begin
    $display("Regfile: x%0d = 0x%08x", rd, result);
    int_regs[rd] <= result;
    wrote_to_regfile <= 1;
  end

end

endmodule
