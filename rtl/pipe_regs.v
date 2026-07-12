/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSED */
module fetch_stage(
    input clk,
    input reset,
    input stall,
    input flush,
    input cpu_halt,
    input pc_src, /* verilator lint_off UNUSED */  //1 If Branch
    input [31:0] csr_pc_update,
    input [31:0] pc_target,
    input csr_update_pc,
    input [31:0] mem_instr,
    output [31:0] pc_out,
    output reg [31:0] pc, //Program counter (Holds address of current instruction)
    output pc_trap,
    output [31:0] instr_fetch_addr,
    output reg [31:0] pc_for_decode
);

  assign instr_fetch_addr = pc >> 2;
  wire [31:0] pc_4 = pc +4;
  assign pc_out = pc_4;
  /*
  The reason why we output pc+4 is to when a jump occurs that when we jump back
  we dont jump to the same instruction (infinite loop), instead we go to the next instruciton
  */



  assign pc_trap = (pc[1:0] != 2'b00);


reg pc_raw_grab;

always @(posedge clk) begin
    if(reset) begin
        pc <= 32'h0;
        pc_raw_grab <= 0;
        pc_for_decode <= 0;
    end else begin
        if(stall || cpu_halt)
            pc <= pc;

        else if(flush) begin
            pc <= pc_target;
            pc_for_decode <= pc;
        end
        else if(csr_update_pc) begin
            pc <= csr_pc_update;
            pc_for_decode <= pc;
        end
        else begin
                pc <= pc + 4;
                pc_for_decode <= pc;
        end
    end
end


endmodule


module decode_stage(
  input clk,
  input [31:0] IF_ID_instr,
  input [31:0] IF_ID_pc,

  //Writeback
  input [31:0] mem_wb_result,
  input [4:0]  wb_rd,          // Which register to write to
  input [4:0]  ram_rd_reg,
  input [31:0] wb_result,      // The data to write
  input        wb_reg_write,   // The enable signal from WB
  input        wb_is_load_reg,



  //ID-EX Registers
  output [31:0] id_rs1_val,
  output [31:0] id_rs2_val,
  output        id_reg_write_reg,
  output [31:0] id_imm_val,
  output [4:0]  id_alu_op,
  output [2:0]  id_div_op,
  output [4:0]  id_rd_addr,
  output [4:0]  id_rs1_addr,
  output [4:0]  id_rs2_addr,
  //Control Signals
  output        id_alu_src, // Determines whether to use rs2 or imm value
  output [2:0]  id_branch_type,
  output        id_is_branch,
  output        id_jal_jump,
  output        id_jalr_jump,
  output        id_decoder_illegal,
  output        id_is_load,
  output        id_is_store,
  output [2:0]  id_load_type,
  output [2:0]  id_store_type,
  output        id_div_start,
  output        id_div_instruction,
  output        id_is_lui,
  output        cpu_halt,
  output        is_auipc,
  output [2:0]  csr_func,
  output        csr_write_enable,
  output        wrote_to_regfile,
  output [11:0] csr_addr,
  output        is_mret
 );
  wire [4:0] rs1_wire;
  wire [4:0] rs2_wire;
  wire [4:0] rd_wire;
  assign id_rd_addr = rd_wire;

  wire [31:0] wb_final_data = (wb_is_load_reg) ? mem_wb_result : wb_result;

  assign id_rs1_addr = rs1_wire;
  assign id_rs2_addr = rs2_wire;






  decoder decoder_module(
    .instr(IF_ID_instr),
    .rd(rd_wire),
    .rs1(rs1_wire),
    .rs2(rs2_wire),
    .imm(id_imm_val),
    .alu_op(id_alu_op),
    .reg_write(id_reg_write_reg),
    .alu_src(id_alu_src),
    .b_type(id_branch_type),
    .is_branch(id_is_branch),
    .jal_jump(id_jal_jump),
    .jalr_jump(id_jalr_jump),
    .decoder_illegal(id_decoder_illegal),
    .is_load(id_is_load),
    .is_store(id_is_store),
    .load_type(id_load_type),
    .store_type(id_store_type),
    .div_op(id_div_op),
    .div_start(id_div_start),
    .is_div_instruction(id_div_instruction),
    .is_lui(id_is_lui),
    .cpu_halt(cpu_halt),
    .is_auipc(is_auipc),
    .csr_func(csr_func),
    .csr_write_enable(csr_write_enable),
    .csr_addr(csr_addr),
    .is_mret(is_mret)
  );


  regfile reg_file_module(
    .clk(clk),
    .rs1(rs1_wire),
    .rs2(rs2_wire),
    .rd(wb_rd),
    .result(wb_final_data),
    .csr_write_enable(csr_write_enable),
    .reg_write(wb_reg_write),
    .rs1_val(id_rs1_val),
    .rs2_val(id_rs2_val),
    .wrote_to_regfile(wrote_to_regfile)
  );

endmodule



module execute_stage(
  input clk,
  input reset,
  input stall,
  input [31:0] id_pc_reg,
  input [31:0] id_pc_4_reg,
  // Data from ID/EX Registers
  input [31:0] id_rs1_val_reg,
  input [31:0] id_rs2_val_reg,
  input [31:0] id_imm_val_reg,
  // Control from ID/EX Registers
  input id_alu_src_reg,
  input id_is_branch_reg,
  input [2:0] id_branch_type_reg,
  input id_jal_jump_reg,
  input id_jalr_jump_reg,

  input [4:0] id_alu_op_reg,
  input [2:0] id_div_op_reg,
  input       id_div_instruction,
  input       id_ex_is_lui_reg,
  input        id_ex_is_auipc,
//Forwarding Values:
  input        ex_mem_reg_write_reg,
  input [4:0]  ex_mem_rd,
  input [4:0]  mem_wb_rd,
  input [4:0]  id_rs1_addr,
  input [4:0]  id_rs2_addr,
  input [31:0] ex_mem_result_reg,
  input [31:0] mem_wb_result_reg,
  input        mem_wb_write_reg,

  input [2:0] load_type,
  input [2:0] store_type,
  input is_load,
  input is_store,
  // Outputs to EX/MEM Register
  output [31:0] ex_result,
  output        flush,
  output [31:0] ex_pc_target,
  output [31:0] ex_ram_address,
  //Control
  output divider_busy,
  output divider_finished_comb,
  output reg misaligned,
  output [31:0] csr_w_data,
  output send_to_uart
);
 reg is_branch_reg;
reg [2:0] branch_type_reg;
 reg [31:0] forward_a_reg, forward_b_reg;
reg [4:0] alu_op_reg;
reg divider_trigger_reg;
reg [2:0] div_op_reg;
reg div_instruction_reg;
reg is_lui_reg;
reg [31:0] imm_val_reg;
reg is_auipc_reg;
reg [31:0] id_pc_reg_r;
reg jal_jump_reg;
reg  jalr_jump_reg;
reg [31:0] pc_4_reg;

  wire [31:0] forward_val_b;
  wire [31:0] forward_val_a;
  wire [31:0] forward_val_b_inter;

  wire [31:0] div_result, alu_result;
  wire [31:0] alu_b = id_alu_src_reg ? id_imm_val_reg : forward_val_b;
  wire [31:0] result = div_instruction_reg ? div_result : (is_lui_reg) ? imm_val_reg : (is_auipc_reg) ? (id_pc_reg_r + imm_val_reg) : alu_result;

  wire divider_finished;
  assign divider_finished_comb = div_instruction_reg && divider_finished;
  wire div_busy;
  assign divider_busy = div_busy;
  wire divider_trigger;
  assign divider_trigger = div_instruction_reg && !div_busy && !divider_finished;

  wire take_branch;
  wire ex_jump_branch_taken;
  wire [31:0] target_pc_imm; // For JAL and Branches
  assign target_pc_imm   = id_pc_reg_r + imm_val_reg;
  wire [31:0] target_rs1_imm; //For JALR
  assign target_rs1_imm  = (forward_a_reg + imm_val_reg ) & ~32'h1;
  assign ex_jump_branch_taken = jal_jump_reg || jalr_jump_reg || (is_branch_reg && take_branch);


  assign flush = jal_jump_reg || jalr_jump_reg || (is_branch_reg && take_branch);

  assign ex_pc_target = ((jalr_jump_reg) ? target_rs1_imm : target_pc_imm);

  //RAM Address
  assign ex_ram_address = forward_a_reg + imm_val_reg;

  //check for misaligned bit

  always @(*) begin
    misaligned = 1'b0;
    if(is_load) begin
      misaligned = (load_type == 3'b010 && ex_ram_address[1:0] != 2'b00) |
                    (load_type == 3'b01 && ex_ram_address[0] != 1'b0);
    end
    else if(is_store) begin
      misaligned = (store_type == 3'b010 && ex_ram_address[1:0] != 2'b00) |
                    (store_type == 3'b01 && ex_ram_address[0] != 1'b0);
    end
  end

  //Result Handling
  assign ex_result = (jal_jump_reg || jalr_jump_reg) ? pc_4_reg:  result;

  assign csr_w_data = forward_val_a;
  assign forward_val_a =
    (ex_mem_reg_write_reg && (ex_mem_rd != 0) && (ex_mem_rd == id_rs1_addr)) ? ex_mem_result_reg :
    (mem_wb_write_reg     && (mem_wb_rd != 0) && (mem_wb_rd == id_rs1_addr))  ? mem_wb_result_reg :
    id_rs1_val_reg ;

   assign forward_val_b_inter =
    (ex_mem_reg_write_reg && (ex_mem_rd != 0) && (ex_mem_rd == id_rs2_addr)) ? ex_mem_result_reg :
    (mem_wb_write_reg     && (mem_wb_rd != 0) && (mem_wb_rd == id_rs2_addr)) ? mem_wb_result_reg :
    id_rs2_val_reg;


  assign forward_val_b = id_alu_src_reg ? id_imm_val_reg : forward_val_b_inter;


  //Check whether its part of the memory area or periphercal section
  assign send_to_uart = ex_ram_address >= 32'h10000004;



 always @(posedge clk) begin
  if(reset) begin
    forward_a_reg <= 0;
    forward_b_reg <= 0;
    alu_op_reg    <= 0;
    divider_trigger_reg <= 0;
    div_op_reg <= 0;
    is_branch_reg <= 0;
    branch_type_reg <= 0;
    div_instruction_reg <= 0;
    is_lui_reg <= 0;
    imm_val_reg <= 0 ;
    is_auipc_reg <= 0;
    id_pc_reg_r <= 0;
    jal_jump_reg <= 0;
    jalr_jump_reg <= 0;
    pc_4_reg <= 0;
  end
  else if(!stall) begin
    forward_a_reg <= forward_val_a;
    forward_b_reg <= alu_b;
    alu_op_reg <= id_alu_op_reg;
    divider_trigger_reg <= divider_trigger;
    div_op_reg <= id_div_op_reg;
    is_branch_reg <= id_is_branch_reg;
    branch_type_reg <= id_branch_type_reg;
    div_instruction_reg <= id_div_instruction;
    is_lui_reg <= id_ex_is_lui_reg;
    imm_val_reg <= id_imm_val_reg ;
    is_auipc_reg <= id_ex_is_auipc;
    id_pc_reg_r <= id_pc_reg;
    jal_jump_reg <= id_jal_jump_reg;
    jalr_jump_reg <= id_jalr_jump_reg;
    pc_4_reg <= id_pc_4_reg;
  end

 end

  alu alu_module(
    .a(forward_a_reg),
    .b(forward_b_reg),
    .alu_op(alu_op_reg),
    .result(alu_result)
  );


    divider divider_module(
    .clk(clk),
    .divisor(forward_b_reg),
    .dividend(forward_a_reg),
    .start(divider_trigger_reg),
    .div_op(div_op_reg),
    .result(div_result),
    .busy(div_busy),
    .finished(divider_finished)
  );



  branch_unit branch_unit_module(
    .is_branch(is_branch_reg),
    .b_type(branch_type_reg),
    .rs1_val(forward_a_reg),
    .rs2_val(forward_b_reg),
    .take_branch(take_branch)
  );









endmodule




