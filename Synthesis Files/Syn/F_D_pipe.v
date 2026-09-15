module FD_pipe (
    input clk,
    input rst_n,

    input [15:0] instr_in,           // comes from fetch output

    input enable,                    // control from hazard detection
    input flush,                        // control from hazard detection

    input [15:0] pc_plus_2_in,           // comes from fetch output
    output [15:0] pc_plus_2_out,       // Sends to decode stage

    output [15:0] instr_out             // sends to decode stage 
);


    wire rst = ~rst_n;

    wire [15:0] instr_d;
    wire [15:0] pc_plus_2_d;

    assign instr_d = flush ? 16'h0000 : instr_in;
    assign pc_plus_2_d = pc_plus_2_in;

    dff instr_ff [15:0] (
        .clk(clk),
        .rst(rst),
        .wen(enable),
        .d(instr_d),
        .q(instr_out)
    );

    dff pc_plus_2_ff [15:0] (
        .clk(clk),
        .rst(rst),
        .wen(enable),
        .d(pc_plus_2_d),
        .q(pc_plus_2_out)
    );





endmodule
