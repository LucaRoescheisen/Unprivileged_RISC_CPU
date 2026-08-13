/* verilator lint_off UNUSED */
module data_memory(
  input clk,
  input reset,
  input flush,
  input stall,
  input id_ex_send_to_uart,
  input [2:0] load_type,
  input [2:0] store_type,
  input mem_read_en,
  input mem_write_en,
  input [31:0] ram_address,
  input  [31:0] data_in,
  input [31:0] instr_fetch_addr,
  output reg [31:0] data_out,
  output reg mem_busy,
  output reg wrote_to_ram,
  output reg [31:0] output_if_instr
);
/*
addr : [1:0] tells which byte is being accessed (column)
addr : [11:2] which address is being accessed (row)
*/


reg [31:0] ram [0:2047];
integer i;
  initial begin
     for (i = 0; i < 2048; i = i + 1)
        ram[i] = 32'b0;
    $readmemh("D:/u_risc/programs/fixed_ram.hex", ram);
  end

always @(posedge clk) begin
  if(reset) begin
    output_if_instr <= 32'h00000013;
  end
  else if(!flush && !stall) begin
    output_if_instr <= ram[instr_fetch_addr];
  end
end

always @(posedge clk) begin

  if(mem_write_en ) begin
        $display("Store: x%0d = 0x%08x", ram_address[12:2], data_in);
        case(store_type)
            3'b000: begin // STORE BYTE
                wrote_to_ram <= 1;
                case(ram_address[1:0])
                    2'b00: ram[ram_address[12:2]][7:0]   <= data_in[7:0];
                    2'b01: ram[ram_address[12:2]][15:8]  <= data_in[7:0];
                    2'b10: ram[ram_address[12:2]][23:16] <= data_in[7:0];
                    2'b11: ram[ram_address[12:2]][31:24] <= data_in[7:0];
                endcase
            end
            3'b001: begin // STORE HALF
                wrote_to_ram <= 1;
                case(ram_address[1])
                    1'b0: ram[ram_address[12:2]][15:0]  <= data_in[15:0];
                    1'b1: ram[ram_address[12:2]][31:16] <= data_in[15:0];
                endcase
            end
            3'b010: begin // STORE WORD
                wrote_to_ram <= 1;
                ram[ram_address[12:2]] <= data_in;
            end
            default: begin
              wrote_to_ram <= 0;
            end
        endcase
    end
end


//wire [31:0] current_word = ram[ram_address[11:2]]; // switch to sync, so ram becomes bram instead of lutram
reg[31:0] current_word;
always @(posedge clk) begin

    if(reset) begin
    data_out <= 0;
  end
  else begin
  if(mem_read_en) begin
    $display("Load: x%0d = 0x%08x", ram_address[12:2], data_out);
    case(load_type)
      3'b000: //LOAD BYTE
        case(ram_address[1:0])
          2'b00: data_out <= {{24{ram[ram_address[12:2]][7]}} , ram[ram_address[12:2]][7:0]};
          2'b01: data_out <= {{24{ram[ram_address[12:2]][15]}}, ram[ram_address[12:2]][15:8]};
          2'b10: data_out <= {{24{ram[ram_address[12:2]][23]}}, ram[ram_address[12:2]][23:16]};
          2'b11: data_out <= {{24{ram[ram_address[12:2]][31]}}, ram[ram_address[12:2]][31:24]};
        endcase
      3'b001: //LOAD HALF
          case(ram_address[1])
            1'b0: data_out <= {{16{ram[ram_address[12:2]][15]}} ,ram[ram_address[12:2]][15:0]};
            1'b1: data_out <= {{16{ram[ram_address[12:2]][31]}}, ram[ram_address[12:2]][31:16]};
          endcase
      3'b010: //LOAD WORD
        data_out <= ram[ram_address[12:2]];
      3'b100: //LOAD BYTE (U)
         case(ram_address[1:0])
          2'b00: data_out <= {24'b0, ram[ram_address[12:2]][7:0]};
          2'b01: data_out <= {24'b0, ram[ram_address[12:2]][15:8]};
          2'b10: data_out <= {24'b0, ram[ram_address[12:2]][23:16]};
          2'b11: data_out <= {24'b0, ram[ram_address[12:2]][31:24]};
        endcase
      3'b101: //LOAD HALF (U)
          case(ram_address[1])
            1'b0: data_out <= {{16{ram[ram_address[12:2]][0]}} , ram[ram_address[12:2]][15:0]};
            1'b1: data_out <= {{16{ram[ram_address[12:2]][0]}}, ram[ram_address[12:2]][31:16]};
          endcase
      default: begin
            end

    endcase

  end
  end
end

always @(posedge clk) begin
    if ((mem_read_en || mem_write_en) && !mem_busy) begin
        mem_busy <= 1'b1;
    end else begin
        mem_busy <= 1'b0;
    end

end


endmodule