module WriteDecoder_4_16(RegId, WriteReg, Wordline);
    input [3:0] RegId;
    input WriteReg;
    output [15:0] Wordline;

    //wire [15:0] one_hot;

    //Shifter decode_RegId(.Shift_Out(one_hot), .Shift_In(16'b1), .Shift_Val(RegId), .Mode(1'b0)); //select register using one hot encoding

    //assign Wordline = WriteReg ? one_hot : 16'b0;

assign Wordline = (WriteReg) ? (16'b1 << RegId) : 16'b0;
    
endmodule
