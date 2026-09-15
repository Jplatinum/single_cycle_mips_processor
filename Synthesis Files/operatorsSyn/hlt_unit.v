module hlt_unit (
  input clk,
  input rst,
  input if_hlt, //IF stage - if hlt signal, control logic set this in WB stage
  input if_flush, //flush signal
  input wb_hlt,
  output pc_stall,
  output hlt
);
  wire d_hlt, q_hlt;
  assign pc_stall = if_hlt & ~if_flush;
  assign d_hlt = q_hlt | wb_hlt;
  dff dff_inst (
    .q(q_hlt),
    .d(d_hlt),
    .wen(1'b1),
    .clk(clk),
    .rst(rst)
  );
  assign hlt = q_hlt;
endmodule
