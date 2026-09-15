module icache (

    input clk,
    input rst,
    input [15:0] addr,                  // Address to fetch instruction from PC
    output [15:0] data_out,             // Output instruction word to fetch stage
    output cache_hit,                   // High if instruction was found in cache
    output cache_stall,                 // High while waiting on cache fill
    input grant,

    // Memory interface
    output [15:0] mem_addr,             // Memory address to fetch from during miss
    output mem_request,                 // High while a miss is being handled
    input [15:0] mem_data,              // 2 byte word from memory
    input mem_valid                     // High when memory returns valid data

);


wire [5:0] tag    = addr[15:10];        // 6 bit tag for identifying blocks
wire [5:0] index  = addr[9:4];          // 6 bit index selects 1 of 64 sets
wire [2:0] offset = addr[3:1];          // 3 bit word offset selects 1 of 8 words in 16B block

wire [2:0] chunk_offset;
wire fsm_busy;                          // FSM is actively filling a block
wire write_data_array;                  // Enables writing current mem_data to data array
wire write_tag_array;                   // Enables writing tag/LRU/valid to meta array

cache_fill_FSM icache_fill_fsm (
    .clk(clk),
    .rst_n(~rst),
    .miss_detected(~cache_hit),                 // Trigger FSM if current fetch missed
    .miss_address(addr),                        // Address that missed, to be filled
    .memory_data(mem_data),                     // Incoming data from memory 2B chunk
    .memory_data_valid(mem_valid),
    .fsm_busy(fsm_busy),
    .write_data_array(write_data_array),
    .write_tag_array(write_tag_array),
    .memory_address(mem_addr),                   // Memory address being requested for fill
    .chunk_index(chunk_offset)
);



// Data and tag outputs for both ways
wire [15:0] way0_data_out, way1_data_out;
wire [7:0] way0_tag_out, way1_tag_out;

wire [5:0] tag0 = way0_tag_out[5:0];            // Extract stored tag
wire       valid0 = way0_tag_out[7];            // Valid bit is MSB
wire       match0 = valid0 && (tag0 == tag);    // Hit if valid and tag matches

wire [5:0] tag1 = way1_tag_out[5:0];
wire       valid1 = way1_tag_out[7];
wire       match1 = valid1 && (tag1 == tag);

wire [7:0] word_enable = write_data_array ? (8'b1 << chunk_offset) : (8'b1 << offset);
wire [63:0] set_enable = (64'b1 << index);
wire cache_miss = ~(match0 || match1);
wire lru0 = way0_tag_out[6];

// Way 0 maps to blocks [0–63], Way 1 to [64–127]
wire [127:0] block_enable_0 = {64'b0, set_enable};
wire [127:0] block_enable_1 = {set_enable, 64'b0};

// Deciding which cache way to fill on a miss
wire use_way0 = ~valid0 ? 1'b1 :                // Use Way 0 if invalid, prefer free block
                ~valid1 ? 1'b0 :                // Use Way 1 if invalid
                (lru0 ? 1'b0 : 1'b1);           // Both valid, evict the LRU way


// Latch which way we are going to fill
reg refill_way;
always @(posedge clk, negedge rst) begin
    if (!rst) 
        refill_way <= 1'b0;
    else if (cache_miss)
        refill_way <= use_way0;
end




// Only enable write to one way based on use_way0 decision during a miss
//wire [127:0] block_enable_write0 = (cache_miss && use_way0) ? block_enable_0 : 128'b0;
//wire [127:0] block_enable_write1 = (cache_miss && ~use_way0) ? block_enable_1 : 128'b0;
wire [127:0] block_enable_write0 = (fsm_busy && refill_way)    ? block_enable_0 : 128'b0;
wire [127:0] block_enable_write1 = (fsm_busy && !refill_way)   ? block_enable_1 : 128'b0;



// Use write enables if FSM is writing; otherwise normal read enable
wire [127:0] block_enable_0_final = write_data_array ? block_enable_write0 : block_enable_0;
wire [127:0] block_enable_1_final = write_data_array ? block_enable_write1 : block_enable_1;

// Data written to meta array, format: [valid=1] [LRU bit] [6 bit tag]
//wire [7:0] meta_in_way0 = {1'b1, use_way0 ? 1'b0 : 1'b1, tag};
//wire [7:0] meta_in_way1 = {1'b1, use_way0 ? 1'b1 : 1'b0, tag};
wire [7:0] meta_in_way0 = {1'b1, refill_way ? 1'b0 : 1'b1, tag};
wire [7:0] meta_in_way1 = {1'b1, refill_way ? 1'b1 : 1'b0, tag};


// Cache Array Instantiations
DataArray data_array0(
    .clk(clk),
    .rst(rst),
    .DataIn(mem_data),
    .Write(write_data_array),
    .BlockEnable(block_enable_0_final),
    .WordEnable(word_enable),
    .DataOut(way0_data_out)
);

MetaDataArray meta_array0(
    .clk(clk),
    .rst(rst),
    .DataIn(meta_in_way0),
    .Write(write_tag_array),
    .BlockEnable(block_enable_0_final),
    .DataOut(way0_tag_out)
);

DataArray data_array1(
    .clk(clk),
    .rst(rst),
    .DataIn(mem_data),
    .Write(write_data_array),
    .BlockEnable(block_enable_1_final),
    .WordEnable(word_enable),
    .DataOut(way1_data_out)
);

MetaDataArray meta_array1(
    .clk(clk),
    .rst(rst),
    .DataIn(meta_in_way1),
    .Write(write_tag_array),
    .BlockEnable(block_enable_1_final),
    .DataOut(way1_tag_out)
);

// Selecting which data to return on a hit
assign data_out = match0 ? way0_data_out :
                  match1 ? way1_data_out :
                  16'hxxxx;

assign cache_hit = match0 || match1;                        // Hit if either match
assign mem_request = fsm_busy;                              // High when FSM is active
assign cache_stall = fsm_busy || (mem_request && !grant);


endmodule