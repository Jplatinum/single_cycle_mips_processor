module fetch(
    input clk,
    input rst_n,

    input branch_taken,             // real result from EX stage (for updating predictor)
    input [15:0] branch_target,     // computed in EX stage or decode

    input pc_enable,                // from hazard detection
    input halt_fetch_block,        // halt/stall logic

    input bp_update,               // NEW: signal to update the prediction table
    input bp_actual_taken,         // NEW: actual branch outcome from EX stage
    input [15:0] bp_pc,            // NEW: PC of the branch to update in table

    output [15:0] instr,           // to FD pipe
    output [15:0] pc_plus_2,       // to FD pipe

    output [15:0] PC,              // current PC

    output [15:0] icache_mem_addr,
    output        icache_mem_req,
    input  [15:0] mem_data_main,
    input         mem_valid_main,

    output icache_hit_signal,
    input grant_icache,

    output cache_stall
);

    wire [15:0] seq_pc;
    wire [15:0] next_PC;
    wire predicted_taken;

    // Simple PC+2 logic
    assign seq_pc = PC + 16'd2;
    assign pc_plus_2 = seq_pc;

    // Branch predictor instantiation
    branch_predictor predictor0 (
        .clk(clk),
        .rst_n(rst_n),
        .PC(PC),                      // used to get prediction
        .update(bp_update),          // EX/MEM stage triggers update
        .actual_taken(bp_actual_taken),
        .bp_pc(bp_pc),               // PC of the branch to update
        .predicted_taken(predicted_taken)
    );

    // Next PC comes from prediction
    assign next_PC = predicted_taken ? branch_target : seq_pc;

    // PC register
    Register PC_reg (
        .clk(clk),
        .rst(~rst_n),
        .D(next_PC),
        .WriteReg((pc_enable === 1'b1) && (halt_fetch_block === 1'b0) && (icache_hit_signal)),
        .ReadEnable1(1'b1),
        .ReadEnable2(1'b0),
        .Bitline1(PC),
        .Bitline2()
    );

    // Instruction memory / I-cache
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

    // Instruction register
    reg [15:0] instr_reg;
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            instr_reg <= 16'h0000;
        else if (icache_hit_signal)
            instr_reg <= icache_data_out;
    end

    assign instr = instr_reg;

endmodule
