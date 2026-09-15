module execute (
   input         clk,
   input         rst_n,
   input  [3:0]  opcode,
   input  [3:0]  dest,
   input  [7:0]  imm_field,
   input  [2:0]  cond,
   input  [8:0]  branch_imm,
   input  [15:0] current_PC,
   input  [15:0] rs_data,
   input  [15:0] rt_data,

   input [3:0] src1_exec,
   input [3:0] src2_exec,

   // Added for forwarding
   input [1:0]  forwardA,
   input [1:0]  forwardB,
   input [15:0] E_M_forward_val,
   input [15:0] M_W_forward_val,
   input alu_src,

   // output [2:0]  alu_flags,
   output [15:0] aluResult,
   output [15:0] mem_calc_result,
   output        branch_taken,
   output [15:0] branch_target,
   output        ctrl_halt,
   output [15:0] pcs_value,
   output        pcs_valid,

   // Add new outputs to support prediction table update
   output        bp_update,
   output        bp_actual_taken,
   output [15:0] bp_pc

);

assign bp_update       = (opcode == 4'b1100 || opcode == 4'b1101);      // B or BR
assign bp_actual_taken = branch_taken;                                  // result from condition eval
assign bp_pc           = current_PC;                                    // PC of the branch instruction

reg [15:0] operandA, operandB;
wire [2:0] alu_flags;


wire [15:0] forwarded_rs_data = (forwardA == 2'b00) ? rs_data :
                                 (forwardA == 2'b01) ? E_M_forward_val :
                                 (forwardA == 2'b10) ? M_W_forward_val :
                                 16'hxxxx;

wire [15:0] forwarded_rt_data = (forwardB == 2'b00) ? rt_data :
                                 (forwardB == 2'b01) ? E_M_forward_val :
                                 (forwardB == 2'b10) ? M_W_forward_val :
                                 16'hxxxx;

wire is_shift_op = (opcode == 4'b0100) || (opcode == 4'b0101) || (opcode == 4'b0110); // SLL/SRA/ROR
wire [15:0] alu_in_B = (alu_src || is_shift_op) ? {12'b0, imm_field[3:0]} : forwarded_rt_data;




    wire [15:0] alu_result_from_comp_instructions;

   // compute instructions
   comp_instructions alu_inst (
      .opcode(opcode),
      .rs_data(forwarded_rs_data),           // changed to operandA from rs_data for forwarding
      .rt_data(alu_in_B),           // changed to alu_in_B from rt_data
      .immediate(imm_field[3:0]),
      .result(alu_result_from_comp_instructions),
      .flag_out(alu_flags)
   );



// memory address computation
mem_instr mem_inst (
   .opcode(opcode),
   .rs(src1_exec),
   .rs_data(forwarded_rs_data),
   .rt_data(forwarded_rt_data),
   .imm_field(imm_field),               // pass full imm_field [7:0] now
   .result(mem_calc_result)
);


   // branch control signals
   contr_instructions ctrl_inst (
      .opcode(opcode),
      .cond(cond),
      .imm_field(branch_imm),
      .pc_next(current_PC),
      .flag_N(alu_flags[2]),
      .flag_Z(alu_flags[1]),
      .flag_V(alu_flags[0]),
      .rs_val(forwarded_rs_data),    // changed to forwarded_rs_data from rs_data for forwarding
      .branch_taken(branch_taken),
      .branch_target(branch_target),
      .pcs_valid(pcs_valid),
      .pcs_value(pcs_value),
      .halt(ctrl_halt)
   );


//////////////////////////////////////////////////
// for forwarding


    always @(*) begin
        case (forwardA)
            2'b00: operandA = rs_data;
            2'b01: operandA = E_M_forward_val;
            2'b10: operandA = M_W_forward_val;
            default: operandA = 16'hxxxx;
        endcase

        case (forwardB)
            2'b00: operandB = rt_data;
            2'b01: operandB = E_M_forward_val;
            2'b10: operandB = M_W_forward_val;
            default: operandB = 16'hxxxx;
        endcase
    end
//////////////////////////////////////////////////

assign aluResult = (opcode == 4'b1010 || opcode == 4'b1011) ? mem_calc_result : alu_result_from_comp_instructions;


endmodule
