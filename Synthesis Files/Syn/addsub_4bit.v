module addsub_4bit (
  A, B, sub, carry_in, Sum, carry_out
);
  input  [3:0] A;
  input  [3:0] B;
  input        sub;
  input        carry_in;
  output [3:0] Sum;
  output       carry_out;

  wire [3:0] B_mod;
  assign B_mod = B ^ {4{sub}};
  wire c0;
  assign c0 = carry_in;
  wire s0, c0_0;
  assign s0 = A[0] ^ B_mod[0] ^ c0;
  assign c0_0 = (A[0] & B_mod[0]) | (A[0] & c0) | (B_mod[0] & c0);
  wire s1, c0_1;
  assign s1 = A[1] ^ B_mod[1] ^ c0_0;
  assign c0_1 = (A[1] & B_mod[1]) | (A[1] & c0_0) | (B_mod[1] & c0_0);
  wire s2, c0_2;
  assign s2 = A[2] ^ B_mod[2] ^ c0_1;
  assign c0_2 = (A[2] & B_mod[2]) | (A[2] & c0_1) | (B_mod[2] & c0_1);
  wire s3;
  assign s3 = A[3] ^ B_mod[3] ^ c0_2;
  assign carry_out = (A[3] & B_mod[3]) | (A[3] & c0_2) | (B_mod[3] & c0_2);
  assign Sum = {s3, s2, s1, s0};
endmodule
