#include <stdint.h>
#define UART_RX_ADDR 0x10000004
#define UART_STATUS_ADDR 0x10000008

uint32_t get_char(void) {
  while((*(volatile uint32_t*)UART_STATUS_ADDR & 1) != 0) {}
  return *(volatile uint32_t*)UART_RX_ADDR;
}