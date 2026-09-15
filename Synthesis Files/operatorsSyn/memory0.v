module mem(
    input         clk,
    input         rst_n,

    // Data inputs
    input  [15:0] rt_data,
    input  [15:0] mem_calc_result,
    input  [15:0] aluResult,
    input  [15:0] pcs_value,

    // Control inputs from EM_pipe
    input  [3:0]  dest,
    input         reg_write_enable_in,
    input         mem_to_reg,
    input         pcs_valid,
    input         memWrite,
    input         memRead,

    // MEM-MEM forwarding
    input  [3:0]  M_W_rd,
    input         M_W_regWrite,
    input  [15:0] M_W_data,
    input [3:0] rt_src,

    output [15:0] reg_write_data,
    output [3:0]  reg_write_addr,
    output        reg_write_enable_out,

    input  [15:0] data_mem_out       // <-- NEW: comes from dcache

);


wire [15:0] store_value = 
    (reg_write_enable_in && dest == rt_src && dest != 4'd0) ? aluResult :
    (M_W_regWrite && M_W_rd == rt_src && M_W_rd != 4'd0)     ? M_W_data :
    rt_data;


   
// Writeback logic
assign reg_write_data = (reg_write_enable_in == 0) ? 16'h0000 :  // kill garbage
                        (pcs_valid) ? pcs_value :
                        (mem_to_reg && memRead) ? data_mem_out :
                        aluResult;





assign reg_write_addr   = dest;
assign reg_write_enable_out = reg_write_enable_in;


endmodule
