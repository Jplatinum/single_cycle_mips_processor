// decode_tb.v - Test bench for the decode module

module decode_tb;

  // Inputs to the decode module.
  reg         clk;
  reg         rst_n;
  reg  [15:0] instr;
  reg  [15:0] rf_write_data;
  reg  [3:0]  rf_write_addr;
  reg         rf_write_enable;
  
  // Outputs from the decode module.
  wire [15:0] rs_data;
  wire [15:0] rt_data;
  wire [3:0]  src1;
  wire [3:0]  src2;
  wire [3:0]  opcode;
  wire [3:0]  dest;
  wire [7:0]  imm_field;
  wire [2:0]  cond;
  wire [8:0]  branch_imm;
  
  // Instantiate the decode module.
  decode DUT (
    .clk(clk),
    .rst_n(rst_n),
    .instr(instr),
    .rf_write_data(rf_write_data),
    .rf_write_addr(rf_write_addr),
    .rf_write_enable(rf_write_enable),
    .rs_data(rs_data),
    .rt_data(rt_data),
    .src1(src1),
    .src2(src2),
    .opcode(opcode),
    .dest(dest),
    .imm_field(imm_field),
    .cond(cond),
    .branch_imm(branch_imm)
  );
  
  // Clock generation: period = 10 time units.
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // Test sequence.
  initial begin
    // Initialize inputs.
    rst_n          = 0;
    instr          = 16'h0000;
    rf_write_data  = 16'h0000;
    rf_write_addr  = 4'd0;
    rf_write_enable = 1'b0;
    
    // Hold reset for one clock cycle.
    #12;
    rst_n = 1;
    #10;
    
    //-------------------------------------------------------------------------
    // Test 1: Compute Instruction (e.g., ADD)
    // Format for compute instructions: 0aaa dddd ssss tttt.
    // Example: ADD with opcode = 0000, dest = 0101, src1 = 0011, src2 = 0010.
    // Expected: opcode=0000, dest=4'd5, src1=4'd3, src2=4'd2, imm_field = 8'd0.
    // Also, to test register file reads, we write a known value to register 3 and register 2.
    //-------------------------------------------------------------------------
    // Write to register 3 and register 2.
    rf_write_data  = 16'hAAAA;  // Arbitrary value for register 3.
    rf_write_addr  = 4'd3;
    rf_write_enable = 1'b1;
    #10;
    rf_write_enable = 1'b0;
    
    instr = 16'b0000_0101_0011_0010;  // ADD: opcode=0000, dest=5, src1=3, src2=2.
    #10;
    $display("Test 1: Compute (ADD)");
    $display("  instr    = %h", instr);
    $display("  opcode   = %b (expected 0000)", opcode);
    $display("  dest     = %b (expected 0101)", dest);
    $display("  src1     = %b (expected 0011)", src1);
    $display("  src2     = %b (expected 0010)", src2);
    $display("  imm_field= %h (expected 00)", imm_field);
    $display("  Register File: rs_data (reg3) = %h, rt_data (reg2) = %h", rs_data, rt_data);
    
    //-------------------------------------------------------------------------
    // Test 2: Memory Instruction (LW)
    // Format for memory instructions: 100a tttt ssss oooo.
    // Example: LW with opcode = 1000, dest = 0110, src1 = 0011, and offset = 1010.
    // Expected: opcode=1000, dest=6, src1=3, imm_field = {4'b0, 4'b1010} = 8'h0A.
    //-------------------------------------------------------------------------
    #10;
    instr = 16'b1000_0110_0011_1010;  // LW: opcode=1000, dest=6, src1=3, offset=1010.
    #10;
    $display("Test 2: Memory (LW)");
    $display("  instr    = %h", instr);
    $display("  opcode   = %b (expected 1000)", opcode);
    $display("  dest     = %b (expected 0110)", dest);
    $display("  src1     = %b (expected 0011)", src1);
    $display("  imm_field= %h (expected 0A)", imm_field);
    
    //-------------------------------------------------------------------------
    // Test 3: Immediate Load Instruction (LLB)
    // Format for immediate load: 101a dddd uuuu uuuu.
    // Example: LLB with opcode = 1010, dest = 0011, and immediate = 8'hCA.
    // Expected: opcode=1010, dest=3, imm_field = CA, src1 and src2 = 0.
    //-------------------------------------------------------------------------
    #10;
    instr = 16'b1010_0011_1100_1010;  // LLB: opcode=1010, dest=3, immediate = 8'hCA.
    #10;
    $display("Test 3: Immediate Load (LLB)");
    $display("  instr    = %h", instr);
    $display("  opcode   = %b (expected 1010)", opcode);
    $display("  dest     = %b (expected 0011)", dest);
    $display("  imm_field= %h (expected CA)", imm_field);
    $display("  src1     = %b (expected 0000)", src1);
    $display("  src2     = %b (expected 0000)", src2);
    
    //-------------------------------------------------------------------------
    // Test 4: Branch Instruction (B)
    // Format for B: 1100 ccci iiiiiiiii.
    // Example: B with opcode = 1100, condition = 010, branch_imm = 9'b000000101.
    // Expected: opcode=1100, cond = 010, branch_imm = 000000101.
    //-------------------------------------------------------------------------
    #10;
    instr = {4'b1100, 3'b010, 9'b000000101};  // B instruction.
    #10;
    $display("Test 4: Branch (B)");
    $display("  instr      = %h", instr);
    $display("  opcode     = %b (expected 1100)", opcode);
    $display("  cond       = %b (expected 010)", cond);
    $display("  branch_imm = %b (expected 000000101)", branch_imm);
    
    //-------------------------------------------------------------------------
    // Test 5: Branch Register Instruction (BR)
    // Format for BR: 1101 cccx ssss xxxx.
    // Example: BR with opcode = 1101, condition = 011, and src1 = 1010.
    // Expected: opcode=1101, cond = 011, src1 = 1010, branch_imm = 0.
    //-------------------------------------------------------------------------
    #10;
    instr = 16'b1101_0110_1010_1111;  // BR: opcode=1101, cond=011, src1 = bits[7:4]=1010.
    #10;
    $display("Test 5: Branch Register (BR)");
    $display("  instr    = %h", instr);
    $display("  opcode   = %b (expected 1101)", opcode);
    $display("  cond     = %b (expected 011)", cond);
    $display("  src1     = %b (expected 1010)", src1);
    $display("  branch_imm = %b (expected 000000000)", branch_imm);
    
    //-------------------------------------------------------------------------
    // Test 6: PCS Instruction
    // Format for PCS: 1110 dddd xxxx xxxx.
    // Example: PCS with opcode = 1110 and dest = 1010.
    // Expected: opcode=1110, dest = 1010.
    //-------------------------------------------------------------------------
    #10;
    instr = 16'b1110_1010_0000_0000;  // PCS: opcode=1110, dest=1010.
    #10;
    $display("Test 6: PCS");
    $display("  instr    = %h", instr);
    $display("  opcode   = %b (expected 1110)", opcode);
    $display("  dest     = %b (expected 1010)", dest);
    
    //-------------------------------------------------------------------------
    // Test 7: HLT Instruction
    // Format for HLT: 1111 xxxx xxxx xxxx.
    // Example: HLT with opcode = 1111.
    // Expected: opcode=1111 and all other decoded fields are 0.
    //-------------------------------------------------------------------------
    #10;
    instr = 16'b1111_0000_0000_0000;  // HLT: opcode=1111.
    #10;
    $display("Test 7: HLT");
    $display("  instr     = %h", instr);
    $display("  opcode    = %b (expected 1111)", opcode);
    $display("  dest      = %b (expected 0000)", dest);
    $display("  src1      = %b (expected 0000)", src1);
    $display("  src2      = %b (expected 0000)", src2);
    $display("  imm_field = %h (expected 00)", imm_field);
    $display("  cond      = %b (expected 000)", cond);
    $display("  branch_imm= %b (expected 000000000)", branch_imm);
    
    #20;
    $finish;
  end

endmodule
