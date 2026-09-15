//register file wrapper to view contents at cpu testbench runtime
module RegisterFileWrapper(
    input         clk,
    input         rst,
    input  [3:0]  SrcReg1,
    input  [3:0]  SrcReg2,
    input  [3:0]  DstReg,
    input         WriteReg,
    input  [15:0] DstData,
    output [15:0] SrcData1,
    output [15:0] SrcData2,
    output [3:0]  writeregsel,  
    output        write,       
    output [15:0] writedata    
);

   RegisterFile rf_inst (
       .clk(clk),
       .rst(rst),
       .SrcReg1(SrcReg1),
       .SrcReg2(SrcReg2),
       .DstReg(DstReg),
       .WriteReg(WriteReg),
       .DstData(DstData),
       .SrcData1(SrcData1),
       .SrcData2(SrcData2)
   );

   assign writeregsel = DstReg;
   assign write       = WriteReg;
   assign writedata   = DstData;
endmodule
