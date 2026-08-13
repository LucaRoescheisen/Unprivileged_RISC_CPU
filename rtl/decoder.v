module decoder(
  input [31:0] instr,
  output reg [4:0] rd,
  output reg [4:0] rs1,
  output reg [4:0] rs2,
  output reg [31:0] imm,
  output reg [4:0] alu_op,
  output reg reg_write,
  output reg alu_src,
  output reg [2:0] b_type,
  output reg is_branch,
  output reg jal_jump,
  output reg jalr_jump,
  output reg decoder_illegal,
  output reg is_load,
  output reg is_store,
  output reg [2:0] load_type,
  output reg [2:0] store_type,
  output reg[2:0] div_op,
  output reg div_start,
  output reg is_div_instruction,
  output reg is_lui,
  output reg cpu_halt,
  output reg is_auipc,
  output reg [2:0] csr_func,
  output reg csr_write_enable,
  output reg [11:0] csr_addr,
  output reg is_mret
);

  initial begin
    jal_jump = 0;
    jalr_jump = 0;
  end

  //Check Type:
always @(*) begin //Anytime the input signal changes
  rd = 0; rs1 = 0; rs2 = 0; imm = 0;        //Prevent latches
  alu_op = 0; reg_write = 0; is_branch = 0;
  alu_src = 0; b_type = 0; jalr_jump = 0;
  jal_jump = 0;
  is_load = 0;load_type = 0;
  is_store = 0; decoder_illegal = 0;
  store_type= 0; div_start = 0; is_div_instruction = 0;
  is_lui = 0; is_auipc = 0; csr_write_enable = 0;
  is_mret = 0;
  case(instr[6:0])     //Identify OP code
    7'b1110011: begin  //E-CALL E-BREAK
      case(instr[31:20])
        12'b000000000000: begin
          cpu_halt = 1;
              $display("ecall");
        end
        12'b000000000001:
        begin
          cpu_halt = 1;
              $display("ebreak");
        end
        default: cpu_halt = 0;
      endcase
      case(instr[14:12])
        3'b000 : begin //SYSTEM FUNCTIONS
          case (instr[31:20])
            12'h302: begin
              is_mret = 1;
            end
            default: begin
              is_mret = 0;
            end
          endcase

        end


        3'b001 : begin      //CSRRW
          rs1 = instr[19:15];
          rd = instr[11:7];
          csr_addr = instr[31:20];
          csr_func = instr[14:12];
          csr_write_enable = 1;
          reg_write = 1;
          decoder_illegal = 0;
        end
        3'b010 : begin      //CSRRS
          rs1 = instr[19:15];
          csr_func = instr[14:12];
          csr_addr = instr[31:20];
          csr_write_enable = 1;
          reg_write = 1;
          decoder_illegal = 0;
        end
        3'b011 : begin      //CSRRC
          rs1 = instr[19:15];
          rd = instr[11:7];
          csr_addr = instr[31:20];
          csr_func = instr[14:12];
          csr_write_enable = 1;
          reg_write = 1;
          decoder_illegal = 0;
        end
        3'b100 : begin      //CSRRWI
          rd = instr[11:7];
          csr_addr = instr[31:20];
          imm = {27'b0, instr[19:15]};
          csr_func = instr[14:12];
          csr_write_enable = 1;
          reg_write = 1;
          decoder_illegal = 0;
        end
        3'b101 : begin      //CSRRSI
          csr_func = instr[14:12];
           imm = {27'b0, instr[19:15]};
          csr_write_enable = 1;
          reg_write = 1;
          decoder_illegal = 0;
        end
        3'b110 : begin      //CSRRCI
          rd = instr[11:7];
          imm = {27'b0, instr[19:15]};
          csr_write_enable = 1;
          csr_func = instr[14:12];
          reg_write = 1;
          decoder_illegal = 0;
        end
        default : begin
          csr_write_enable = 0;
          reg_write = 0;
          rs1 = 5'bx;
          csr_func = 0;
          decoder_illegal = 1;
        end
      endcase
    end

    7'b0010111: begin //AUIPC
      rd = instr[11:7];
      imm = {instr[31:12], 12'b0};
      reg_write = 1'b1;
      is_auipc = 1'b1;
      decoder_illegal = 0;

    end

    7'b0110111: begin //LUI
      rd = instr[11:7];
      imm = {instr[31:12], 12'b0};
      reg_write = 1'b1;
      is_lui = 1'b1;
      decoder_illegal = 0;

    end

    7'b0110011: begin //ALU R-Type
      rd  = instr[11:7];
      rs1 = instr[19:15];
      rs2 = instr[24:20];
      reg_write = 1;
      decoder_illegal = 0;

    end
    7'b0010011: begin  //ALU I-Type
      rd  = instr[11:7];
      rs1 = instr[19:15];
      imm = {{20{instr[31]}}, instr[31:20]};
      reg_write = 1;
      decoder_illegal = 0;
    end
    7'b1100011: begin  //ALU B-Type
      rs1 = instr[19:15];
      rs2 = instr[24:20];
      imm = { {20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0 }; //Add 1'b0 to shift right (2x's jump value)
      reg_write = 0;
      is_branch = 1;
      decoder_illegal = 0;
    end
    7'b1101111: begin  //J-Type format : JAL
      rd = instr[11:7];
      imm = { {12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0 };
      jal_jump = 1'b1;
      reg_write = 1;
      decoder_illegal = 0;
    end

    7'b1100111: begin // I-Type format : JALR
      rd = instr[11:7];
      rs1 = instr[19:15];
      imm = {{20{instr[31]}}, instr[31:20]};
      jalr_jump = 1'b1;
      reg_write = 1;
      decoder_illegal = 0;
    end
    7'b0000011: begin // I-type : LOAD
      rs1 = instr[19:15];
      rd  = instr[11:7];
      imm = {{20{instr[31]}}, instr[31:20]};
      is_load = 1'b1;
      load_type = instr[14:12];
      decoder_illegal = 0;
      reg_write = 1;
    end



    7'b0100011: begin //S-Type : STORE
      is_store = 1'b1;
      store_type = instr[14:12];
      imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      rs1 = instr[19:15];
      rs2 = instr[24:20];
      decoder_illegal = 0;
    end



    default begin
       is_lui = 0;
       cpu_halt = 0;
       is_auipc = 0;
      store_type= 3'b0;
      is_load = 1'b0;
      is_store = 1'b0;
      reg_write = 1'b0;
      is_branch = 1'b0;
      jal_jump  = 1'b0;
      jalr_jump = 1'b0;
      rs1 = 5'bx;
      rs2 = 5'bx;
      imm = 32'bx;
      is_load = 1'b0;
      load_type = 3'bx;
      decoder_illegal = 1;
    end
  endcase

  case(instr[6:0])  //Check OP Code again
    7'b0110011 : begin // R-Type
      case(instr[14:12]) //func3
        3'b000 : begin
          case(instr[31:25])
            7'b0000000: alu_op = 5'b00000; //ADD
            7'b0100000: alu_op = 5'b00001; //SUB
            7'b0000001: alu_op = 5'b10011;  //MUL
            default : alu_op = 5'b0;
          endcase
        end
        3'b100 :  begin
           case(instr[31:25])
             7'b0000000: alu_op = 5'b00010; //XOR
             7'b0000001: begin
                div_op = 3'b100; // DIV
                div_start = 1'b1;
                is_div_instruction = 1'b1;
                $display("DIV");

             end
             default : alu_op = 5'b0;
          endcase
        end
        3'b110 : begin
           case(instr[31:25])
             7'b0000000: alu_op = 5'b00011; //OR
             7'b0000001: begin
                div_op = 3'b110; // REMAINDER
                div_start = 1'b1;
                is_div_instruction = 1'b1;
                 $display("R");

             end
              default : begin
               alu_op = 5'b0;
               div_op = 3'b0;
              end
          endcase
        end


        3'b111 : begin
           case(instr[31:25])
             7'b0000000: alu_op = 5'b00100; //AND
             7'b0000001: begin
                div_op = 3'b111; // REMAINDER (U)
                div_start = 1'b1;
                is_div_instruction = 1'b1;
                 $display("R U");
             end
             default : alu_op = 5'b0;
          endcase
        end
        3'b001 : begin
          case(instr[31:25])
            7'b0000000: alu_op = 5'b00101; //LEFT SHIFT LOGICAL
            7'b0000001: alu_op = 5'b10100; //MUL HIGH
            default : alu_op = 5'b0;
          endcase
        end
        3'b101: begin
          case(instr[31:25])
            7'b0000000: alu_op = 5'b00110; //RIGHT SHIFT LOGICAL
            7'b0100000: alu_op = 5'b00111; //RIGHT SHIFT ARITHMETIC
            7'b0000001: begin
                div_op = 3'b101; // DIV (U)
                div_start = 1'b1;
                is_div_instruction = 1'b1;
                $display("DIV U");
             end
             default : alu_op = 5'b0;
          endcase
        end
        3'b010 : begin
           case(instr[31:25])
             7'b0000000: alu_op = 5'b01000;  //LESS THAN
             7'b0000001: alu_op = 5'b10101; //MUL HIGH (S) (U)
             default : alu_op = 5'b0;
          endcase
        end
        3'b011 : begin
           case(instr[31:25])
             7'b0000000: alu_op = 5'b01001;  //LESS THAN (U)
             7'b0000001: alu_op = 5'b10110; //MUL HIGH (U)
             default : alu_op = 5'b0;
          endcase
        end
      endcase
    end

      //M Extension
      7'b0010011: begin //I-Type
      case(instr[14:12])
        3'b000 : alu_op = 5'b01010;  //ADD IMMEDIATE
        3'b100 : alu_op = 5'b01011;  //XOR IMMEDIATE
        3'b110 : alu_op = 5'b01100;  //OR IMMEDIATE
        3'b111 : alu_op = 5'b01101;  //AND IMMEDIATE
        3'b001 : alu_op = 5'b01110;  //SHIFT LEFT LOGICAL IMMEDIATE (rd=rs1<<imm[0:4])
        3'b101 :  begin
          case(imm[11:5])
            7'b0000000 : alu_op = 5'b01111; //SHIFT RIGHT LOGICAL IMMEDIATE
            7'b0100000 : alu_op = 5'b10000; //SHIFT RIGHT ARITHMETIC IMMEDIATE
            default : alu_op = 5'b0;
          endcase
        end
        3'b010 : alu_op = 5'b10001; // LESS THAN IMMEDIATE
        3'b011 : alu_op = 5'b10010; // LESS THAN IMMEDIATE UNSIGNED
        default : alu_op = 5'b0;
        endcase
    end

    7'b1100011: begin //B-Type
      b_type = instr[14:12];
    end

    default: begin
      alu_op = 5'b0;
      b_type = 3'bx;
      div_op = 3'bx;
      div_start = 1'b0;
     is_div_instruction = 1'b0;
    end
  endcase

  case (instr[6:0])
    7'b0110011: alu_src = 0; // R-type
    7'b0010011: alu_src = 1; // I-type
    7'b0000011: alu_src = 1; // LOAD
    7'b0100011: alu_src = 1; // STORE
    7'b1100011: alu_src = 0;// B-TYPE
    default: alu_src = 0;
  endcase

  end
endmodule
