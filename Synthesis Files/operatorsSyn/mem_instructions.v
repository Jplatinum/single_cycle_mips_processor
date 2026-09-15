//handle mem instructions
//LW, SW, LLB, LHB

module mem_instr (

    input [3:0] opcode,
    input [3:0] rs,
    input [15:0] rs_data,
    input [15:0] rt_data,
    input [7:0] imm_field,
    output reg [15:0] result

);


wire [15:0] address;

assign address = (rs_data & 16'hFFFE) + ({{12{imm_field[3]}}, imm_field[3:0]} << 1);



    always @(*)
		casex (opcode)
			4'b100?: result = address; // LW or SW
			4'b1010: result = (rt_data & 16'hFF00) | imm_field; //LLB
			4'b1011: result = (rt_data & 16'h00FF) | (imm_field << 8); //LHB
			default: result = 16'b0;
		endcase
endmodule
