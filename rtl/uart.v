module uart(
  input clk,
  input reset,
  input uart_store,
  input [7:0] uart_send_info,
  input id_ex_send_to_uart,
  input [7:0] rx,
  output reg tx
);
  /*
  Baudrate : 115200
  Parity : None
  Stop bit: 1
  Data : 8 bit

  */



  localparam FIFO_DEPTH = 16;


  //TX Variables
  reg [3:0] tx_write_ptr;
  reg [3:0] tx_read_ptr;
  reg [7:0] tx_fifo [0:FIFO_DEPTH - 1];
  reg [9:0] tx_shift_reg;
  reg [3:0] tx_shift_bit;
  reg [3:0] tx_fifo_count;
  wire tx_fifo_empty = (tx_fifo_count == 0);
  reg tx_shift_reg_busy;

  reg [9:0] baud_rate_counter;
  reg baud_tick;

  //RX Variables
  //memory location : 0x10000004 outputs : rx_fifo[rx_read_ptr]
  //memory location : 0x10000008 lw from rx_fifo read_ptr value
  //memory location : 0x10000012 for polling if uart is empty
  reg [3:0] rx_write_ptr;
  reg [3:0] rx_read_ptr;
  reg [7:0] rx_fifo [0:FIFO_DEPTH - 1];
  reg [9:0] rx_shift_reg;
  reg [3:0] rx_shift_bit;
  reg [3:0] rx_fifo_count;
  wire rx_fifo_empty = (rx_fifo_count == 0);
  wire rx_fifo_full = (rx_fifo_count == 16);
  reg rx_shift_reg_busy;


  always @(posedge clk) begin
    if(reset) begin
      baud_rate_counter <= 0;
    end
    else begin
      if(baud_rate_counter == 868) begin
        baud_rate_counter <= 0;
        baud_tick <= 1;
      end
      else begin
        baud_rate_counter = baud_rate_counter + 1;
        baud_tick <= 0
      end
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      tx_write_ptr <= 0;
      tx_read_ptr <= 0;
      tx_fifo_count <= 0;
      tx_shift_bit <= 1;
      tx_shift_reg_busy <= 0;
    end
    else if(uart_store) begin
      tx_write_ptr <= tx_write_ptr + 1;
      tx_fifo[tx_write_ptr] <= rx;
      tx_fifo_count <= (tx_fifo_count + 1) % FIFO_DEPTH;
    end
    else begin
      if(!tx_shift_reg_busy && !tx_fifo_empty) begin
        tx_shift_reg <= {1'b1, tx_fifo[tx_read_ptr] , 1'b0};
        tx_shift_reg_busy <= 1;
        tx_shift_bit <= 0;
        tx_read_ptr <= (tx_read_ptr + 1) % FIFO_DEPTH;
        tx_fifo_count <= tx_fifo_count - 1;
      end
      else if(baud_tick && tx_shift_reg_busy) begin
        tx <= tx_shift_reg[0];
        tx_shift_reg <= shift >> 1;
        tx_shift_bit <= tx_shift_bit + 1;
        if(tx_shift_bit == 9) tx_shift_reg_busy <= 0;
      end
      else if(!tx_shift_reg_busy && tx_fifo_count == 0) begin
        tx <= 1;
      end

    end
  end


  always @(posedge clk) begin
    if(reset) begin
      rx_write_ptr <= 0;
      rx_read_ptr <= 0;
      rx_fifo_count <= 0;
      rx_shift_bit <= 1;
      rx_shift_reg_busy <= 0;
    end
    else begin
      if(id_ex_send_to_uart && rx_fifo && !rx_fifo_full) begin
        rx_fifo[rx_write_ptr] <=uart_send_info;
        rx_write_ptr <= rx_write_ptr + 1;
      end


      if(rx == 0 && rx_shift_reg_busy == 0 && !rx_fifo_full) begin
        rx_shift_reg_busy <= 1;
        rx_shift_bit <= 0;
      end
      else if (rx_shift_reg_busy && baud_tick) begin
        rx_shift_bit <= rx_shift_bit + 1;
        if(rx_shift_bit < 8) begin
          rx_shift_reg <= {rx, rx_shift_reg[7:1]};
        end
        if(rx_shift_bit == 8) begin
          rx_fifo[rx_write_ptr] <= rx_shift_reg;
          rx_write_ptr <= (rx_write_ptr + 1) % FIFO_DEPTH;
          rx_shift_reg_busy <= 0;
          rx_fifo_count <= (rx_fifo_count + 1) % FIFO_DEPTH;
        end
      end
    end
  end



endmodule
