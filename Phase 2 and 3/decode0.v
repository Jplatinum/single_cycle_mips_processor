module decode(
    input         clk,
    input         rst_n,

    input  [15:0] instr,                // from FD pipe
    input  [15:0] rf_write_data,
    input  [3:0]  rf_write_addr,
    input         rf_write_enable,

    input         stall,                  // <-- Added stall control input

    output [15:0] rs_data,
    output [15:0] rt_data,
    output [3:0]  src1,
    output [3:0]  src2,
    output [3:0]  opcode,
    output [3:0]  dest,
    output [7:0]  imm_field,
    output [2:0]  cond,
    output [8:0]  branch_imm,

    output reg       mem_enable,
    output reg       mem_to_reg,
    output reg       mem_write,
    output reg       alu_src,

    output       reg_write,

    output reg       pcs,
    output reg [2:0] flag_en,

    output [3:0] rt_field
);  

assign rt_field = (instr[15:12] == 4'b1001) ? instr[11:8] : 4'd0;  // SW only

assign opcode     = stall ? 4'd0 : instr[15:12];  // treat as NOP if stalled

// === control signals (pre-stall-mux) ===
wire w_mem_enable;
wire w_mem_to_reg;
wire w_mem_write;
wire w_alu_src;

wire w_pcs;

wire z_en;
wire vn_en;

assign w_mem_enable = (opcode == 4'b1000);
assign w_mem_to_reg = (opcode == 4'b1000);
assign w_mem_write  = (opcode == 4'b1001);
assign w_pcs        = (opcode == 4'b1110);

assign w_alu_src =
    (opcode == 4'b0100) ||  // SLL
    (opcode == 4'b0101) ||  // SRA
    (opcode == 4'b0110) ||  // ROR
    (opcode == 4'b1000) ||  // LW
    (opcode == 4'b1001) ||  // SW
    (opcode == 4'b1010) ||  // LLB
    (opcode == 4'b1011);    // LHB




assign z_en  = (~opcode[3] & ~opcode[1]) | (~opcode[3] & ~opcode[0]);
assign vn_en = (~opcode[3] & ~opcode[2] & ~opcode[1]);
assign w_flag_en = {z_en, {2{vn_en}}};


assign reg_write = stall ? 1'b0 :
    (opcode == 4'b0000) || // ADD
    (opcode == 4'b0001) || // SUB
    (opcode == 4'b0010) || // XOR
    (opcode == 4'b0011) || // RED
    (opcode == 4'b0100) || // SLL
    (opcode == 4'b0101) || // SRA
    (opcode == 4'b0110) || // ROR
    (opcode == 4'b0111) || // PADDSB
    (opcode == 4'b1000) || // LW
    (opcode == 4'b1010) || // LLB
    (opcode == 4'b1011) || // LHB
    (opcode == 4'b1110);   // PCS





    always @(*) begin
        if (stall) begin
            mem_enable  = 1'b0;
            mem_to_reg  = 1'b0;
            mem_write   = 1'b0;
            alu_src     = 1'b0;
            pcs         = 1'b0;
            flag_en     = 3'b000;
        end else begin
            mem_enable  = w_mem_enable;
            mem_to_reg  = w_mem_to_reg;
            mem_write   = w_mem_write;
            alu_src     = w_alu_src;
            pcs         = w_pcs;
            flag_en     = w_flag_en;
        end
    end



    reg [3:0] r_dest;
    reg [3:0] r_src1;
    reg [3:0] r_src2;
    reg [7:0] r_imm; //r instruction immediate
    reg [2:0] r_cond; //condition register
    reg [8:0] r_branch_imm;//immediate val for branch






    always @(*) begin
       // Default assignments for signals not used by a given instruction type.
       r_dest       = 4'd0;
       r_src1       = 4'd0;
       r_src2       = 4'd0;
       r_imm        = 8'd0;
       r_cond       = 3'd0;
       r_branch_imm = 9'd0;
       
       case (opcode)
         //ADD, SUB, XOR, RED, SLL, SRA, ROR, PADDSB
         //0aaa dddd ssss tttt
         4'b0000, 4'b0001, 4'b0010, 4'b0011,
         4'b0100, 4'b0101, 4'b0110, 4'b0111: begin
             r_dest = instr[11:8];
             r_src1 = instr[7:4];
             r_src2 = instr[3:0];
             r_imm  = 8'd0;  // Not used.
         end

         //LW, SW
         //100a tttt ssss oooo
         4'b1000, 4'b1001: begin
             r_dest = instr[11:8];   
             r_src1 = instr[7:4];    
             r_src2 = 4'd0; //N/a
             r_imm  = {4'b0, instr[3:0]};
         end

         //LLB, LHB 
         //101a dddd uuuu uuuu
         4'b1010, 4'b1011: begin
             r_dest = instr[11:8];
             r_src1 = 4'd0;
             r_src2 = 4'd0;
             r_imm  = instr[7:0];   // 8-bit immediate value.
         end

         //B
         //1100 ccci iiiiiiiii,
         4'b1100: begin
             r_cond       = instr[11:9];
             r_branch_imm = instr[8:0];
             r_dest = 4'd0;
             r_src1 = 4'd0;
             r_src2 = 4'd0;
         end

         //BR 
         //1101 cccx ssss xxxx
         4'b1101: begin
             r_cond       = instr[11:9];
             r_branch_imm = 9'd0; //N/a
             r_src1 = instr[7:4]; 

         end

         //PCS
         4'b1110: begin
             r_dest = instr[11:8];
             r_src1 = 4'd0;
             r_src2 = 4'd0;
             r_imm  = 8'd0;
         end

         //HLT
         4'b1111: begin
             r_dest = 4'd0;
             r_src1 = 4'd0;
             r_src2 = 4'd0;
             r_imm  = 8'd0;
         end

         default: begin
             r_dest = 4'd0;
             r_src1 = 4'd0;
             r_src2 = 4'd0;
             r_imm  = 8'd0;
             r_cond = 3'd0;
             r_branch_imm = 9'd0;
         end
       endcase
    end




assign dest       = stall ? 4'd0 : r_dest;
assign src1       = r_src1;  // still needed for forwarding and hazard detection
assign src2       = r_src2;  // still needed for forwarding and hazard detection


wire [7:0] decode_imm_field;

assign decode_imm_field =
    (opcode == 4'b0100 || opcode == 4'b0101 || opcode == 4'b0110) ? {4'd0, instr[3:0]} :  // SLL/SRA/ROR
    (opcode == 4'b1000 || opcode == 4'b1001) ? {4'd0, instr[3:0]} :                       // FIX: LW or SW
    (opcode == 4'b1010 || opcode == 4'b1011) ? instr[7:0] :                               // LLB/LHB
    8'd0;

assign imm_field = stall ? 8'd0 : decode_imm_field;




assign cond       = stall ? 3'd0 : r_cond;
assign branch_imm = stall ? 9'd0 : r_branch_imm;



// Raw outputs from the register file
wire [15:0] rf_rs_data, rf_rt_data;

RegisterFile regFile0 (
    .clk(clk),
    .rst(~rst_n),
    .SrcReg1(r_src1),
    .SrcReg2(r_src2),
    .DstReg(rf_write_addr),
    .WriteReg(rf_write_enable),
    .DstData(rf_write_data),
    .SrcData1(rf_rs_data),
    .SrcData2(rf_rt_data)
);

// FINAL rs_data and rt_data seen by EX stage
assign rs_data = (rf_write_enable && (rf_write_addr == r_src1) && (rf_write_addr != 4'd0)) ? rf_write_data : rf_rs_data;
assign rt_data = (rf_write_enable && (rf_write_addr == r_src2) && (rf_write_addr != 4'd0)) ? rf_write_data : rf_rt_data;


endmodule
