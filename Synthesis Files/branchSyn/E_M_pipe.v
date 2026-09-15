module EM_pipe (

input clk,
input rst_n,


input  [15:0] aluResult_in,
input  [15:0] mem_calc_result_in,
input         branch_taken_in,
input  [15:0] branch_target_in,
input         ctrl_halt_in,
input  [15:0] pcs_value_in,
input         pcs_valid_in,

input [3:0]  dest_in,
input        reg_write_enable_in,
input        mem_to_reg_in,

output [3:0]  dest_out,
output       reg_write_enable_out,
output        mem_to_reg_out,

input  [3:0] opcode_in,
output [3:0] opcode_out,


output [15:0] aluResult_out,
output [15:0] mem_calc_result_out,
output        branch_taken_out,
output [15:0] branch_target_out,
output        ctrl_halt_out,
output [15:0] pcs_value_out,
output        pcs_valid_out,

input mem_read_in,
input mem_write_in,
output mem_read_out,
output mem_write_out,

input [15:0] pc_plus2_in,
output [15:0] pc_plus2_out,

input  [3:0] rt_src_in,
output [3:0] rt_src_out,

input  [3:0] rt_field_in,
output [3:0] rt_field_out,

input        bp_update_in,
input        bp_actual_taken_in,
input  [15:0] bp_pc_in,

output        bp_update_out,
output        bp_actual_taken_out,
output [15:0] bp_pc_out

);

wire rst = ~rst_n;

dff bp_update_ff        (.clk(clk), .rst(rst), .wen(1'b1), .d(bp_update_in),        .q(bp_update_out));
dff bp_actual_taken_ff  (.clk(clk), .rst(rst), .wen(1'b1), .d(bp_actual_taken_in),  .q(bp_actual_taken_out));
dff bp_pc_ff[15:0]      (.clk(clk), .rst(rst), .wen(1'b1), .d(bp_pc_in),            .q(bp_pc_out));

dff rt_field[3:0] (.clk(clk), .rst(rst), .wen(1'b1), .d(rt_field_in), .q(rt_field_out));


dff rt_src[3:0] (.clk(clk), .rst(rst), .wen(1'b1), .d(rt_src_in), .q(rt_src_out));

dff pc_plus2_ff[15:0] (.clk(clk), .rst(rst), .wen(1'b1), .d(pc_plus2_in), .q(pc_plus2_out));


dff mem_read_ff(.clk(clk), .rst(rst), .wen(1'b1), .d(mem_read_in), .q(mem_read_out));
dff mem_write_ff(.clk(clk), .rst(rst), .wen(1'b1), .d(mem_write_in), .q(mem_write_out));

dff opcode_ff[3:0](.clk(clk), .rst(rst), .wen(1'b1), .d(opcode_in), .q(opcode_out));


dff aluResult_ff[15:0]         (.clk(clk), .rst(rst), .wen(1'b1), .d(aluResult_in),         .q(aluResult_out));
dff mem_calc_result_ff[15:0]   (.clk(clk), .rst(rst), .wen(1'b1), .d(mem_calc_result_in),   .q(mem_calc_result_out));
dff branch_taken_ff            (.clk(clk), .rst(rst), .wen(1'b1), .d(branch_taken_in),      .q(branch_taken_out));
dff branch_target_ff[15:0]     (.clk(clk), .rst(rst), .wen(1'b1), .d(branch_target_in),     .q(branch_target_out));

dff ctrl_halt_ff               (.clk(clk), .rst(rst), .wen(1'b1), .d(ctrl_halt_in),         .q(ctrl_halt_out));

dff pcs_value_ff[15:0]         (.clk(clk), .rst(rst), .wen(1'b1), .d(pcs_value_in),         .q(pcs_value_out));
dff pcs_valid_ff               (.clk(clk), .rst(rst), .wen(1'b1), .d(pcs_valid_in),         .q(pcs_valid_out));


dff dest_ff[3:0]            (.clk(clk), .rst(rst), .wen(1'b1), .d(dest_in),             .q(dest_out));

dff reg_write_enable_ff     (.clk(clk), .rst(rst), .wen(1'b1), .d(reg_write_enable_in), .q(reg_write_enable_out));


dff mem_to_reg_ff           (.clk(clk), .rst(rst), .wen(1'b1), .d(mem_to_reg_in),       .q(mem_to_reg_out));


endmodule
