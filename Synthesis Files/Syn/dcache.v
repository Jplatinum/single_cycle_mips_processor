module dcache (

    input clk,
    input rst,

    // Interface with MEM stage
    input [15:0] addr,
    input [15:0] write_data,
    input mem_read,
    input mem_write,
    output [15:0] read_data,
    output dcache_hit,
    output dcache_stall,
    input grant,

    // Interface with memory
    output [15:0] mem_write_data,
    output [15:0] mem_addr,
    output mem_write_enable,
    output mem_request,
    input [15:0] mem_data,
    input mem_valid

);


wire [5:0] tag    = addr[15:10];
wire [5:0] index  = addr[9:4];
wire [2:0] offset = addr[3:1];

wire fsm_busy;
wire write_data_array;
wire write_tag_array;
wire [2:0] chunk_index;

cache_fill_FSM dcache_fill_fsm (
    .clk(clk),
    .rst_n(~rst),
    .miss_detected(~dcache_hit),
    .miss_address(addr),
    .memory_data(mem_data),
    .memory_data_valid(mem_valid),
    .fsm_busy(fsm_busy),
    .write_data_array(write_data_array),
    .write_tag_array(write_tag_array),
    .memory_address(mem_addr),
    .chunk_index(chunk_index)
);



// Data and tag outputs for both ways
wire [15:0] way0_data_out, way1_data_out;
wire [7:0] way0_tag_out, way1_tag_out;

wire [5:0] tag0 = way0_tag_out[5:0];
wire       valid0 = way0_tag_out[7];
wire       match0 = valid0 && (tag0 == tag);

wire [5:0] tag1 = way1_tag_out[5:0];
wire       valid1 = way1_tag_out[7];
wire       match1 = valid1 && (tag1 == tag);

assign dcache_hit = match0 || match1;

wire [7:0] word_enable = write_data_array ? (8'b1 << chunk_index) : (8'b1 << offset);
wire [63:0] set_enable = (64'b1 << index);
wire cache_miss = ~(match0 || match1);
wire lru0 = way0_tag_out[6];

wire [127:0] block_enable_0 = {64'b0, set_enable};
wire [127:0] block_enable_1 = {set_enable, 64'b0};

wire update_lru = dcache_hit && !fsm_busy;
wire [127:0] block_enable_lru0 = (match0 && update_lru) ? block_enable_0 : 128'b0;
wire [127:0] block_enable_lru1 = (match1 && update_lru) ? block_enable_1 : 128'b0;

wire [7:0] updated_meta_way0 = {1'b1, 1'b0, tag0};
wire [7:0] updated_meta_way1 = {1'b1, 1'b0, tag1};

wire use_way0 = ~valid0 ? 1'b1 :
                ~valid1 ? 1'b0 :
                (lru0 ? 1'b0 : 1'b1);

reg refill_way;
always @(posedge clk, negedge rst) begin
  if (!rst)
    refill_way <= 1'b0;
  else if (cache_miss)
    refill_way <= use_way0;
end

// wire [127:0] block_enable_write0 = (cache_miss && use_way0) ? block_enable_0 : 128'b0;
// wire [127:0] block_enable_write1 = (cache_miss && ~use_way0) ? block_enable_1 : 128'b0;
wire [127:0] block_enable_write0 = (fsm_busy && refill_way) ? block_enable_0 : 128'b0;
wire [127:0] block_enable_write1 = (fsm_busy && !refill_way) ? block_enable_1 : 128'b0;

wire [127:0] block_enable_0_final = write_data_array     ? block_enable_write0 :
                                    update_lru && match0 ? block_enable_lru0   :
                                    block_enable_0;

wire [127:0] block_enable_1_final = write_data_array      ? block_enable_write1 :
                                    update_lru && match1  ? block_enable_lru1   :
                                    block_enable_1;

wire [7:0] meta_in_way0 = write_tag_array ? {1'b1, refill_way ? 1'b0 : 1'b1, tag} :
                          (match0 && update_lru) ? (updated_meta_way0) :
                          8'bx;

wire [7:0] meta_in_way1 = write_tag_array ? {1'b1, refill_way ? 1'b1 : 1'b0, tag} :
                          (match1 && update_lru) ? (updated_meta_way1) :
                          8'bx;

DataArray data_array0(
    .clk(clk),
    .rst(rst),
    .DataIn(write_data_array ? mem_data : write_data),
    .Write(write_tag_array || (update_lru && match0)),
    .BlockEnable(block_enable_0_final),
    .WordEnable(word_enable),
    .DataOut(way0_data_out)
);

MetaDataArray meta_array0(
    .clk(clk),
    .rst(rst),
    .DataIn(meta_in_way0),
    .Write(write_tag_array || (update_lru && match0)),
    .BlockEnable(block_enable_0_final),
    .DataOut(way0_tag_out)
);

DataArray data_array1(
    .clk(clk),
    .rst(rst),
    .DataIn(write_data_array ? mem_data : write_data),
    .Write(write_tag_array || (update_lru && match1)),
    .BlockEnable(block_enable_1_final),
    .WordEnable(word_enable),
    .DataOut(way1_data_out)
);

MetaDataArray meta_array1(
    .clk(clk),
    .rst(rst),
    .DataIn(meta_in_way1),
    .Write(write_tag_array || (update_lru && match1)),
    .BlockEnable(block_enable_1_final),
    .DataOut(way1_tag_out)
);

assign read_data = match0 ? way0_data_out :
                   match1 ? way1_data_out :
                   16'hxxxx;


assign mem_write_enable = mem_write && dcache_hit;
assign mem_write_data = write_data;
assign mem_request = fsm_busy;
assign dcache_stall = fsm_busy || (mem_request && !grant);

endmodule