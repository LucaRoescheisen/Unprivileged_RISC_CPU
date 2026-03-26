/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */
(* keep_hierarchy = "yes" *) module top(
  input wire clk,
  input wire reset
);

  wire instr_correctly_executed;





  //Privilege
  reg [1:0] privilege; //starts at machine priv
  wire [1:0] next_privilege;
  always @(posedge clk) begin
    if(reset) privilege <= 2'b11;
    else      privilege <= next_privilege;

  end

  //Interrupt //should be inputs
  wire gpio0_irq;
  wire gpio1_irq;
  wire ext_iqr = gpio0_irq || gpio1_irq;

  //Traps
  wire is_trap;
  wire trap_illegal_instr;
  wire trap_csr_access_violation;
  wire trap_instr_addr_misaligned;
  wire trap_load_store_misaligned;
  assign is_trap = trap_illegal_instr | trap_csr_access_violation
                                      | trap_instr_addr_misaligned
                                      | trap_load_store_misaligned;

  reg [31:0] mcause_id;
  always @(*) begin
    case(1'b1)
      trap_illegal_instr         : mcause_id = 32'd1;
      trap_csr_access_violation  : mcause_id = 32'd2;
      trap_instr_addr_misaligned : mcause_id = 32'd3;
      trap_load_store_misaligned : mcause_id = 32'd4;
      default : mcause_id = 32'd0;
    endcase
  end

  //CSR
  wire [31:0] csr_r_data;

  //Hazards
  wire stall;
  wire flush;
  wire flush_from_interrupt;
  wire flush_jump;
  wire flush_trap;
  assign flush = flush_jump | flush_trap | flush_from_interrupt;
  wire cpu_halt;


  //PC Updates
  wire [31:0] csr_pc_update;
  wire csr_update_pc;
  //IFID Pipline Registers
  reg [31:0] IF_ID_instr;
  reg [31:0] IF_ID_pc_plus_4;
  reg [31:0] IF_ID_pc;


  //Fetch Wires
  wire [31:0] output_if_instr;
  wire pc_src;           //Branches
  wire [31:0] pc_target; //Jump target
  wire [31:0] pc_out_wire;    //Next PC value
  wire [31:0] IF_ID_wire;    //Current PC value

  wire [31:0] instr_fetch_addr;
  wire [31:0] pc_for_decode;
  //**     Fetch Stage     **//
  fetch_stage fetch_stage_mod(
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .flush(flush),
    .cpu_halt(cpu_halt),
    .pc_src(pc_src),
    .csr_pc_update(csr_pc_update),
    .pc_target(pc_target),
    .csr_update_pc(csr_update_pc),
    .pc_out(pc_out_wire),
    .pc(IF_ID_wire),
    .pc_trap(trap_instr_addr_misaligned),
    .instr_fetch_addr(instr_fetch_addr),
    .pc_for_decode(pc_for_decode)
  );

  always @(posedge clk or posedge reset) begin //Handle flush and stalling
    if(flush || reset) begin
      IF_ID_instr <= 32'h00000013; //NOP
      IF_ID_pc_plus_4 <= 32'b0;
      IF_ID_pc <= 32'b0;
    end else begin
      if(stall) begin
        IF_ID_instr <= IF_ID_instr;
        IF_ID_pc_plus_4 <= IF_ID_pc_plus_4;
        IF_ID_pc <= pc_for_decode;
      end else if(cpu_halt) begin
        IF_ID_instr <= IF_ID_instr;
        IF_ID_pc_plus_4 <= IF_ID_pc_plus_4;
        IF_ID_pc <= pc_for_decode;
      end
      else begin
        IF_ID_instr <= output_if_instr;
        IF_ID_pc_plus_4 <= pc_out_wire;
        IF_ID_pc <= pc_for_decode;

      end
    end
  end
  //**-----------------------**//


  //Decode Registers
  //Writeback
  (*KEEP="true"*)  reg [4:0]  mem_wb_rd_reg;
  (*KEEP="true"*)  reg [4:0] ram_wb_rd_reg;
  (*KEEP="true"*)  reg [31:0]  mem_wb_result_reg;
  (*KEEP="true"*)  reg        mem_wb_write_reg;
  (*KEEP="true"*)  reg [31:0] mem_data_out_reg;
  (*KEEP="true"*)  reg        mem_wb_is_load_reg;
  //ID-EX Registers
  reg [4:0]  id_rs1_addr_reg;
  reg [4:0]  id_rs2_addr_reg;

  reg [31:0] id_ex_pc_reg_plus_4_reg;
  reg [31:0] id_ex_pc_reg;
  reg [31:0] id_ex_rs1_val_reg;
  reg [31:0] id_ex_rs2_val_reg;
  reg        id_ex_reg_write_reg;
  reg [31:0] id_ex_imm_val_reg;
  reg [4:0]  id_ex_alu_op_reg;
  reg [2:0]  id_ex_div_op_reg;
  reg [4:0]  id_ex_rd_addr_reg;
  reg        id_ex_alu_src_reg;
  reg [2:0]  id_ex_branch_type_reg;
  reg        id_ex_is_branch_reg;
  reg        id_ex_jal_jump_reg;
  reg        id_ex_jalr_jump_reg;
  reg        id_ex_decoder_illegal_reg;
  reg        id_ex_is_load_reg;
  reg        id_ex_is_store_reg;
  reg [2:0]  id_ex_load_type_reg;
  reg [2:0]  id_ex_store_type_reg;
  reg        id_ex_div_start_reg;
  reg        id_ex_div_instruction_reg;
  reg        id_ex_is_lui_reg;
  reg        id_ex_is_auipc;
  reg [2:0]  id_ex_csr_func_reg;
  reg        id_ex_csr_write_enable_reg;
  reg [11:0] id_ex_csr_addr_reg;
  //ID-EX Wires
    wire [31:0] mem_data_out_w;
  wire [4:0]  id_rs1_addr_w;
  wire [4:0]  id_rs2_addr_w;
  wire [31:0] id_rs1_val_w;
  wire [31:0] id_rs2_val_w;
  wire        id_reg_write_w;
  wire [31:0] id_imm_val_w;
  wire [4:0]  id_alu_op_w;
  wire [2:0]  id_div_op_w;
  wire [4:0]  id_rd_addr_w;
  wire        id_alu_src_w;
  wire [2:0]  id_branch_type_w;
  wire        id_is_branch_w;
  wire        id_jal_jump_w;
  wire        id_jalr_jump_w;
  wire        id_decoder_illegal_w;
  wire        id_is_load_w;
  wire        id_is_store_w;
  wire [2:0]  id_load_type_w;
  wire [2:0]  id_store_type_w;
  wire        id_div_start_w;
  wire        id_div_instruction_w;
  wire        id_is_lui_w;
  wire        id_is_auipc;
  wire [2:0]  id_csr_func_w;
  wire        id_ex_csr_write_enable_w;
  wire        wrote_to_regfile;
  wire [11:0] id_ex_csr_addr_w;
  wire        is_mret;
  //**     Decode Stage     **//
  (*KEEP="true"*)
  decode_stage decode_stage_mod(
    .clk(clk),
    .IF_ID_instr(IF_ID_instr),
    .IF_ID_pc(IF_ID_pc),
    .mem_wb_result(mem_data_out_w),
    .wb_rd(mem_wb_rd_reg),
    .ram_rd_reg(ram_wb_rd_reg),
    .wb_result(mem_wb_result_reg),
    .wb_reg_write(mem_wb_write_reg),
    .wb_is_load_reg(mem_wb_is_load_reg),
    .id_rs1_val(id_rs1_val_w),
    .id_rs2_val(id_rs2_val_w),
    .id_reg_write_reg(id_reg_write_w),
    .id_imm_val(id_imm_val_w),
    .id_alu_op(id_alu_op_w),
    .id_div_op(id_div_op_w),
    .id_rd_addr(id_rd_addr_w),
    .id_rs1_addr(id_rs1_addr_w),
    .id_rs2_addr(id_rs2_addr_w),
    .id_alu_src(id_alu_src_w),
    .id_branch_type(id_branch_type_w),
    .id_is_branch(id_is_branch_w),
    .id_jal_jump(id_jal_jump_w),
    .id_jalr_jump(id_jalr_jump_w),
    .id_decoder_illegal(id_decoder_illegal_w),
    .id_is_load(id_is_load_w),
    .id_is_store(id_is_store_w),
    .id_load_type(id_load_type_w),
    .id_store_type(id_store_type_w),
    .id_div_start(id_div_start_w),
    .id_div_instruction(id_div_instruction_w),
    .id_is_lui(id_is_lui_w),
    .cpu_halt(cpu_halt),
    .is_auipc(id_is_auipc),
    .csr_func(id_csr_func_w),
    .csr_write_enable(id_ex_csr_write_enable_w),
    .wrote_to_regfile(wrote_to_regfile),
    .csr_addr(id_ex_csr_addr_w),
    .is_mret(is_mret)
  );

  always @(posedge clk) begin
    if(reset || flush) begin
      id_ex_reg_write_reg <= 0;
      id_ex_is_load_reg <= 0;
      id_ex_is_store_reg <= 0;
      id_ex_is_branch_reg <= 0;
      id_ex_div_start_reg<= 0;
      id_ex_jal_jump_reg  <= 0;
      id_ex_jalr_jump_reg <= 0;
      id_ex_div_instruction_reg <= 0;
      id_ex_csr_write_enable_reg <= 0;
      id_ex_imm_val_reg <= 0;
    end
    else if(!stall) begin
      id_ex_pc_reg_plus_4_reg <= IF_ID_pc_plus_4;
      id_ex_pc_reg <= IF_ID_pc;
      id_ex_rs1_val_reg <=id_rs1_val_w;
      id_ex_rs2_val_reg <= id_rs2_val_w;
      id_ex_reg_write_reg <= id_reg_write_w;
      id_ex_imm_val_reg <= id_imm_val_w;
      id_ex_alu_op_reg <= id_alu_op_w;
      id_ex_div_op_reg <= id_div_op_w;
      id_ex_rd_addr_reg <= id_rd_addr_w;
      id_ex_alu_src_reg <= id_alu_src_w;
      id_ex_branch_type_reg <= id_branch_type_w;
      id_ex_is_branch_reg <= id_is_branch_w;
      id_ex_jal_jump_reg <= id_jal_jump_w;
      id_ex_jalr_jump_reg <= id_jalr_jump_w;
      id_ex_decoder_illegal_reg <= id_decoder_illegal_w;
      id_ex_is_load_reg <= id_is_load_w;
      id_ex_is_store_reg <= id_is_store_w;
      id_ex_load_type_reg <= id_load_type_w;
      id_ex_store_type_reg <= id_store_type_w;
      id_ex_div_start_reg <= id_div_start_w;
      id_ex_div_instruction_reg <= id_div_instruction_w;
      id_ex_is_lui_reg <= id_is_lui_w;
      id_rs1_addr_reg <=id_rs1_addr_w;
      id_rs2_addr_reg <=id_rs2_addr_w;
      id_ex_is_auipc <= id_is_auipc;
      id_ex_csr_func_reg  <= id_csr_func_w;
      id_ex_csr_write_enable_reg <= id_ex_csr_write_enable_w;
      id_ex_csr_addr_reg <= id_ex_csr_addr_w;
    end

  end
   //**-----------------------**//


  //Execute Registers
  //Writeback

  //EX-MEM Registers
  reg [31:0] ex_mem_result_reg;
  reg [4:0] ex_mem_rd_addr_reg;
  reg ex_mem_reg_write_reg;
  reg ex_mem_is_load_reg;
  reg ex_mem_is_store_reg;
  reg [2:0] ex_mem_load_type_reg;
  reg [2:0] ex_mem_store_type_reg;
  reg [31:0] ex_mem_rs2_val_reg;
  reg [31:0] ex_mem_ram_address_reg;
  reg       ex_mem_is_lui_reg;
  reg       ex_mem_csr_write_enable_reg;
  reg [31:0] ex_mem_imm_val_reg;
  reg [31:0] ex_mem_csr_w_data;
  //EX-MEM Wires
  wire [31:0] id_ex_result_w;
  wire [31:0] ex_id_pc_target_w;
  wire div_busy_w;
  wire divider_finished_w;
  wire [31:0] ex_ram_address_w;
  reg [11:0] ex_mem_csr_addr_reg;
  reg [2:0] ex_mem_csr_func_reg;
  wire [31:0] csr_w_data;
  wire id_ex_send_to_uart;
  reg ex_mem_send_to_uart;
 //**     Execute Stage     **//
  execute_stage execute_stage_module(
    .clk(clk),
    .reset(reset),
    .id_pc_reg(id_ex_pc_reg),
    .id_pc_4_reg(id_ex_pc_reg_plus_4_reg),
    .id_rs1_val_reg(id_ex_rs1_val_reg),
    .id_rs2_val_reg(id_ex_rs2_val_reg),
    .id_imm_val_reg(id_ex_imm_val_reg),
    .id_alu_src_reg(id_ex_alu_src_reg),
    .id_is_branch_reg(id_ex_is_branch_reg),
    .id_branch_type_reg(id_ex_branch_type_reg),
    .id_jal_jump_reg(id_ex_jal_jump_reg),
    .id_jalr_jump_reg(id_ex_jalr_jump_reg),
    .id_alu_op_reg(id_ex_alu_op_reg),
    .id_div_op_reg(id_ex_div_op_reg),
    .id_div_instruction(id_ex_div_instruction_reg),
    .id_ex_is_lui_reg(id_ex_is_lui_reg),
    .id_ex_is_auipc(id_ex_is_auipc),
    .ex_mem_reg_write_reg(ex_mem_reg_write_reg),
    .ex_mem_rd(ex_mem_rd_addr_reg),
    .mem_wb_rd(mem_wb_rd_reg),
    .id_rs1_addr(id_rs1_addr_reg),
    .id_rs2_addr(id_rs2_addr_reg),
    .ex_mem_result_reg(ex_mem_result_reg),
    .mem_wb_result_reg(mem_wb_result_reg),
    .mem_wb_write_reg(mem_wb_write_reg),
    .load_type(id_ex_load_type_reg),
    .store_type(id_ex_store_type_reg),
    .is_load(id_ex_is_load_reg),
    .is_store(id_ex_is_store_reg),
    .ex_result(id_ex_result_w),
    .flush(flush_jump),
    .ex_pc_target(pc_target),      // Feed this back to fetch
    .ex_ram_address(ex_ram_address_w),
    .divider_busy(div_busy_w),
    .divider_finished_comb(divider_finished_w),
    .misaligned(trap_load_store_misaligned),
    .csr_w_data(csr_w_data),
    .send_to_uart(id_ex_send_to_uart)
);
assign pc_src = flush;

 always @(posedge clk) begin
    if(reset) begin
        ex_mem_reg_write_reg <= 0;
        ex_mem_is_store_reg  <= 0;
        ex_mem_is_load_reg   <= 0;
        ex_mem_rd_addr_reg <= 0;
        ex_mem_result_reg <= 0;
        ex_mem_csr_write_enable_reg <= 0;

    end
    else if(!stall) begin
      ex_mem_csr_w_data <= csr_w_data;
      ex_mem_csr_addr_reg<=id_ex_csr_addr_reg;
      ex_mem_imm_val_reg <= id_ex_imm_val_reg;
      ex_mem_csr_func_reg <= id_ex_csr_func_reg;
      ex_mem_result_reg <= id_ex_result_w;
      ex_mem_rd_addr_reg  <= id_ex_rd_addr_reg; // Pass the destination forward
      ex_mem_reg_write_reg <= id_ex_reg_write_reg;
      ex_mem_is_store_reg  <= id_ex_is_store_reg;
      ex_mem_is_load_reg   <= id_ex_is_load_reg;
      ex_mem_load_type_reg <= id_ex_load_type_reg;
      ex_mem_store_type_reg <= id_ex_store_type_reg;
      ex_mem_rs2_val_reg <=  id_ex_rs2_val_reg;
      ex_mem_ram_address_reg <= ex_ram_address_w;
      ex_mem_is_lui_reg  <= id_ex_is_lui_reg;
      ex_mem_csr_write_enable_reg <= id_ex_csr_write_enable_reg;
      ex_mem_send_to_uart <= id_ex_send_to_uart;
    end

 end

    //**-----------------------**//

  wire mem_busy_w;
  wire wrote_to_ram;

  reg [4:0] d_mem_wb_rd_reg;
  reg [31:0] d_mem_wb_result_reg;
  reg d_mem_wb_write_reg;
  reg d_mem_wb_is_load_reg;
  reg [31:0] d_mem_data_out_reg;



   //**     Memory Stage/Writeback     **//
  data_memory ram_unit (
    .clk(clk),
    .reset(reset),
    .flush(flush),
    .stall(stall),
   // .send_to_uart(id_ex_send_to_uart),
    .load_type(ex_mem_load_type_reg),
    .store_type(ex_mem_store_type_reg),
    .mem_read_en(ex_mem_is_load_reg),
    .mem_write_en(ex_mem_is_store_reg),
    .ram_address(ex_mem_ram_address_reg),
    .data_in(ex_mem_rs2_val_reg),
    .instr_fetch_addr(instr_fetch_addr),
    .data_out(mem_data_out_w),
    .mem_busy(mem_busy_w),
    .wrote_to_ram(wrote_to_ram),
    .output_if_instr(output_if_instr)
);
  wire early_stall = id_ex_div_instruction_reg && !div_busy_w && !divider_finished_w;
  wire normal_stall = div_busy_w;
  assign stall = early_stall || normal_stall;

 always @(posedge clk) begin
    if(reset) begin
        mem_wb_rd_reg      <= 0;
        mem_wb_result_reg  <= 0;
        mem_wb_write_reg   <= 0;
        mem_data_out_reg   <= 0;
        mem_wb_is_load_reg <= 0;
        // Clean up the old delay regs


    end
    else if(!stall) begin

        mem_wb_rd_reg      <= ex_mem_rd_addr_reg;  // The destination
        mem_wb_result_reg  <= ex_mem_csr_write_enable_reg ? csr_r_data : ex_mem_result_reg;   // The ALU result or CSR value
        mem_wb_write_reg   <= ex_mem_reg_write_reg;
        mem_wb_is_load_reg <= ex_mem_is_load_reg;  // The Mux selector
        mem_data_out_reg   <= mem_data_out_w;
    end
end

  //**-----------------------**//

assign instr_correctly_executed = wrote_to_regfile | wrote_to_ram; //Instruction was executed



//**     Control System Registers     **//

csr csr_module( //id_ex stage
  .clk(clk),
  .reset(reset),
  .current_privilege(privilege),
  .csr_addr(ex_mem_csr_addr_reg),
  .csr_func(ex_mem_csr_func_reg),
  .csr_w_data(ex_mem_csr_w_data),
  .csr_imm(ex_mem_imm_val_reg),
  .csr_write_enable(ex_mem_csr_write_enable_reg),
  .is_mret(is_mret),
  .trap_sources(is_trap),
  .trap_instr_pc(id_ex_pc_reg),
  .trap_cause(mcause_id),
  .extr_iqr(ext_iqr),
  .current_pc(IF_ID_pc),
  .instr_correctly_executed(instr_correctly_executed),
  .trap_csr_violation(trap_csr_access_violation),
  .csr_r_data(csr_r_data),
  .next_pc(csr_pc_update),
  .flush_from_interrupt(flush_from_interrupt),
  .next_privilege(next_privilege),
  .flush_trap(flush_trap),
  .csr_update_pc(csr_update_pc)
);
/* DEBUG */
always @(posedge clk) begin
    $display("cyc=%0d stall=%b flush=%b div_busy=%b div_fin=%b early_stall=%b normal_stall=%b id_ex_div_instr=%b IF_ID_instr=%h id_ex_result=%h",
        IF_ID_pc,
        stall,
        flush,
        div_busy_w,
        divider_finished_w,
        early_stall,
        normal_stall,
        id_ex_div_instruction_reg,
        IF_ID_instr,
        id_ex_result_w
    );
end

endmodule
