// comp_instructions_tb.v
// Test bench for the comp_instructions module (compute operations)

module comp_instructions_tb;

  // Inputs to the comp_instructions module.
  reg  [3:0]  opcode;      // For compute instructions: valid opcodes 0000-0111
  reg  [15:0] rs_data;     // First operand (e.g., from register rs)
  reg  [15:0] rt_data;     // Second operand (e.g., from register rt)
  reg  [3:0]  immediate;   // Immediate value (used for shift amount)

  // Outputs.
  wire [15:0] result;      // ALU result
  wire [2:0]  flag_out;    // Flags: {Overflow, Zero, Negative}

  // Instantiate the comp_instructions module.
  comp_instructions DUT (
    .opcode(opcode),
    .rs_data(rs_data),
    .rt_data(rt_data),
    .immediate(immediate),
    .result(result),
    .flag_out(flag_out)
  );

  initial begin
    $display("Starting comp_instructions tests...");
    
    // -----------------------------
    // Test 1: ADD (opcode 0000)
    // Example: 1000 + 2000 = 3000 (no overflow)
    opcode    = 4'b0000; // ADD: opcode[0]==0 indicates ADD
    rs_data   = 16'd1000;
    rt_data   = 16'd2000;
    immediate = 4'b0000; // Not used for ADD
    #10;
    $display("Test ADD: opcode=%b, rs=%d, rt=%d => result=%d, flags=%b (expected 3000, flags: no ovfl, nonzero, positive)", 
             opcode, rs_data, rt_data, result, flag_out);
    
    // -----------------------------
    // Test 2: SUB (opcode 0001)
    // Example: 2000 - 50 = 1950 (no overflow)
    opcode    = 4'b0001; // SUB: opcode[0]==1 indicates SUB
    rs_data   = 16'd2000;
    rt_data   = 16'd50;
    immediate = 4'b0000;
    #10;
    $display("Test SUB: opcode=%b, rs=%d, rt=%d => result=%d, flags=%b (expected 1950)", 
             opcode, rs_data, rt_data, result, flag_out);
    
    // -----------------------------
    // Test 3: XOR (opcode 0010)
    // Example: 0xAAAA XOR 0x5555 = 0xFFFF.
    opcode    = 4'b0010;
    rs_data   = 16'hAAAA;
    rt_data   = 16'h5555;
    immediate = 4'b0000;
    #10;
    $display("Test XOR: opcode=%b, rs=%h, rt=%h => result=%h, flags=%b (expected FFFF)", 
             opcode, rs_data, rt_data, result, flag_out);
    
    // -----------------------------
    // Test 4: RED (opcode 0011)
    // Example: RED: Let rs_data = 0x1111 and rt_data = 0x2222.
    // Each nibble adds: 1+2 = 3, so total = 3+3+3+3 = 12.
    opcode    = 4'b0011;
    rs_data   = 16'h1111;
    rt_data   = 16'h2222;
    immediate = 4'b0000;
    #10;
    $display("Test RED: opcode=%b, rs=%h, rt=%h => result=%d, flags=%b (expected 12)", 
             opcode, rs_data, rt_data, result, flag_out);
    
    // -----------------------------
    // Test 5: SLL (opcode 0100)
    // Example: Logical shift left: rs_data = 1, immediate = 3 => 1<<3 = 8.
    opcode    = 4'b0100; // SLL when opcode != 0101
    rs_data   = 16'h0001;
    rt_data   = 16'h0000;  // not used
    immediate = 4'd3;
    #10;
    $display("Test SLL: opcode=%b, rs=%h, imm=%d => result=%h, flags=%b (expected 0008)", 
             opcode, rs_data, immediate, result, flag_out);
    
    // -----------------------------
    // Test 6: SRA (opcode 0101)
    // Example: Arithmetic shift right: rs_data = 0xF000, immediate = 4 => expected 0xFF00.
    opcode    = 4'b0101; // SRA
    rs_data   = 16'hF000; // negative in two's complement
    rt_data   = 16'h0000;
    immediate = 4'd4;
    #10;
    $display("Test SRA: opcode=%b, rs=%h, imm=%d => result=%h, flags=%b (expected FF00)", 
             opcode, rs_data, immediate, result, flag_out);
    
    // -----------------------------
    // Test 7: ROR (opcode 0110)
    // Example: Rotate right: rs_data = 1, immediate = 1 => result should be 0x8000.
    opcode    = 4'b0110;
    rs_data   = 16'h0001;
    rt_data   = 16'h0000;
    immediate = 4'd1;
    #10;
    $display("Test ROR: opcode=%b, rs=%h, imm=%d => result=%h, flags=%b (expected 8000)", 
             opcode, rs_data, immediate, result, flag_out);
    
    // -----------------------------
    // Test 8: PADDSB (opcode 0111)
    // Example: For rs_data = 0x1111 and rt_data = 0x2222, each half-byte adds: 1+2=3 -> result=0x3333.
    opcode    = 4'b0111;
    rs_data   = 16'h1111;
    rt_data   = 16'h2222;
    immediate = 4'b0000;
    #10;
    $display("Test PADDSB: opcode=%b, rs=%h, rt=%h => result=%h, flags=%b (expected 3333)", 
             opcode, rs_data, rt_data, result, flag_out);
    
    $display("All tests completed.");
    $finish;
  end

endmodule
