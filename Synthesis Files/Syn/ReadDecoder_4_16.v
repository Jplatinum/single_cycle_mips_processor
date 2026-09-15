module ReadDecoder_4_16(RegId, Wordline);
    input [3:0] RegId;
    output [15:0] Wordline;

    //wire [15:0] one_hot;

    //Shifter decode_RegId(.Shift_Out(one_hot), .Shift_In(16'b1), .Shift_Val(RegId), .Mode(1'b0));

    //assign Wordline = one_hot;

assign Wordline = 16'b1 << RegId;

endmodule
