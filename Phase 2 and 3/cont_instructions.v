//handle control instruction
//B, BR. PCs, HLT
module contr_instructions (
  opcode,       
  cond,         
  imm_field,    
  pc_next,    
  flag_N,
  flag_Z,
  flag_V,
  rs_val, 
  branch_taken,
  branch_target,
  pcs_valid,
  pcs_value,
  halt
);

input  [3:0]  opcode;       
input  [2:0]  cond;         
input  [8:0]  imm_field;    
input  [15:0] pc_next;    
input         flag_N;
input         flag_Z;
input         flag_V;
input  [15:0] rs_val; 
output reg        branch_taken;
output reg [15:0] branch_target;
output reg        pcs_valid;
output reg [15:0] pcs_value;
output reg        halt;

  wire sign = imm_field[8];
  wire [15:0] offset_extend = { {7{sign}}, imm_field };
  wire [15:0] shifted_offset = offset_extend << 1;
  

  wire [15:0] b_target;
  addsub16bit adder_b (
      .A(pc_next),
      .B(shifted_offset),
      .sub(1'b0),
      .Sum(b_target),
      .Ovfl()
  );
  
  reg cond_true;
  always @(*) begin
      
      branch_taken = 1'b0;
      branch_target = 16'd0;
      pcs_valid = 1'b0;
      pcs_value = 16'd0;
      halt = 1'b0;
      cond_true = 1'b0;
      
      case (opcode)
        //branch inst B
        4'b1100: begin
            case (cond)
              3'b000: cond_true = (flag_Z == 1'b0);
              3'b001: cond_true = (flag_Z == 1'b1);
              3'b010: cond_true = ((flag_N == 1'b0) && (flag_Z == 1'b0));
              3'b011: cond_true = (flag_N == 1'b1);
              3'b100: cond_true = ((flag_Z == 1'b1) || ((flag_N == 1'b0) && (flag_Z == 1'b0)));
              3'b101: cond_true = ((flag_N == 1'b1) || (flag_Z == 1'b1));
              3'b110: cond_true = (flag_V == 1'b1);
              3'b111: cond_true = 1'b1;
              default: cond_true = 1'b0;
            endcase
            branch_taken = cond_true;
            branch_target = cond_true ? b_target : 16'd0;
        end
        // BR inst
        4'b1101: begin
            case (cond)
              3'b000: cond_true = (flag_Z == 1'b0);
              3'b001: cond_true = (flag_Z == 1'b1);
              3'b010: cond_true = ((flag_N == 1'b0) && (flag_Z == 1'b0));
              3'b011: cond_true = (flag_N == 1'b1);
              3'b100: cond_true = ((flag_Z == 1'b1) || ((flag_N == 1'b0) && (flag_Z == 1'b0)));
              3'b101: cond_true = ((flag_N == 1'b1) || (flag_Z == 1'b1));
              3'b110: cond_true = (flag_V == 1'b1);
              3'b111: cond_true = 1'b1;
              default: cond_true = 1'b0;
            endcase
            branch_taken = cond_true;
            branch_target = cond_true ? rs_val : 16'd0;
        end
        //PCS inst 
        4'b1110: begin
            pcs_valid = 1'b1;
            //assign pcs next to pcs reg
            pcs_value = pc_next;
            
           
        end
        //HLT
        4'b1111: begin
            halt = 1'b1;
        end
        default: begin //non control op (default)
            branch_taken = 1'b0;
            pcs_valid = 1'b0;
            halt = 1'b0;
        end
      endcase
  end

endmodule
