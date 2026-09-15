module MW_pipe (
    input clk,
    input rst_n,

    // comes from data memory
    input [15:0] reg_write_data_in,

    // comes from prev EM pipe
    input [15:0] alu_result_in,
    input [3:0]  reg_write_addr_in,  // destination register
    input        reg_write_enable_in,
    input        mem_to_reg_in,
    input        ctrl_halt_in,

    output [15:0] reg_write_data_out,
    output [15:0] alu_result_out,
    output [3:0]  reg_write_addr_out,
    output        reg_write_enable_out,
    output        mem_to_reg_out,
    output        ctrl_halt_out,

    input  [15:0] mem_calc_result_in,
    output [15:0] mem_calc_result_out,

    input [15:0] pc_plus2_in,
    output [15:0] pc_plus2_out
);

wire rst = ~rst_n;

dff pc_plus2_ff[15:0] (.clk(clk), .rst(rst), .wen(1'b1), .d(pc_plus2_in), .q(pc_plus2_out));

dff mem_calc_result_ff[15:0] (.clk(clk), .rst(rst), .wen(1'b1), .d(mem_calc_result_in), .q(mem_calc_result_out));

dff reg_write_data_ff[15:0] (.clk(clk), .rst(rst), .wen(1'b1), .d(reg_write_data_in), .q(reg_write_data_out));

dff alu_result_ff[15:0]     (.clk(clk), .rst(rst), .wen(1'b1), .d(alu_result_in),     .q(alu_result_out));
dff reg_write_addr_ff[3:0]  (.clk(clk), .rst(rst), .wen(1'b1), .d(reg_write_addr_in), .q(reg_write_addr_out));
dff reg_write_enable_ff     (.clk(clk), .rst(rst), .wen(1'b1), .d(reg_write_enable_in), .q(reg_write_enable_out));
dff mem_to_reg_ff           (.clk(clk), .rst(rst), .wen(1'b1), .d(mem_to_reg_in),     .q(mem_to_reg_out));
dff ctrl_halt_ff            (.clk(clk), .rst(rst), .wen(1'b1), .d(ctrl_halt_in),      .q(ctrl_halt_out));

endmodule
