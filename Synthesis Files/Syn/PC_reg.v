module PC_reg(
    clk,
    rst_n,
    next_PC,
    PC
);

    input         clk;
    input         rst_n;       
    input  [15:0] next_PC;     
    output [15:0] PC;

    wire rst_sync = ~rst_n;
    
    wire [15:0] write_en;
    assign write_en = 16'hFFFF;
    
    wire [15:0] read_en1, read_en2;
    assign read_en1 = 16'hFFFF;
    assign read_en2 = 16'hFFFF;
    
    Register reg_file [15:0] (
        .clk(clk),
        .rst(rst_sync),
        .D(next_PC),
        .WriteReg(write_en),
        .ReadEnable1(read_en1),
        .ReadEnable2(read_en2),
        .Bitline1(PC),
        .Bitline2() 
    );
    
endmodule
