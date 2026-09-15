module forwarding_unit(
    input [3:0] D_E_rs,
    input [3:0] D_E_rt,

    input [3:0] E_M_rd,
    input       E_M_regWrite,

    input [3:0] M_W_rd,
    input       M_W_regWrite,

    input       is_LLB_or_LHB,              // <-- NEW input signal
    input [3:0] D_E_dest,                   // <-- NEW input signal (destination reg in EX stage)

    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);

always @(*) begin
    forwardA = 2'b00;
    forwardB = 2'b00;

    // EX hazard
    if (E_M_regWrite && (E_M_rd != 4'd0) && (E_M_rd == (is_LLB_or_LHB ? D_E_dest : D_E_rs)))
        forwardA = 2'b01;
    if (E_M_regWrite && (E_M_rd != 4'd0) && (E_M_rd == (is_LLB_or_LHB ? D_E_dest : D_E_rt)))
        forwardB = 2'b01;

    // MEM hazard
    if (M_W_regWrite && (M_W_rd != 4'd0) &&
        !(E_M_regWrite && (E_M_rd != 4'd0) && (E_M_rd == (is_LLB_or_LHB ? D_E_dest : D_E_rs))) &&
        (M_W_rd == (is_LLB_or_LHB ? D_E_dest : D_E_rs)))
        forwardA = 2'b10;

    if (M_W_regWrite && (M_W_rd != 4'd0) &&
        !(E_M_regWrite && (E_M_rd != 4'd0) && (E_M_rd == (is_LLB_or_LHB ? D_E_dest : D_E_rt))) &&
        (M_W_rd == (is_LLB_or_LHB ? D_E_dest : D_E_rt)))
        forwardB = 2'b10;
end

endmodule
