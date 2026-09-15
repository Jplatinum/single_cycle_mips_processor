module cpu(
   input         clk,
   input         rst_n,
   output        hlt,
   output [15:0] pc
);



//fetch stage
wire [15:0] PC_fetch;
wire [15:0] instruction_fetch;
wire branch_taken;
wire [15:0] branch_target;
wire [15:0] pc_plus_2;
wire pc_enable;


//wire is_hlt_fetched = (instruction_fetch[15:12] == 4'b1111);
wire is_hlt_fetched = (instruction_fetch !== 16'hxxxx) && (instruction_fetch[15:12] == 4'b1111);
//wire halt_fetch_block = is_hlt_fetched & ~branch_taken;



wire [15:0] icache_mem_addr;
wire        icache_mem_req;
wire [15:0] mem_data_shared;
wire        mem_valid_shared;
wire [15:0] arb_mem_addr;
wire [15:0] arb_write_data;
wire        arb_write_enable;
wire        grant_icache;
wire        grant_dcache;
wire [15:0] dcache_mem_addr;   // D-cache memory address (for miss refill)
wire [15:0] dcache_mem_data;   // D-cache data to write to memory (for write-through)
wire        dcache_mem_req;    // D-cache is requesting access to memory
wire        dcache_we;         // D-cache write enable signal
wire icache_hit_signal;
wire dcache_hit_signal;


wire ic_stall;
wire halt_fetch_block = (is_hlt_fetched & ~branch_taken) | ic_stall;

wire bp_update_mem, bp_actual_taken_mem;
wire [15:0] bp_pc_mem;

fetch fetch0 (
    .clk(clk),
    .rst_n(rst_n),
    .branch_taken(branch_taken),
    .branch_target(branch_target),
    .pc_enable(pc_enable),
    .halt_fetch_block(halt_fetch_block),
    .pc_plus_2(pc_plus_2),
    .PC(PC_fetch),
    .instr(instruction_fetch),
    .icache_mem_addr(icache_mem_addr),
    .icache_mem_req(icache_mem_req),
    .mem_data_main(mem_data_shared),
    .mem_valid_main(mem_valid_shared),

    .icache_hit_signal(icache_hit_signal),
    .grant_icache(grant_icache),

    .cache_stall(ic_stall),

    .bp_update(bp_update_mem),
    .bp_actual_taken(bp_actual_taken_mem),
    .bp_pc(bp_pc_mem)


);


arbiter arbiter0 (
    .clk(clk),
    .rst_n(rst_n),

    .icache_req(icache_mem_req),
    .dcache_req(dcache_mem_req),

    .icache_done(icache_hit_signal),     // Done when I-cache hits or FSM finishes
    .dcache_done(dcache_hit_signal),     // Done when D-cache hits or FSM finishes

    .icache_addr(icache_mem_addr),
    .icache_data(16'd0),                 // I-cache is read-only
    .icache_we(1'b0),                    // I-cache never writes

    .dcache_addr(dcache_mem_addr),
    .dcache_data(dcache_mem_data),
    .dcache_we(dcache_we),

    .grant_icache(grant_icache),
    .grant_dcache(grant_dcache),

    .mem_addr(arb_mem_addr),
    .mem_write_data(arb_write_data),
    .mem_write_enable(arb_write_enable)
);



memory4c main_memory (
    .data_out(mem_data_shared),
    .data_in(arb_write_data),
    .addr(arb_mem_addr),
    .enable(grant_icache || grant_dcache),
    .wr(arb_write_enable),
    .clk(clk),
    .rst(~rst_n),
    .data_valid(mem_valid_shared)
);

wire [15:0] aluResult_mem, mem_calc_result_mem;
wire [15:0] rs_data_exec, rt_data_exec;
wire memRead_mem;
wire memWrite_mem;
wire [15:0] reg_write_data_mem;




dcache dcache0 (
    .clk(clk),
    .rst(~rst_n),

    // Interface with MEM stage
    .addr(mem_calc_result_mem),
    .write_data(rt_data_exec),
    .mem_read(memRead_mem),
    .mem_write(memWrite_mem),
    .read_data(reg_write_data_mem),        // Output to be written back
    .dcache_hit(dcache_hit_signal),
    .dcache_stall(),

    // Interface with arbiter/memory
    .mem_write_data(dcache_mem_data),
    .mem_addr(dcache_mem_addr),
    .mem_write_enable(dcache_we),
    .mem_request(dcache_mem_req),
    .mem_data(mem_data_shared),
    .mem_valid(mem_valid_shared),

    .grant(grant_dcache)
);






// F_D pipeline
wire [15:0] PC_decode;
wire [15:0] instruction_decode;
wire stall, flush, IF_ID_enable;

FD_pipe fd_pipe (
    .clk(clk),
    .rst_n(rst_n),
    .instr_in(instruction_fetch),

    .enable(IF_ID_enable && icache_hit_signal),
    .flush(flush),

    .pc_plus_2_in(pc_plus_2),
    .pc_plus_2_out(PC_decode),

    .instr_out(instruction_decode)
);



   // M_W pipeline
   wire [15:0] reg_write_data_wb;
   wire [3:0] reg_write_addr_wb;
   wire reg_write_enable_wb;

   //decode stage
   wire [15:0] rs_data, rt_data;
   wire [3:0]  src1, src2;
   wire [3:0]  opcode_decode, dest_decode;
   wire [7:0]  imm_field_decode;
   wire [2:0]  cond_decode;
   wire [8:0]  branch_imm_decode;

wire mem_enable_decode;
wire mem_to_reg_decode;
wire mem_write_decode;
wire alu_src_decode;
wire reg_write_decode;
wire pcs_decode;
wire [2:0] flag_en_decode;

// E_M pipeline
wire [3:0] dest_mem;
wire [3:0] opcode_mem;

wire ctrl_halt_mem;
wire ctrl_halt_wb;

//execute stage
wire [15:0] aluResult_exec, mem_calc_result_exec;
wire ctrl_halt;
wire [3:0] rt_field_decode;

wire stall_decode = stall | ic_stall;

decode decode0 (
    .clk(clk),
    .rst_n(rst_n),
    .instr(instruction_decode),
    .rf_write_data(reg_write_data_wb),
    .rf_write_addr(reg_write_addr_wb),     
    .rf_write_enable(reg_write_enable_wb), 

    .stall(stall_decode),

    .rs_data(rs_data),
    .rt_data(rt_data),
    .src1(src1),
    .src2(src2),
    .opcode(opcode_decode),
    .dest(dest_decode),
    .imm_field(imm_field_decode),
    .cond(cond_decode),
    .branch_imm(branch_imm_decode),

    .mem_enable(mem_enable_decode),
    .mem_to_reg(mem_to_reg_decode),
    .mem_write(mem_write_decode),
    .alu_src(alu_src_decode),
    .reg_write(reg_write_decode),
    .pcs(pcs_decode),
    .flag_en(flag_en_decode),
    
    .rt_field(rt_field_decode)

   );







// D_E pipeline
wire [15:0] PC_exec;
wire [3:0]  opcode_exec, dest_exec;
wire [7:0]  imm_field_exec;
wire [2:0]  cond_exec;
wire [8:0]  branch_imm_exec;


wire [15:0] pc_decode_exec;


wire memRead_exec;

wire memWrite_exec;


wire        reg_write_exec;         // comes from DE_pipe
wire reg_write_enable_mem;

hazard_detection_unit hdu (
    .IF_ID_opcode(opcode_decode),
    .ID_EX_opcode(opcode_exec),
    .EX_MEM_opcode(opcode_mem),
    .IF_ID_rs(src1),
    .IF_ID_rt(src2),
    .ID_EX_rd(dest_exec),
    .EX_MEM_rd(dest_mem),
    .ID_EX_memRead(memRead_exec),
    .ID_EX_regWrite(reg_write_exec),
    .EX_MEM_regWrite(reg_write_enable_mem),
    .branch_taken(branch_taken),
    .stall(stall),
    .flush(flush),
    .pc_enable(pc_enable),
    .IF_ID_enable(IF_ID_enable)
);




wire alu_src_exec;
wire mem_to_reg_exec;
wire hlt_exec;

wire [3:0] src1_exec, src2_exec;
wire [3:0] rt_field_exec;

DE_pipe de_pipe (

    .clk(clk),
    .rst_n(rst_n),

    .read_data_1_in(rs_data),
    .read_data_2_in(rt_data),
    .pc_plus2_in(PC_decode),

    .mem_enable_in(mem_enable_decode),
    .mem_to_reg_in(mem_to_reg_decode),
    .mem_write_in(mem_write_decode),
    .alu_src_in(alu_src_decode),
    .reg_write_in(reg_write_decode),
    .pcs_in(pcs_decode),
    .hlt_in(is_hlt_fetched),
    .flag_en_in(flag_en_decode),

    .dest_in(dest_decode),
    .opcode_in(opcode_decode),
    .cond_in(cond_decode),
    .branch_imm_in(branch_imm_decode),
    .src1_in(src1),
    .src2_in(src2),
    .imm_field_in(imm_field_decode),

    .read_data_1_out(rs_data_exec),
    .read_data_2_out(rt_data_exec),
    .pc_plus2_out(PC_exec),

    .mem_enable_out(),                      // not used
    .mem_to_reg_out(mem_to_reg_exec),
    .mem_write_out(memWrite_exec),                       // unused in execute
    .alu_src_out(alu_src_exec),
    .reg_write_out(reg_write_exec),
    .pcs_out(),                             // unused in execute
    .hlt_out(hlt_exec),
    .flag_en_out(),                         // unused in execute

    .dest_out(dest_exec),
    .opcode_out(opcode_exec),
    .cond_out(cond_exec),
    .branch_imm_out(branch_imm_exec),
    .src1_out(src1_exec),
    .src2_out(src2_exec),
    .imm_field_out(imm_field_exec),

    .mem_read_in(mem_enable_decode),
    .mem_read_out(memRead_exec),

    .rt_field_in(rt_field_decode),
    .rt_field_out(rt_field_exec)


);






wire [1:0] forwardA, forwardB;
wire [15:0] pcs_value_exec;
wire        pcs_valid_exec;

wire bp_update_ex, bp_actual_taken_ex;
wire [15:0] bp_pc_ex;

   execute execute0 (
      .clk(clk),
      .rst_n(rst_n),
      .opcode(opcode_exec),
      .dest(dest_exec),
      .imm_field(imm_field_exec),
      .cond(cond_exec),
      .branch_imm(branch_imm_exec),
      .current_PC(PC_exec),
      .rs_data(rs_data_exec),
      .rt_data(rt_data_exec),

      .src1_exec(src1_exec),
      .src2_exec(src2_exec),

      .aluResult(aluResult_exec),
      .mem_calc_result(mem_calc_result_exec),
      .branch_taken(branch_taken),
      .branch_target(branch_target),
      .ctrl_halt(ctrl_halt),
      .pcs_value(pcs_value_exec),
      .pcs_valid(pcs_valid_exec),
      .alu_src(alu_src_exec),

    // Added for forwarding
      .forwardA(forwardA),
      .forwardB(forwardB),
      .E_M_forward_val(aluResult_mem),
      .M_W_forward_val(reg_write_data_wb),

      .bp_update(bp_update_ex),
      .bp_actual_taken(bp_actual_taken_ex),
      .bp_pc(bp_pc_ex)

   );






// from EM_pipe
wire [15:0] pcs_value_mem;
wire [15:0] pc_plus2_mem_stage;
wire        pcs_valid_mem;



// Outputs from execute stage → inputs to EM_pipe

wire mem_to_reg_mem;
wire reg_write_enable_em;
wire [3:0] rt_src_mem;
wire [3:0] rt_field_mem;


EM_pipe em_pipe (
    .clk(clk),
    .rst_n(rst_n),

    // Inputs from execute stage
    .aluResult_in(aluResult_exec),
    .mem_calc_result_in(mem_calc_result_exec),
    .branch_taken_in(branch_taken),
    .branch_target_in(branch_target),
    .ctrl_halt_in(hlt_exec),
    .pcs_value_in(pcs_value_exec),
    .pcs_valid_in(pcs_valid_exec),

    .dest_in(dest_exec),

    .reg_write_enable_in(reg_write_exec),

    .mem_to_reg_in(mem_to_reg_exec),

    // Outputs to mem stage
    .aluResult_out(aluResult_mem),
    .mem_calc_result_out(mem_calc_result_mem),
    .branch_taken_out(),          // unused
    .branch_target_out(),         // unused
    .ctrl_halt_out(ctrl_halt_mem),
    .pcs_value_out(pcs_value_mem),
    .pcs_valid_out(pcs_valid_mem),

    .dest_out(dest_mem),

    .reg_write_enable_out(reg_write_enable_em),

    .mem_to_reg_out(mem_to_reg_mem),

    .opcode_in(opcode_exec),
    .opcode_out(opcode_mem),
    
    .pc_plus2_in(PC_exec),
    .pc_plus2_out(pc_plus2_mem_stage),
    
    .mem_read_in(memRead_exec),
    .mem_write_in(memWrite_exec),
    .mem_read_out(memRead_mem),
    .mem_write_out(memWrite_mem),
    
    .rt_src_in(src2_exec),
    .rt_src_out(rt_src_mem),

    .rt_field_in(rt_field_exec),
    .rt_field_out(rt_field_mem),

    .bp_update_in(bp_update_ex),
    .bp_actual_taken_in(bp_actual_taken_ex),
    .bp_pc_in(bp_pc_ex),

    .bp_update_out(bp_update_mem),
    .bp_actual_taken_out(bp_actual_taken_mem),
    .bp_pc_out(bp_pc_mem)

);





// mem stage
wire [3:0] reg_write_addr_mem;



mem memory0 (
    .clk(clk),
    .rst_n(rst_n),

    .rt_data(rt_data_exec),
    .mem_calc_result(mem_calc_result_mem),
    .aluResult(aluResult_mem),
    .pcs_value(pcs_value_mem),

    .dest(dest_mem),

    .reg_write_enable_in(reg_write_enable_em),

    .mem_to_reg(mem_to_reg_mem),
    .pcs_valid(pcs_valid_mem),
    .memWrite(memWrite_mem),
    .memRead(memRead_mem),

    .M_W_rd(reg_write_addr_wb),
    .M_W_regWrite(reg_write_enable_wb),
    .M_W_data(reg_write_data_wb),

    .reg_write_data(reg_write_data_mem),
    .reg_write_addr(reg_write_addr_mem),
    .reg_write_enable_out(reg_write_enable_mem),

    .rt_src(rt_field_mem),

    .data_mem_out(reg_write_data_mem)       // from dcache read output

);






wire [15:0] pc_plus2_wb_stage;
wire [15:0] reg_write_data_out;         // comes from MEM stage (via MW_pipe)
wire [15:0] alu_result_out;             // comes from EX stage (via MW_pipe)
wire        mem_to_reg_out;             // control signal to WB MUX
wire [15:0] mem_calc_result_out;        // from MW_pipe to WB

MW_pipe mw_pipe (
    .clk(clk),
    .rst_n(rst_n),

    // Inputs
    .reg_write_data_in(reg_write_data_mem),
    .alu_result_in(aluResult_mem),
    .reg_write_addr_in(reg_write_addr_mem),
    .reg_write_enable_in(reg_write_enable_mem),
    .mem_to_reg_in(mem_to_reg_mem),
    .ctrl_halt_in(ctrl_halt_mem),

    .pc_plus2_in(pc_plus2_mem_stage),
    .pc_plus2_out(pc_plus2_wb_stage),

    .reg_write_data_out(reg_write_data_out),
    .alu_result_out(alu_result_out),
    .reg_write_addr_out(reg_write_addr_wb),

    .reg_write_enable_out(reg_write_enable_wb),

    .mem_to_reg_out(mem_to_reg_out),
    .ctrl_halt_out(ctrl_halt_wb),

    .mem_calc_result_in(mem_calc_result_mem),
    .mem_calc_result_out(mem_calc_result_out)
);








writeback writeback0 (
    .clk(clk),
    .rst_n(rst_n),
    .mem_data(reg_write_data_mem),          // from MW_pipe
    .alu_result(alu_result_out),             // from MW_pipe
    .mem_to_reg(mem_to_reg_out),            // from MW_pipe
    .reg_write_data(reg_write_data_wb)      // final result -> decode & forwarding
);




// Added for forwarding
    forwarding_unit forwarding_unit0 (
        .D_E_rs(src1_exec),
        .D_E_rt(src2_exec),

        .D_E_dest(dest_exec), 
        .is_LLB_or_LHB((opcode_exec == 4'b1010) || (opcode_exec == 4'b1011)), 

        .E_M_rd(dest_mem),                      // destination reg from EX/MEM stage
        .E_M_regWrite(reg_write_enable_mem),    // reg write signal from EX/MEM
        .M_W_rd(reg_write_addr_wb),             // destination reg from MEM/WB stage
        .M_W_regWrite(reg_write_enable_wb),     // reg write signal from MEM/WB
        .forwardA(forwardA),
        .forwardB(forwardB)
);








// Decode stage output
wire dbg_reg_write_decode       = reg_write_decode;

// DE_pipe output (Execute stage input)
wire dbg_reg_write_exec         = reg_write_exec;

// Execute stage output (input to EM_pipe)
wire dbg_reg_write_enable_in    = reg_write_exec;

// EM_pipe output (used by MEM and forwarding)
wire dbg_reg_write_enable_mem   = reg_write_enable_mem;

// Control + hazard
wire dbg_stall      = stall;
wire dbg_flush      = flush;
wire dbg_opcode     = opcode_decode;
wire dbg_instr_raw  = instruction_decode;
wire dbg_rst        = rst_n;




assign pc = PC_fetch;



wire halt_detected;

// Add the flip-flop
dff hlt_dff (
    .q(halt_detected),
    .d(ctrl_halt_wb),
    .wen(1'b1),
    .clk(clk),
    .rst(~rst_n)
);

assign hlt = halt_detected;




endmodule