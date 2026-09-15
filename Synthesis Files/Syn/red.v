module red(
    input  [15:0] rs,
    input  [15:0] rt,
    output [15:0] rd
);
    wire [4:0] nib[7:0];

    // Sign-extend each nibble manually to 5 bits (4-bit value + sign bit)
    assign nib[0] = {rs[15], rs[15:12]};
    assign nib[1] = {rs[11], rs[11:8]};
    assign nib[2] = {rs[7],  rs[7:4]};
    assign nib[3] = {rs[3],  rs[3:0]};
    assign nib[4] = {rt[15], rt[15:12]};
    assign nib[5] = {rt[11], rt[11:8]};
    assign nib[6] = {rt[7],  rt[7:4]};
    assign nib[7] = {rt[3],  rt[3:0]};

    // Level 1 adds (pairwise)
    wire [4:0] sum0, sum1, sum2, sum3;
    wire co0, co1, co2, co3;

    addsub_4bit a0(.A(nib[0][3:0]), .B(nib[1][3:0]), .sub(1'b0), .carry_in(1'b0), .Sum(sum0[3:0]), .carry_out(co0));
    assign sum0[4] = nib[0][4] ^ nib[1][4] ^ co0;

    addsub_4bit a1(.A(nib[2][3:0]), .B(nib[3][3:0]), .sub(1'b0), .carry_in(1'b0), .Sum(sum1[3:0]), .carry_out(co1));
    assign sum1[4] = nib[2][4] ^ nib[3][4] ^ co1;

    addsub_4bit a2(.A(nib[4][3:0]), .B(nib[5][3:0]), .sub(1'b0), .carry_in(1'b0), .Sum(sum2[3:0]), .carry_out(co2));
    assign sum2[4] = nib[4][4] ^ nib[5][4] ^ co2;

    addsub_4bit a3(.A(nib[6][3:0]), .B(nib[7][3:0]), .sub(1'b0), .carry_in(1'b0), .Sum(sum3[3:0]), .carry_out(co3));
    assign sum3[4] = nib[6][4] ^ nib[7][4] ^ co3;

    // Level 2 adds
    wire [5:0] sum4, sum5;
    wire co4, co5;

    addsub_4bit a4(.A(sum0[3:0]), .B(sum1[3:0]), .sub(1'b0), .carry_in(1'b0), .Sum(sum4[3:0]), .carry_out(co4));
    assign sum4[5] = sum0[4] ^ sum1[4] ^ co4;

    addsub_4bit a5(.A(sum2[3:0]), .B(sum3[3:0]), .sub(1'b0), .carry_in(1'b0), .Sum(sum5[3:0]), .carry_out(co5));
    assign sum5[5] = sum2[4] ^ sum3[4] ^ co5;

    // Level 3 final add
    wire [6:0] sum_final;
    wire co6;

    addsub_4bit a6(.A(sum4[3:0]), .B(sum5[3:0]), .sub(1'b0), .carry_in(1'b0), .Sum(sum_final[3:0]), .carry_out(co6));
    assign sum_final[6:4] = {sum4[5] ^ sum5[5] ^ co6, 2'b00}; // 2 upper bits don't affect sign

    // Final sign extension to 16-bit
    assign rd = {{9{sum_final[6]}}, sum_final};

endmodule
