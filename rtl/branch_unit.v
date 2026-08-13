module branch_unit(
  input is_branch,
  input [2:0] b_type,

  input [31:0] rs1_val,
  input [31:0] rs2_val,
  output reg take_branch
);
initial begin
  take_branch = 0;
end


  always @(*) begin
  take_branch = 1'b0;

  if(is_branch) begin
    case(b_type)
      3'b000: begin
        $display("BEQ");
        if(rs1_val == rs2_val) take_branch = 1'b1;  //BEQ
      end
      3'b001: begin
        $display("BNE");
        if(rs1_val != rs2_val) take_branch = 1'b1;  //BNE
      end
      3'b100: begin
        $display("BLT");
          if($signed(rs1_val) < $signed(rs2_val)) take_branch = 1'b1;   //BLT
      end
      3'b101: begin
        $display("bge");
        if($signed(rs1_val) >= $signed(rs2_val)) take_branch = 1'b1;//BLTU
      end
      3'b110: begin
        $display("BLTU");
        if(rs1_val < rs2_val) take_branch = 1'b1; //BLTU
      end
      3'b111: begin
        $display("BGEU");
       if(rs1_val >= rs2_val) take_branch = 1'b1; //BGEU
      end
    default: take_branch = 1'b0;
    endcase
    end else begin
      take_branch = 1'b0;
    end

  end



endmodule
