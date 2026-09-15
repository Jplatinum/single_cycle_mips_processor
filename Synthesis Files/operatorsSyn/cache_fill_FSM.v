module cache_fill_FSM (
    
    input clk, rst_n,
    input miss_detected,                // active high when tag match logic detects a miss
    input [15:0] miss_address,          // address that missed the cache
    input [15:0] memory_data,           // data returned by memory (after delay)
    input memory_data_valid,            // active high indicates valid data returning on memory bus

    output reg fsm_busy,                // asserted while FSM is busy handling the miss (can be used as pipeline stall signal)
    output reg write_data_array,        // write enable to cache data array to signal when filling with memory_data
    output reg write_tag_array,         // write enable to cache tag array to signal when all words are filled in to data array
    output reg [15:0] memory_address,   // address to read from memory
    output [2:0] chunk_index
);

wire [3:0] chunk_count;
reg  [3:0] next_chunk;
dff chunk_ff[3:0] (.clk(clk), .rst(~rst_n), .wen(1'b1), .d(next_chunk), .q(chunk_count));

wire [15:0] chunk_offset = {chunk_count, 1'b0};
wire [15:0] chunk_addr = miss_address + chunk_offset;


reg next_state;
wire current_state;
dff fsm (.q(current_state), .d(next_state), .wen(1'b1), .clk(clk), .rst(~rst_n));

parameter IDLE = 1'b0;
parameter WAIT = 1'b1;

always @(*) begin

    next_state = current_state;         // default hold current state
    next_chunk = chunk_count;           // default hold current chunk count
    fsm_busy = 0;                       // default FSM not busy
    write_data_array = 0;               // default do not write to cache data array
    write_tag_array = 0;                // default do not write to cache tag array
    memory_address = 16'h0;             // default memory address to 0

    case (current_state)

        IDLE: begin
            if (miss_detected) begin                    // if cache miss detected, begin miss handling process
                next_state = WAIT;                      // transition to begin filling cache block
                next_chunk = 0;                         // reset chunk counter for the new block
                fsm_busy = 1;                           // now busy stalling the pipeline
                memory_address = miss_address;          // start fetching block from the missed address
            end
        end

        WAIT: begin
            fsm_busy = 1;                               // remains busy while waiting for memory responses
            memory_address = chunk_addr;                // compute memory address for current 2 byte chunk

            if (memory_data_valid) begin                // if valid 2 byte chunk has returned from memory
                write_data_array = 1;                   // write this word into the cache data array

                if (chunk_count == 4'd7) begin          // if this is the last chunk 
                    write_tag_array = 1;                // write tag into tag array, block now fully filled
                    next_chunk = 0;                     // reset
                    next_state = IDLE;                  // return since block fill is complete
                end

                else begin                              // still fetching chunks, move to next chunk
                    next_chunk = chunk_count + 1;
                    next_state = WAIT;
                end
            end

            else begin
                next_state = WAIT;
            end

        end

        default: begin
            next_state = IDLE;
            next_chunk = 0;
            memory_address = 16'h0;
            fsm_busy = 0;
            write_data_array = 0;
            write_tag_array = 0;
        end

    endcase
end

assign chunk_index = chunk_count[2:0];

endmodule

