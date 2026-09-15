module arbiter (
    input clk,
    input rst_n,

    input icache_req,
    input dcache_req,
    input icache_done,
    input dcache_done,

    input  [15:0] icache_addr,
    input  [15:0] icache_data,
    input         icache_we,
    
    input  [15:0] dcache_addr,
    input  [15:0] dcache_data,
    input         dcache_we,

    output reg grant_icache,
    output reg grant_dcache,

    output [15:0] mem_addr,
    output [15:0] mem_write_data,
    output        mem_write_enable
);


// i think we should implement grant control "sequentially" to persist the grant across multiple cycles?
// once a cache wins it keeps access until its miss handler finishes

always @(posedge clk, negedge rst_n) begin

    if (!rst_n) begin
        grant_icache <= 0;
        grant_dcache <= 0;
    end

    else begin

        if (grant_icache && icache_done)
            grant_icache <= 0;

        else if (grant_dcache && dcache_done)
            grant_dcache <= 0;

        else if (!grant_icache && !grant_dcache) begin                  // Priority: grant I-cache if both request

            if (icache_req)
                grant_icache <= 1;
            else if (dcache_req)
                grant_dcache <= 1;

    
        end
    end
end


assign mem_addr         = grant_icache ? icache_addr  : dcache_addr;
assign mem_write_data   = grant_icache ? icache_data  : dcache_data;
assign mem_write_enable = grant_icache ? icache_we    : dcache_we;


endmodule
