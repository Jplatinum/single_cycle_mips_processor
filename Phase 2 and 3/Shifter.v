module Shifter (
    output [15:0] Shift_Out,
    input  [15:0] Shift_In,
    input  [3:0]  Shift_Val,
    input         Mode
);

reg [15:0] shift8;

always @(*) begin
    case (Mode)
        1'b0: shift8 = Shift_In << Shift_Val;             // Logical Left Shift
        1'b1: shift8 = $signed(Shift_In) >>> Shift_Val;   // Arithmetic Right Shift
    endcase
end

assign Shift_Out = shift8;

endmodule
