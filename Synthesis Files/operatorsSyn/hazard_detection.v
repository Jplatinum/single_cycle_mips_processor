module hazard_detection_unit (
    input [3:0] IF_ID_opcode,
    input [3:0] ID_EX_opcode,
    input [3:0] EX_MEM_opcode,
    input [3:0] IF_ID_rs,
    input [3:0] IF_ID_rt,
    input [3:0] ID_EX_rd,
    input [3:0] EX_MEM_rd,
    input       ID_EX_memRead,
    input       ID_EX_regWrite,
    input       EX_MEM_regWrite,
    input       branch_taken,

    output      stall,
    output      flush,
    output      pc_enable,
    output      IF_ID_enable
);



wire mem_address_hazard = (EX_MEM_opcode == 4'b1001) &&         // SW in MEM stage
                          (ID_EX_opcode == 4'b1000) &&          // LW in EX stage
                          (EX_MEM_rd == ID_EX_rd);              // rs conflict (base register)


// Load-Use hazard (stall 1 cycle if LW in EX writes to rs or rt in ID)
wire load_use_hazard = ID_EX_memRead &&
                        ((ID_EX_rd == IF_ID_rs) || (ID_EX_rd == IF_ID_rt));

// Branch data hazard (branch uses a register that's being written)
wire branch_reg_hazard = (IF_ID_opcode == 4'b1101) &&
                            ((ID_EX_regWrite && ID_EX_rd == IF_ID_rs) ||
                            (EX_MEM_regWrite && EX_MEM_rd == IF_ID_rs));

// Flag hazard (branch or conditional logic depends on flags set in EX)
wire is_branch = (IF_ID_opcode[3:1] == 3'b110);

wire is_flag_setting = (ID_EX_opcode == 4'b0000) ||     // ADD
                    (ID_EX_opcode == 4'b0001) ||         // SUB
                    (ID_EX_opcode == 4'b0010) ||         // XOR
                    (ID_EX_opcode == 4'b0100) ||         // SLL
                    (ID_EX_opcode == 4'b0101) ||         // SRA
                    (ID_EX_opcode == 4'b0110);           // ROR

wire flag_hazard = is_branch && is_flag_setting;

assign stall = load_use_hazard || branch_reg_hazard || flag_hazard || mem_address_hazard;
assign flush = is_branch && branch_taken;
assign pc_enable = ~stall;
assign IF_ID_enable = ~stall;




endmodule
