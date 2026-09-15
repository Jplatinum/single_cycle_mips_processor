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

  

wire [15:0] b_target = pc_next + ({{7{imm_field[8]}}, imm_field} << 1);
  
reg cond_true;
always @(*) begin
    // Defaults
    branch_taken = 1'b0;
    branch_target = 16'd0;
    pcs_valid = 1'b0;
    pcs_value = 16'd0;
    halt = 1'b0;
    cond_true = 1'b0;

    // Shared cond evaluation
    case (cond)
        3'b000: cond_true = (flag_Z == 1'b0);                               // NE
        3'b001: cond_true = (flag_Z == 1'b1);                               // EQ
        3'b010: cond_true = (flag_N == 1'b0 && flag_Z == 1'b0);             // GT
        3'b011: cond_true = (flag_N == 1'b1);                               // LT
        3'b100: cond_true = (flag_Z == 1'b1 || (flag_N == 1'b0 && flag_Z == 1'b0)); // GTE
        3'b101: cond_true = (flag_N == 1'b1 || flag_Z == 1'b1);             // LTE
        3'b110: cond_true = (flag_V == 1'b1);                               // OVF
        3'b111: cond_true = 1'b1;                                           // UNCOND
        default: cond_true = 1'b0;
    endcase;

    case (opcode)
        4'b1100: begin // B
            branch_taken = cond_true;
            branch_target = cond_true ? b_target : 16'd0;
        end
        4'b1101: begin // BR
            branch_taken = cond_true;
            branch_target = cond_true ? rs_val : 16'd0;
        end
        4'b1110: begin // PCS
            pcs_valid = 1'b1;
            pcs_value = pc_next;
        end
        4'b1111: halt = 1'b1;
        default: ; // nothing
    endcase
end

endmodule
