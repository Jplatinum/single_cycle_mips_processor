// mem_exec_tb.v - Test bench for the memory/execute stage.

module mem_exec_tb;

  // Clock and reset.
  reg clk;
  reg rst_n;
  
  // Inputs for memory_exec.
  reg  [3:0]  opcode;
  reg  [3:0]  dest;       // destination register (if applicable)
  reg  [7:0]  imm_field;  // immediate field (for non-branch instructions)
  reg  [2:0]  cond;       // condition code (for branch instructions)
  reg  [8:0]  branch_imm; // branch immediate (for branch instructions)
  reg  [15:0] current_PC; // PC from fetch stage
  reg  [15:0] rs_data;    // data from register file port 1
  reg  [15:0] rt_data;    // data from register file port 2
  reg  [3:0]  src1;       // base register (for memory instructions)
  
  // Outputs from memory_exec.
  wire        memRead;
  wire        memWrite;
  wire        memReadorWrite;
  wire [15:0] aluResult;
  wire [15:0] writeData;
  wire        branch_taken;
  wire [15:0] branch_target;
  wire        ctrl_halt;
  wire [15:0] reg_write_data;
  wire [3:0]  reg_write_addr;
  wire        reg_write_enable;
  
  // Instantiate the memory_exec module.
  memory_exec DUT (
    .clk(clk),
    .rst_n(rst_n),
    .opcode(opcode),
    .dest(dest),
    .imm_field(imm_field),
    .cond(cond),
    .branch_imm(branch_imm),
    .current_PC(current_PC),
    .rs_data(rs_data),
    .rt_data(rt_data),
    .src1(src1),
    .memRead(memRead),
    .memWrite(memWrite),
    .memReadorWrite(memReadorWrite),
    .aluResult(aluResult),
    .writeData(writeData),
    .branch_taken(branch_taken),
    .branch_target(branch_target),
    .ctrl_halt(ctrl_halt),
    .reg_write_data(reg_write_data),
    .reg_write_addr(reg_write_addr),
    .reg_write_enable(reg_write_enable)
  );
  
  // Clock generation: period = 10 time units.
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // Reset generation.
  initial begin
    rst_n = 0;
    #15;
    rst_n = 1;
  end
  
  // Test sequence.
  initial begin
    // Allow reset to propagate.
    #20;
    $display("============================================");
    $display("Test 1: Compute Instruction (ADD, opcode 0000)");
    // For a compute instruction (e.g. ADD), format: 0aaa dddd ssss tttt.
    // Example: ADD with opcode=0000, dest=0101, src1=0011, src2=0010.
    // We assume the ALU in comp_instructions does addition.
    opcode      = 4'b0000;  // ADD
    dest        = 4'b0101;  // destination register (5) [used only for write-back routing]
    imm_field   = 8'h00;    // not used in compute instructions
    cond        = 3'b000;
    branch_imm  = 9'd0;
    current_PC  = 16'h0100;
    // Set the ALU operands: rs_data + rt_data.
    rs_data     = 16'd5;
    rt_data     = 16'd3;
    src1        = 4'd0;     // not used by compute ALU
    #10;
    $display("Compute: aluResult = %h (expected 8)", aluResult);
    $display("Write-back: reg_write_data = %h, reg_write_enable = %b, reg_write_addr = %b", 
             reg_write_data, reg_write_enable, reg_write_addr);
    $display("memRead = %b, memWrite = %b", memRead, memWrite);
    
    //-------------------------------------------------------------------------
    #10;
    $display("============================================");
    $display("Test 2: Memory Instruction (LW, opcode 1000)");
    // For LW, encoding: 100a tttt ssss oooo.
    // Example: LW with opcode=1000, dest=0110, base register=from rs_data.
    // Let offset = 4'b0011 -> imm_field = 8'h03.
    // Expected address: (rs_data & 0xFFFE) + (signextend(offset) << 1).
    // Choose: rs_data = 16'h1002. Then (1002 & FFFE) = 1002, offset 3 => (3<<1)=6, so expected mem_calc_result = 1002 + 6 = 1008.
    // We assume data memory (dmem) has been preloaded so that dmem[16'h1008] = 16'hBEEF.
    opcode      = 4'b1000;  // LW
    dest        = 4'b0110;  // destination register 6
    imm_field   = {4'b0, 4'b0011};  // offset = 3
    cond        = 3'b000;
    branch_imm  = 9'd0;
    current_PC  = 16'h1000;
    rs_data     = 16'h1002; // base register value
    rt_data     = 16'h0000; // not used for LW
    src1        = 4'd3;     // base register index (arbitrary)
    #10;
    $display("LW: aluResult (address) = %h (expected 1008)", aluResult);
    $display("memRead = %b (expected 1), memWrite = %b (expected 0)", memRead, memWrite);
    $display("Write-back: reg_write_data = %h (expected from dmem, e.g. BEEF)", reg_write_data);
    
    //-------------------------------------------------------------------------
    #10;
    $display("============================================");
    $display("Test 3: Memory Instruction (SW, opcode 1001)");
    // For SW, encoding is similar to LW but no write-back.
    opcode      = 4'b1001;  // SW
    dest        = 4'b0110;  // not used for SW
    imm_field   = {4'b0, 4'b0011};  // same offset = 3
    cond        = 3'b000;
    branch_imm  = 9'd0;
    current_PC  = 16'h1000;
    rs_data     = 16'h1002; // base register
    rt_data     = 16'hDEAD; // data to store
    src1        = 4'd3;
    #10;
    $display("SW: writeData = %h (expected 0xDEAD)", writeData);
    $display("memWrite = %b (expected 1), reg_write_enable = %b (expected 0)", memWrite, reg_write_enable);
    
    //-------------------------------------------------------------------------
    #10;
    $display("============================================");
    $display("Test 4: Immediate Load (LLB, opcode 1010)");
    // For LLB, encoding: 101a dddd uuuu uuuu.
    // Example: LLB with opcode=1010, dest=0011, immediate = 8'h12.
    // Expected: result = (rt_data & 0xFF00) | 8'h12.
    opcode      = 4'b1010;  // LLB
    dest        = 4'b0011;  // destination register 3
    imm_field   = 8'h12;    // immediate value 0x12
    cond        = 3'b000;
    branch_imm  = 9'd0;
    current_PC  = 16'h2000;
    // For LLB, rt_data is used (via read-modify-write) to preserve upper 8 bits.
    rt_data     = 16'hABCD;
    rs_data     = 16'h0000; // not used
    src1        = 4'd0;
    #10;
    $display("LLB: reg_write_data = %h (expected %h)", 
             reg_write_data, (16'hABCD & 16'hFF00) | 16'h0012);
    
    //-------------------------------------------------------------------------
    #10;
    $display("============================================");
    $display("Test 5: Immediate Load (LHB, opcode 1011)");
    // For LHB, encoding: 101a dddd uuuu uuuu.
    // Example: LHB with opcode=1011, dest=0100, immediate = 8'h34.
    // Expected: result = (rt_data & 0x00FF) | (8'h34 << 8).
    opcode      = 4'b1011;  // LHB
    dest        = 4'b0100;  // destination register 4
    imm_field   = 8'h34;    // immediate value 0x34
    cond        = 3'b000;
    branch_imm  = 9'd0;
    current_PC  = 16'h3000;
    rt_data     = 16'h1234;
    rs_data     = 16'h0000;
    src1        = 4'd0;
    #10;
    $display("LHB: reg_write_data = %h (expected %h)", 
             reg_write_data, (16'h1234 & 16'h00FF) | (8'h34 << 8));
    
    //-------------------------------------------------------------------------
    #10;
    $display("============================================");
    $display("Test 6: PCS Instruction (opcode 1110)");
    // For PCS, encoding: 1110 dddd xxxx xxxx.
    // PCS should output pcs_value (we assume pcs_value = current_PC + 2).
    opcode      = 4'b1110;  // PCS
    dest        = 4'b0101;  // destination register 5
    imm_field   = 8'h00;
    cond        = 3'b000;
    branch_imm  = 9'd0;     // not used for PCS
    current_PC  = 16'h4000;
    rs_data     = 16'h0000;
    rt_data     = 16'h0000;
    src1        = 4'd0;
    #10;
    $display("PCS: reg_write_data = %h (expected %h)", 
             reg_write_data, 16'h4002);
    
    //-------------------------------------------------------------------------
    #10;
    $display("============================================");
    $display("Test 7: HLT Instruction (opcode 1111)");
    // For HLT, encoding: 1111 xxxx xxxx xxxx.
    // Expected: ctrl_halt should be asserted and no write-back.
    opcode      = 4'b1111;  // HLT
    dest        = 4'b0000;
    imm_field   = 8'h00;
    cond        = 3'b000;
    branch_imm  = 9'd0;
    current_PC  = 16'h5000;
    rs_data     = 16'h0000;
    rt_data     = 16'h0000;
    src1        = 4'd0;
    #10;
    $display("HLT: ctrl_halt = %b (expected 1), reg_write_enable = %b (expected 0)", ctrl_halt, reg_write_enable);
    
    #20;
    $display("============================================");
    $finish;
  end

endmodule
