module DE_pipe (
    input clk,
    input rst_n,

    // Inputs from Decode stage
    input  [15:0] read_data_1_in,
    input  [15:0] read_data_2_in,
    input  [15:0] pc_plus2_in,

    input        mem_enable_in,
    input        mem_to_reg_in,
    input        mem_write_in,
    input        alu_src_in,
    input        reg_write_in,
    input        pcs_in,
    input        hlt_in,
    input [2:0]  flag_en_in,

    input [3:0] dest_in,
    input [3:0] opcode_in,
    input [2:0] cond_in,
    input [8:0] branch_imm_in,
    input [3:0] src1_in,
    input [3:0] src2_in,
    input [7:0] imm_field_in,

    // Outputs to EX stage
    output [15:0] read_data_1_out,
    output [15:0] read_data_2_out,
    output [15:0] pc_plus2_out,

    output        mem_enable_out,
    output        mem_to_reg_out,
    output        mem_write_out,
    output        alu_src_out,
    output        reg_write_out,
    output        pcs_out,
    output        hlt_out,
    output [2:0]  flag_en_out,

    output [3:0] dest_out,
    output [3:0] opcode_out,
    output [2:0] cond_out,
    output [8:0] branch_imm_out,
    output [3:0] src1_out,
    output [3:0] src2_out,
    output [7:0] imm_field_out,

    input         mem_read_in,
    output        mem_read_out,
    
    input  [3:0]  rt_field_in,
    output [3:0]  rt_field_out
);

wire rst = ~rst_n;


dff rt_field_ff[3:0] (.clk(clk), .rst(rst), .wen(1'b1), .d(rt_field_in), .q(rt_field_out));


dff mem_read_ff (.clk(clk), .rst(rst), .wen(1'b1), .d(mem_read_in), .q(mem_read_out));

// Data path
dff read_data_1_ff[15:0] (.clk(clk), .rst(rst), .wen(1'b1), .d(read_data_1_in), .q(read_data_1_out));
dff read_data_2_ff[15:0] (.clk(clk), .rst(rst), .wen(1'b1), .d(read_data_2_in), .q(read_data_2_out));
dff pc_plus_2_ff[15:0]   (.clk(clk), .rst(rst), .wen(1'b1), .d(pc_plus2_in), .q(pc_plus2_out));

// Control signals
dff mem_enable_ff        (.clk(clk), .rst(rst), .wen(1'b1), .d(mem_enable_in),  .q(mem_enable_out));
dff mem_to_reg_ff        (.clk(clk), .rst(rst), .wen(1'b1), .d(mem_to_reg_in),  .q(mem_to_reg_out));
dff mem_write_ff         (.clk(clk), .rst(rst), .wen(1'b1), .d(mem_write_in),   .q(mem_write_out));
dff alu_src_ff           (.clk(clk), .rst(rst), .wen(1'b1), .d(alu_src_in),     .q(alu_src_out));
dff reg_write_ff         (.clk(clk), .rst(rst), .wen(1'b1), .d(reg_write_in),   .q(reg_write_out));
dff pcs_ff               (.clk(clk), .rst(rst), .wen(1'b1), .d(pcs_in),         .q(pcs_out));
dff hlt_ff               (.clk(clk), .rst(rst), .wen(1'b1), .d(hlt_in),         .q(hlt_out));
dff flag_en_ff[2:0]      (.clk(clk), .rst(rst), .wen(1'b1), .d(flag_en_in),     .q(flag_en_out));

// Instruction fields
dff dest_ff[3:0]         (.clk(clk), .rst(rst), .wen(1'b1), .d(dest_in),        .q(dest_out));
dff opcode_ff[3:0]       (.clk(clk), .rst(rst), .wen(1'b1), .d(opcode_in),      .q(opcode_out));
dff cond_ff[2:0]         (.clk(clk), .rst(rst), .wen(1'b1), .d(cond_in),        .q(cond_out));
dff branch_imm_ff[8:0]   (.clk(clk), .rst(rst), .wen(1'b1), .d(branch_imm_in),  .q(branch_imm_out));
dff src1_ff[3:0]         (.clk(clk), .rst(rst), .wen(1'b1), .d(src1_in),        .q(src1_out));
dff src2_ff[3:0]         (.clk(clk), .rst(rst), .wen(1'b1), .d(src2_in),        .q(src2_out));
dff imm_field_ff[7:0]    (.clk(clk), .rst(rst), .wen(1'b1), .d(imm_field_in),   .q(imm_field_out));

endmodule



