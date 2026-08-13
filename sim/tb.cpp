#include "Vtop_verilator.h"
#include "verilated.h"
#include <iostream>



int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Vtop_verilator* dut = new Vtop_verilator;
  dut->clk = 0;
  dut->reset = 1;
      for (int i = 0; i < 10; i++) {
        dut->clk = !dut->clk;
        dut->eval();

        if (i == 1) dut->reset = 0;

        std::cout << "Cycle " << i << ", clk=" << (int)dut->clk << ", pc=" << (int)dut->pc_out << std::endl;
    }

  delete dut;
  return 0;

}