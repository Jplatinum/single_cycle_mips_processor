module RegisterFile(clk, rst, SrcReg1, SrcReg2, DstReg, WriteReg, DstData, SrcData1, SrcData2);

    input clk;
    input rst;
    input [3:0] SrcReg1;
    input [3:0] SrcReg2;
    input [3:0] DstReg;
    input WriteReg;
    input [15:0] DstData;

    inout [15:0] SrcData1;
    inout [15:0] SrcData2;
    
    wire [15:0] read_wordline1;
    wire [15:0] read_wordline2;
    wire [15:0] write_wordline;

    wire [15:0] reg_data1;
    wire [15:0] reg_data2;
    

    //decode register (1 hot)
    ReadDecoder_4_16 decoder1 (.RegId(SrcReg1), .Wordline(read_wordline1));
    ReadDecoder_4_16 decoder2 (.RegId(SrcReg2), .Wordline(read_wordline2));
    WriteDecoder_4_16 decoder3 (.RegId(DstReg), .WriteReg(WriteReg), .Wordline(write_wordline));
    
    Register reg_file [15:0] (
        .clk(clk),
        .rst(rst),
        .D(DstData),
        .WriteReg(write_wordline),
        .ReadEnable1(read_wordline1),
        .ReadEnable2(read_wordline2),
        .Bitline1(reg_data1),
        .Bitline2(reg_data2)
    );

    //bypass re-read if src and dest are same
//assign SrcData1 = (SrcReg1 == DstReg && WriteReg) ? DstData : reg_data1;
//assign SrcData2 = (SrcReg2 == DstReg && WriteReg) ? DstData : reg_data2;

assign SrcData1 = reg_data1;
assign SrcData2 = reg_data2;

endmodule
