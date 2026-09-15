module fetch(
    input clk,
    input rst_n,

    input branch_taken,             // select for first mux of diagram, chooses PC+2 or branch target?
    input [15:0] branch_target,     // COMES FROM output of some adder in the decode stage?
    input pc_enable,               // New input from hazard detection

    input halt_fetch_block,         // <-- New input

    output [15:0] instr,            // send to FD pipe
    output [15:0] pc_plus_2,         // send to FD pipe

    output [15:0] PC,             //  the current PC, not needed downstream?

    output [15:0] icache_mem_addr,
    output        icache_mem_req,
    input  [15:0] mem_data_main,
    input         mem_valid_main,

    output icache_hit_signal,
    input grant_icache,

    output        cache_stall

);

    wire [15:0] seq_pc;
    wire [15:0] next_PC;




   //PC incrementer
   addsub16bit pc_adder (
       .A(PC),
       .B(16'd2),
       .sub(1'b0),
       .Sum(seq_pc),
       .Ovfl()
   );
   
assign pc_plus_2 = seq_pc;
assign next_PC = branch_taken ? branch_target : seq_pc;
   
   //hold pc val
   Register PC_reg (
       .clk(clk),
       .rst(~rst_n),
       .D(next_PC),
       .WriteReg( (pc_enable === 1'b1) && (halt_fetch_block === 1'b0) && (icache_hit_signal) ),            // <-- actual PC update condition
       .ReadEnable1(1'b1),
       .ReadEnable2(1'b0),
       .Bitline1(PC),
       .Bitline2()
   );
   


wire [15:0] icache_data_out;

icache icache0 (
    .clk(clk),
    .rst(~rst_n),
    .addr(PC),
    .data_out(icache_data_out),
    .cache_hit(icache_hit_signal),

    .cache_stall(cache_stall),

    .mem_addr(icache_mem_addr),
    .mem_request(icache_mem_req),
    .mem_data(mem_data_main),
    .mem_valid(mem_valid_main),
    .grant(grant_icache)
);


wire [15:0] instr_reg;
assign instr = instr_reg;

dff instr_ff[15:0] (
    .q(instr_reg),
    .d(icache_data_out),
    .wen(icache_hit_signal),
    .clk(clk),
    .rst(~rst_n)
);


endmodule
