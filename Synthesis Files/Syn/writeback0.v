module writeback (
   input clk,
   input rst_n,

   input [15:0] mem_data,        // output of memory
   input [15:0] alu_result,      // output of ALU
   input        mem_to_reg,      // control signal from ME pipe

   output [15:0] reg_write_data  // to decode and forwarding paths
);

   assign reg_write_data = mem_to_reg ? mem_data : alu_result;


endmodule