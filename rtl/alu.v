module alu(
  input clk,
  input [31:0] a,
  input [31:0] b,
  input [4:0] alu_op,

  output reg [31:0] result
);

  wire [63:0] full_product_s_s = $signed(a) * $signed(b); /* verilator lint_off UNUSED */
  wire [63:0] full_product_s_u = $signed(a) * b; /* verilator lint_off UNUSED */
  wire [63:0] full_product_u_u = a * b;

 reg [31:0] mult_result_reg;
  always @(posedge clk) begin
    case(alu_op)
      5'b10011: mult_result_reg <= full_product_s_s[31:0];
      5'b10100: mult_result_reg <= full_product_s_s[63:32];
      5'b10101: mult_result_reg <= full_product_s_u[63:32];
      5'b10110: mult_result_reg <= full_product_u_u[63:32];
      default:  mult_result_reg <= mult_result_reg;
    endcase
  end



always @(*) begin //Process OPCODES
  case(alu_op)
  //R-TYPE
  5'b00000 : result = a + b;                       // ADD
  5'b00001 : result = a - b;                       // SUB
  5'b00010 : result = a ^ b;                       // XOR
  5'b00011 : result = a | b;                       // OR
  5'b00100 : result = a & b;                       // AND
  5'b00101 : result = a << b[4:0];                // SLL
  5'b00110 : result = a >> b[4:0];                // SRL (logical)
  5'b00111 : result = $signed(a) >>> b[4:0];      // SRA (arithmetic)
  5'b01000 : result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
  5'b01001 : result = (a < b) ? 32'd1 : 32'd0;   // SLTU
  //I-Type
  5'b01010 : result = a + b;                       // ADDI
  5'b01011 : result = a ^ b;                       // XORI
  5'b01100 : result = a | b;                       // ORI
  5'b01101 : result = a & b;                       // ANDI
  5'b01110 : result = a << b[4:0];                // SLLI
  5'b01111 : result = a >> b[4:0];                // SRLI (logical)
  5'b10000 : result = $signed(a) >>> b[4:0];               // SRAI (arithmetic)
  5'b10001 : result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLTI
  5'b10010 : result = (a < b) ? 32'd1 : 32'd0;    // SLTIU
  //M Extension
  5'b10011,5'b10100,5'b10101,5'b10110: result = mult_result_reg;

    default:
    result = 32'bx;

  endcase
end
endmodule
