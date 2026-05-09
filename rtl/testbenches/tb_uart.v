`timescale 1ns/1ps
module tb_uart;
  localparam CLK_PERIOD = 10;
  // 115200 baud = 868 cycles @ 100MHz = 8680ns per bit
  localparam BIT_PERIOD = 8680;

  reg clk, reset;
  reg uart_store;

  reg id_ex_send_to_uart;
  reg [7:0] rx, tx; 

  uart dut(
    .clk(clk),
    .reset(reset),
    .uart_store(uart_store),
    .uart_send_info(uart_send_info),
    .id_ex_send_to_uart(id_ex_send_to_uart),
    .rx(rx),
    .tx(tx)
  );

  always #(CLK_PERIOD/2) clk = ~clk;

  task send_byte;
    input [7:0] in;
    @(posedge clk) 
      uart_send_info <= in;
      uart_store <= 1;
    @(posedge clk);
      uart_store <= 0;
  endtask

endmodule