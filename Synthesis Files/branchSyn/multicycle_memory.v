module memory4c (data_out, data_in, addr, enable, wr, clk, rst, data_valid);

   output  reg [15:0] data_out;
   output reg data_valid;
   input [15:0]   data_in;
   input [15:0]   addr;
   input          enable;
   input          wr;
   input          clk;
   input          rst;


   // synopsys translate_off

   parameter ADDR_WIDTH = 16;

   wire [15:0]    data_out_4;
   reg [15:0]    data_out_3, data_out_2, data_out_1;
   wire    data_valid_4;
   reg     data_valid_3, data_valid_2, data_valid_1;


   reg [15:0]      mem [0:2**ADDR_WIDTH-1];
   reg            loaded;

   assign         data_out_4 = (enable & (~wr))? {mem[addr[ADDR_WIDTH-1 :1]]}: 0; //Read
   assign	     data_valid_4 = (enable & (~wr));
   initial begin
      loaded = 0;
   end
   always @(posedge clk) begin
      if (rst) begin
         //load loadfile_all.img
         if (!loaded) begin
            $readmemh("phase3_test1.txt", mem);
            loaded = 1;
         end

      end
      else begin
         if (enable & wr) begin
                mem[addr[ADDR_WIDTH-1 :1]] = data_in[15:0];       // The actual write
         end
      end
   end

  always @(posedge clk) begin
        if (rst) begin
                data_out_3 <= 0;
                data_out_2 <= 0;
                data_out_1 <= 0;
                data_out <= 0;

                data_valid_3 <= 0;
                data_valid_2 <= 0;
                data_valid_1 <= 0;
                data_valid <= 0;
        end
        else begin
                data_out_3 <= data_out_4;
                data_out_2 <= data_out_3;
                data_out_1 <= data_out_2;
                data_out <= data_out_1;

                data_valid_3 <= data_valid_4;
                data_valid_2 <= data_valid_3;
                data_valid_1 <= data_valid_2;
                data_valid <= data_valid_1;

        end
  end

  // synopsys translate_on

endmodule
                         
