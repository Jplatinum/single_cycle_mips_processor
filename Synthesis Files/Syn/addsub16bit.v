
module addsub16bit (A, B, sub, Sum, Ovfl);
    input  [15:0] A;
    input  [15:0] B;
    input         sub;
    output [15:0] Sum;
    output        Ovfl;
  wire [3:0] c;
  addsub_4bit i0 (
      .A(A[3:0]),
      .B(B[3:0]),
      .sub(sub),
      .carry_in(sub),
      .Sum(Sum[3:0]),
      .carry_out(c[0])
  );
  addsub_4bit i1 (
      .A(A[7:4]),
      .B(B[7:4]),
      .sub(sub),
      .carry_in(c[0]),
      .Sum(Sum[7:4]),
      .carry_out(c[1])
  );
  addsub_4bit i2 (
      .A(A[11:8]),
      .B(B[11:8]),
      .sub(sub),
      .carry_in(c[1]),
      .Sum(Sum[11:8]),
      .carry_out(c[2])
  );
  addsub_4bit i3 (
      .A(A[15:12]),
      .B(B[15:12]),
      .sub(sub),
      .carry_in(c[2]),
      .Sum(Sum[15:12]),
      .carry_out(c[3])
  );
    assign Ovfl = sub ? 
                  ((A[15] != B[15]) && (Sum[15] != A[15])) : 
                  ((A[15] == B[15]) && (Sum[15] != A[15]));
endmodule
