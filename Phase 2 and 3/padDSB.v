module padDSB(
    input  [15:0] rs,
    input  [15:0] rt,
    output [15:0] result
);

    wire [3:0] sum0, sum1, sum2, sum3;
    wire co0, co1, co2, co3;

    // 4-bit adders with carry out (no + used)
    addsub_4bit A0 (.A(rs[3:0]),   .B(rt[3:0]),   .sub(1'b0), .carry_in(1'b0), .Sum(sum0), .carry_out(co0));
    addsub_4bit A1 (.A(rs[7:4]),   .B(rt[7:4]),   .sub(1'b0), .carry_in(1'b0), .Sum(sum1), .carry_out(co1));
    addsub_4bit A2 (.A(rs[11:8]),  .B(rt[11:8]),  .sub(1'b0), .carry_in(1'b0), .Sum(sum2), .carry_out(co2));
    addsub_4bit A3 (.A(rs[15:12]), .B(rt[15:12]), .sub(1'b0), .carry_in(1'b0), .Sum(sum3), .carry_out(co3));

    // Overflow detection logic (signed)
    wire ovf0 = (rs[3] == rt[3]) && (sum0[3] != rs[3]);
    wire ovf1 = (rs[7] == rt[7]) && (sum1[3] != rs[7]);
    wire ovf2 = (rs[11] == rt[11]) && (sum2[3] != rs[11]);
    wire ovf3 = (rs[15] == rt[15]) && (sum3[3] != rs[15]);

    // Saturation logic using ternary and equality only
    wire [3:0] sat0 = ovf0 ? (rs[3] ? 4'b1000 : 4'b0111) : sum0;
    wire [3:0] sat1 = ovf1 ? (rs[7] ? 4'b1000 : 4'b0111) : sum1;
    wire [3:0] sat2 = ovf2 ? (rs[11]? 4'b1000 : 4'b0111) : sum2;
    wire [3:0] sat3 = ovf3 ? (rs[15]? 4'b1000 : 4'b0111) : sum3;

    assign result = {sat3, sat2, sat1, sat0};
endmodule
